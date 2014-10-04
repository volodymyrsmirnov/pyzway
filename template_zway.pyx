"""
Copyright (C) 2014, Vladimir Smirnov (vladimir@smirnov.im)

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
"""

cimport cython
from libc.stdio cimport fopen
from libc.stdlib cimport free, malloc
from cpython.pythread cimport PyThread_start_new_thread
cimport libzway as zw
import time

"""
Why do we need callback and caller functions per each callback?

Because the bare C callback behaves pretty much strange. When I enable GIL bypassing "with gil" in function definition -
execution enters the deadlock in caller thread with pthread sem_wait. Without GIL it causes the SEGFAULT, so the only
working solution I was able to find is to pass pointer with data into the new PyThread where we execute python callback.

Know the better way? Drop me a line at vladimir@smirnov.im or send a pull request on github.
"""

cdef void c_device_caller(void* info_p) with gil:
    cdef zw.DeviceCallbackInfo info = <zw.DeviceCallbackInfo> info_p

    if info.instance != NULL:
        (<ZWay> info.instance).on_device(info.type, info.node_id, info.instance_id, info.command_id)

    free(info_p)


cdef void c_device_callback(const zw.ZWay zway, zw.ZWDeviceChangeType type, zw.ZWBYTE node_id, zw.ZWBYTE instance_id,
                            zw.ZWBYTE command_id, void *arg):

    cdef zw.DeviceCallbackInfo info = <zw.DeviceCallbackInfo> malloc(cython.sizeof(zw.DeviceCallbackInfo))
    info.type = type
    info.node_id = node_id
    info.instance_id = instance_id
    info.command_id = command_id
    info.instance = arg

    PyThread_start_new_thread(c_device_caller, <void *> info)


cdef void c_job_caller(void* info_p) with gil:
    cdef zw.JobCallbackInfo info = <zw.JobCallbackInfo> info_p

    if info.instance != NULL:
        (<ZWay> info.instance).on_job(info.success, info.function_id)

    free(info_p)


cdef void c_job_success_callback(const zw.ZWay zway, zw.ZWBYTE function_id, void* arg):
    cdef zw.JobCallbackInfo info = <zw.JobCallbackInfo> malloc(cython.sizeof(zw.JobCallbackInfo))
    info.success = 1
    info.function_id = function_id
    info.instance = arg

    PyThread_start_new_thread(c_job_caller, <void *> info)


cdef void c_job_failure_callback(const zw.ZWay zway, zw.ZWBYTE function_id, void* arg):
    cdef zw.JobCallbackInfo info = <zw.JobCallbackInfo> malloc(cython.sizeof(zw.JobCallbackInfo))
    info.success = 0
    info.function_id = function_id
    info.instance = arg

    PyThread_start_new_thread(c_job_caller, <void *> info)


cdef void c_data_caller(void* info_p) with gil:
    cdef zw.DataChangeCallbackInfo info = <zw.DataChangeCallbackInfo> info_p

    if info.instance != NULL:
        (<ZWayData> info.instance).on_data_change(info.type)

    free(info_p)

cdef void c_data_change_callback(const zw.ZWay wzay, zw.ZWDataChangeType type, zw.ZDataHolder data, void *arg):
    cdef zw.DataChangeCallbackInfo info = <zw.DataChangeCallbackInfo> malloc(cython.sizeof(zw.DataChangeCallbackInfo))
    info.type = type
    info.data = data
    info.instance = arg

    PyThread_start_new_thread(c_data_caller, <void *> info)


