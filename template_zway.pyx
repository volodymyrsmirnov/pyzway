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


cdef class ZWay:
    cdef zw.ZWay _zway

    def on_terminate(self):
        pass


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
        self.on_terminate()


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
            bytes_string = config_file.readall()

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