cdef class ZWay:
    cdef zw.ZWay _zway


    def on_device(self, type, node_id, instance_id, command_id):
        pass


    def on_job(self, success, function_id):
        pass


    def __cinit__ (self, bytes port, bytes config_folder, bytes translations_folder, bytes zddx_folder, bytes log,
                   int level = 0):
        zw.PyEval_InitThreads()

        errno =  zw.zway_init(
            &self._zway, port, config_folder, translations_folder, zddx_folder,
            fopen(<char *> log, "wb") if log else NULL, level
        )

        if errno != 0:
            raise EnvironmentError((errno, "zway library init error"))


    def terminate(self):
        zw.zway_terminate(&self._zway)


    def set_log(self, bytes log, int level):
        return zw.zway_set_log(self._zway, fopen(<char *> log, "wb") if log else NULL, level)


    def device_add_callback(self, mask):
        return zw.zway_device_add_callback(self._zway, mask, c_device_callback, <void *> self)


    def device_remove_callback(self):
        return zw.zway_device_remove_callback(self._zway, c_device_callback)


    def start(self):
        return zw.zway_start(self._zway, NULL)


    def device_guess(self, node_id):
        results = []

        cdef zw.ZGuessedProduct* products = zw.zway_device_guess(self._zway, node_id)
        cdef zw.ZGuessedProduct product = NULL

        if products != NULL:
            i = 0

            while True:
                product = products[i]

                if product == NULL:
                    break

                results.append({
                    "score": product.score,
                    "vendor": product.vendor,
                    "product": product.product,
                    "image_url": product.image_url,
                    "file_name": product.file_name,
                })

                i += 1

        zw.zway_device_guess_free(products)

        return results

    def controller_config_save(self, file_name):
        cdef size_t data_length = 0
        cdef zw.ZWBYTE *data = NULL

        errno = zw.zway_controller_config_save(self._zway, &data, &data_length)

        if errno == 0 and data != NULL:
            bytes_string = data[:data_length]

            with open(file_name, "wb") as config_file:
                config_file.write(bytes_string)

            free(data)

        return errno


    def config_restore(self, file_name, full):
        bytes_string = ""

        with open(file_name, "wb") as config_file:
            bytes_string = config_file.read()

        return zw.zway_controller_config_restore(self._zway, bytes_string, len(bytes_string), full)


    def devices_list(self):
        results = []

        cdef zw.ZWDevicesList devices = zw.zway_devices_list(self._zway)
        cdef zw.ZWBYTE node_id = 0

        i = 0

        while True:
            node_id = devices[i]

            if node_id == 0:
                break

            results.append(node_id)

            i += 1

        zw.zway_devices_list_free(devices)

        return results


    def instances_list(self, device_id):
        results = []

        cdef zw.ZWInstancesList instances = zw.zway_instances_list(self._zway, device_id)
        cdef zw.ZWBYTE instance_id = 0

        i = 0

        while True:
            instance_id = instances[i]

            if instance_id == 0:
                break

            results.append(instance_id)

            i += 1

        zw.zway_instances_list_free(instances)

        return results


    def command_classes_list(self, device_id, instance_id):
        results = []

        cdef zw.ZWCommandClassesList c_classes = zw.zway_command_classes_list(self._zway, device_id,
                                                                                        instance_id)
        cdef zw.ZWBYTE c_class = 0

        i = 0

        while True:
            c_class = c_classes[i]

            if c_class == 0:
                break

            results.append(c_class)

            i += 1

        zw.zway_command_classes_list_free(c_classes)

        return results


    def cc_firmware_update_perform(self, node_id, instance_id, manufacturerId, firmwareId, firmwareTarget, bytes data):
        return zw.zway_cc_firmware_update_perform(self._zway, node_id, instance_id, manufacturerId, firmwareId, firmwareTarget, len(data), data, c_job_success_callback, c_job_failure_callback, <void *> self)


#GENPYX:ZWayLib.h:zway_device_add_callback_ex,zway_device_remove_callback_ex,zway_command_classes_list_free,zway_command_classes_list,zway_instances_list_free,zway_instances_list,zway_devices_list,zway_devices_list_free,zway_controller_config_restore,zway_controller_config_restore,zway_controller_config_save,zway_device_guess_free,zway_device_guess,zway_start,zway_set_log,zway_terminate,zway_init,zway_device_add_callback,zway_device_remove_callback


#GENPYX:CommandClassesPublic.h:zway_cc_firmware_update_perform


#GENPYX:FunctionClassesPublic.h:


cdef class ZWayData:
    cdef zw.ZDataHolder holder
    cdef ZWay controller


    def on_data_change(self, change_type):
        pass


    def __cinit__(self, ZWay controller):
        self.controller = controller
        self.holder = NULL


    @property
    def is_empty(self):
        zw.zway_data_acquire_lock(self.controller._zway)

        empty = zw.zway_data_is_empty(self.controller._zway, self.holder) != 0

        zw.zway_data_release_lock(self.controller._zway)

        return empty


    @property
    def type(self):
        cdef zw.ZWDataType dtype

        zw.zway_data_acquire_lock(self.controller._zway)

        if zw.zway_data_get_type(self.controller._zway, self.holder, &dtype) != 0:
            dtype = 0

        zw.zway_data_release_lock(self.controller._zway)

        return type


    @property
    def path(self):
        zw.zway_data_acquire_lock(self.controller._zway)

        path = zw.zway_data_get_path(self.controller._zway, self.holder)

        zw.zway_data_release_lock(self.controller._zway)

        return path


    @property
    def update_time(self):
        zw.zway_data_acquire_lock(self.controller._zway)

        cdef zw.time_t timestamp = zw.zway_data_get_update_time(self.holder)

        zw.zway_data_release_lock(self.controller._zway)

        return time.gmtime(timestamp/1000)


    @property
    def invalidate_time(self):
        zw.zway_data_acquire_lock(self.controller._zway)

        cdef zw.time_t timestamp = zw.zway_data_get_invalidate_time(self.holder)

        zw.zway_data_release_lock(self.controller._zway)

        return time.gmtime(timestamp/1000)


    @property
    def value(self):
        cdef zw.ZWBOOL bool_val
        cdef int int_val
        cdef float float_val
        cdef zw.ZWCSTR str_val
        cdef const zw.ZWBYTE *binary
        cdef const int *int_arr
        cdef const float *float_arr
        cdef const zw.ZWCSTR *str_arr
        cdef size_t length

        result_type = self.type
        result_list = list()

        zw.zway_data_acquire_lock(self.controller._zway)

        # Empty
        if result_type == 0:
            zw.zway_data_release_lock(self.controller._zway)

            return None

        # Boolean
        elif result_type == 1:
            zw.zway_data_get_boolean(self.controller._zway, self.holder, &bool_val)
            zw.zway_data_release_lock(self.controller._zway)

            return bool_val != 0

        # Integer
        elif result_type == 2:
            zw.zway_data_get_integer(self.controller._zway, self.holder, &int_val)
            zw.zway_data_release_lock(self.controller._zway)

            return int_val

        # Float
        elif result_type == 3:
            zw.zway_data_get_float(self.controller._zway, self.holder, &float_val)
            zw.zway_data_release_lock(self.controller._zway)

            return float_val

        # String
        elif result_type == 4:
            zw.zway_data_get_string(self.controller._zway, self.holder, &str_val)
            zw.zway_data_release_lock(self.controller._zway)

            return str_val

        # Binary
        elif result_type == 5:
            zw.zway_data_get_binary(self.controller._zway, self.holder, &binary, &length)
            zw.zway_data_release_lock(self.controller._zway)

            return <bytes> binary[:length]

        # Array of integers
        elif result_type == 6:
            zw.zway_data_get_integer_array(self.controller._zway, self.holder, &int_arr, &length)
            zw.zway_data_release_lock(self.controller._zway)

            for i in range(0, length):
                result_list.append(<int> int_arr[i])

            return result_list

        # Array of floats
        elif result_type == 7:
            zw.zway_data_get_float_array(self.controller._zway, self.holder, &float_arr, &length)
            zw.zway_data_release_lock(self.controller._zway)

            for i in range(0, length):
                result_list.append(<float> float_arr[i])

            return result_list

        # Array of strings
        elif result_type == 8:
            zw.zway_data_get_string_array(self.controller._zway, self.holder, &str_arr, &length)
            zw.zway_data_release_lock(self.controller._zway)

            for i in range(0, length):
                result_list.append(str_arr[i])

            return result_list

    def set(self, value, is_binary = False):
        zw.zway_data_acquire_lock(self.controller._zway)

        cdef int* ints = []
        cdef float* floats = []
        cdef zw.ZWCSTR* strings = []

        errno = 0

        if type(value) is None:
            errno = zw.zway_data_set_empty(self.controller._zway, self.holder)

        elif type(value) is bool:
            errno = zw.zway_data_set_boolean(self.controller._zway, self.holder, 1 if value else 0)

        elif type(value) is int:
            errno = zw.zway_data_set_integer(self.controller._zway, self.holder, value)

        elif type(value) is float:
            errno = zw.zway_data_set_float(self.controller._zway, self.holder, value)

        elif type(value) is bytes:
            errno = zw.zway_data_set_string(self.controller._zway, self.holder, value, 1)

        elif type(value) is bytes and is_binary:
            errno =  zw.zway_data_set_binary(self.controller._zway, self.holder, value, len(value), 1)

        elif type(value) is list:
            if all(isinstance(x, int) for x in value):
                ints = <int *>malloc(len(value) * cython.sizeof(int))

                for i in range(len(value)):
                    ints[i] = value[i]

                errno = zw.zway_data_set_integer_array(self.controller._zway, self.holder, ints, len(value))

                free(ints)

            elif all(isinstance(x, float) for x in value):
                floats = <float *>malloc(len(value) * cython.sizeof(float))

                for i in range(len(value)):
                    floats[i] = value[i]

                errno = zw.zway_data_set_float_array(self.controller._zway, self.holder, floats, len(value))

                free(floats)

            elif all(isinstance(x, bytes) for x in value):
                strings = <zw.ZWCSTR *>malloc(len(value) * cython.sizeof(zw.ZWCSTR))

                for i in range(len(value)):
                    strings[i] = value[i]

                errno = zw.zway_data_set_string_array(self.controller._zway, self.holder, strings, len(value), 1)

                free(strings)

            else:
                raise ValueError("Unsupported list in value")
        else:
            raise ValueError("Unsupported value")

        zw.zway_data_release_lock(self.controller._zway)

        return errno


    def invalidate(self, children=True):
        zw.zway_data_acquire_lock(self.controller._zway)

        errno = zw.zway_data_invalidate(self.controller._zway, self.holder, 1 if children else 0)

        zw.zway_data_release_lock(self.controller._zway)

        return errno


    def add_callback(self, watch_children=True):
        zw.zway_data_acquire_lock(self.controller._zway)

        errno = zw.zway_data_add_callback(self.controller._zway, self.holder, c_data_change_callback, 1 if watch_children else 0, <void *>self)

        zw.zway_data_release_lock(self.controller._zway)

        return errno


    def remove_callback(self):
        zw.zway_data_acquire_lock(self.controller._zway)

        errno = zw.zway_data_remove_callback(self.controller._zway, self.holder, c_data_change_callback)

        zw.zway_data_release_lock(self.controller._zway)

        return errno


    cdef void set_holder(self, zw.ZDataHolder holder):
        self.holder = holder


    def find_data(self, bytes path):
        zw.zway_data_acquire_lock(self.controller._zway)

        cdef zw.ZDataHolder holder = zw.zway_find_data(self.controller._zway, self.holder, path)

        new_data = ZWayData(self.controller)
        new_data.set_holder(holder)

        zw.zway_data_release_lock(self.controller._zway)

        return new_data


    def find_controller_data(self, bytes path):
        zw.zway_data_acquire_lock(self.controller._zway)

        cdef zw.ZDataHolder holder = zw.zway_find_controller_data(self.controller._zway, path)

        new_data = ZWayData(self.controller)
        new_data.set_holder(holder)

        zw.zway_data_release_lock(self.controller._zway)

        return new_data


    def find_device_data(self, bytes path, device, instance=None, command_class=None):
        zw.zway_data_acquire_lock(self.controller._zway)

        cdef zw.ZDataHolder holder = NULL

        if command_class is None and instance is None:
            holder = zw.zway_find_device_data(self.controller._zway, device, path)

        elif command_class is None and instance is not None:
            holder = zw.zway_find_device_instance_data(self.controller._zway, device, instance, path)

        else:
            holder = zw.zway_find_device_instance_cc_data(self.controller._zway, device, instance, command_class, path)

        new_data = ZWayData(self.controller)
        new_data.set_holder(holder)

        zw.zway_data_release_lock(self.controller._zway)

        return new_data

