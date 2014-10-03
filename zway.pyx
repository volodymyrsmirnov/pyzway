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


    def stop(self):
        return zw.zway_stop(self._zway, )

    def discover(self):
        return zw.zway_discover(self._zway, )

    def is_idle(self):
        return zw.zway_is_idle(self._zway, ) != 0

    def is_running(self):
        return zw.zway_is_running(self._zway, ) != 0

    def device_send_nop(self, node_id):
        return zw.zway_device_send_nop(self._zway, node_id)

    def device_load_xml(self, node_id, file_name):
        return zw.zway_device_load_xml(self._zway, node_id, file_name)

    def device_awake_queue(self, node_id):
        zw.zway_device_awake_queue(self._zway, node_id)

    def command_interview(self, device_id, instance_id, cc_id):
        return zw.zway_command_interview(self._zway, device_id, instance_id, cc_id)

    def device_interview_force(self, device_id):
        return zw.zway_device_interview_force(self._zway, device_id)

    def device_is_interview_done(self, device_id):
        return zw.zway_device_is_interview_done(self._zway, device_id) != 0

    def device_assign_return_route(self, device_id, node_id):
        return zw.zway_device_assign_return_route(self._zway, device_id, node_id)

    def device_delete_return_route(self, device_id):
        return zw.zway_device_delete_return_route(self._zway, device_id)

    def device_assign_suc_return_route(self, device_id):
        return zw.zway_device_assign_suc_return_route(self._zway, device_id)

    def device_delete_suc_return_route(self, device_id):
        return zw.zway_device_delete_suc_return_route(self._zway, device_id)

    def controller_set_suc_node_id(self, node_id):
        return zw.zway_controller_set_suc_node_id(self._zway, node_id)

    def controller_set_sis_node_id(self, node_id):
        return zw.zway_controller_set_sis_node_id(self._zway, node_id)

    def controller_disable_suc_node_id(self, node_id):
        return zw.zway_controller_disable_suc_node_id(self._zway, node_id)

    def controller_change(self, startStop):
        return zw.zway_controller_change(self._zway, startStop)

    def controller_add_node_to_network(self, startStop):
        return zw.zway_controller_add_node_to_network(self._zway, startStop)

    def controller_remove_node_from_network(self, startStop):
        return zw.zway_controller_remove_node_from_network(self._zway, startStop)

    def controller_set_learn_mode(self, startStop):
        return zw.zway_controller_set_learn_mode(self._zway, startStop)

    def controller_set_default(self):
        return zw.zway_controller_set_default(self._zway, )

    def zddx_save_to_xml(self):
        return zw.zddx_save_to_xml(self._zway, )

    def command_is_supported(self, node_id, instance_id, command_id):
        return zw.zway_command_is_supported(self._zway, node_id, instance_id, command_id) != 0




    def cc_basic_get(self, node_id, instance_id):
        return zw.zway_cc_basic_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_basic_set(self, node_id, instance_id, value):
        return zw.zway_cc_basic_set(self._zway, node_id, instance_id, value, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_wakeup_get(self, node_id, instance_id):
        return zw.zway_cc_wakeup_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_wakeup_capabilities_get(self, node_id, instance_id):
        return zw.zway_cc_wakeup_capabilities_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_wakeup_sleep(self, node_id, instance_id):
        return zw.zway_cc_wakeup_sleep(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_wakeup_set(self, node_id, instance_id, interval, notification_node_id):
        return zw.zway_cc_wakeup_set(self._zway, node_id, instance_id, interval, notification_node_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_battery_get(self, node_id, instance_id):
        return zw.zway_cc_battery_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_manufacturer_specific_get(self, node_id, instance_id):
        return zw.zway_cc_manufacturer_specific_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_configuration_get(self, node_id, instance_id, parameter):
        return zw.zway_cc_configuration_get(self._zway, node_id, instance_id, parameter, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_configuration_set(self, node_id, instance_id, parameter, value, size):
        return zw.zway_cc_configuration_set(self._zway, node_id, instance_id, parameter, value, size, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_configuration_set_default(self, node_id, instance_id, parameter):
        return zw.zway_cc_configuration_set_default(self._zway, node_id, instance_id, parameter, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_sensor_binary_get(self, node_id, instance_id, sensorType):
        return zw.zway_cc_sensor_binary_get(self._zway, node_id, instance_id, sensorType, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_association_get(self, node_id, instance_id, group_id):
        return zw.zway_cc_association_get(self._zway, node_id, instance_id, group_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_association_set(self, node_id, instance_id, group_id, include_node):
        return zw.zway_cc_association_set(self._zway, node_id, instance_id, group_id, include_node, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_association_remove(self, node_id, instance_id, group_id, exclude_node):
        return zw.zway_cc_association_remove(self._zway, node_id, instance_id, group_id, exclude_node, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_association_groupings_get(self, node_id, instance_id):
        return zw.zway_cc_association_groupings_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_meter_get(self, node_id, instance_id, scale):
        return zw.zway_cc_meter_get(self._zway, node_id, instance_id, scale, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_meter_reset(self, node_id, instance_id):
        return zw.zway_cc_meter_reset(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_meter_supported(self, node_id, instance_id):
        return zw.zway_cc_meter_supported(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_sensor_multilevel_get(self, node_id, instance_id, sensor_type):
        return zw.zway_cc_sensor_multilevel_get(self._zway, node_id, instance_id, sensor_type, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_sensor_configuration_get(self, node_id, instance_id):
        return zw.zway_cc_sensor_configuration_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_sensor_configuration_set(self, node_id, instance_id, mode, value):
        return zw.zway_cc_sensor_configuration_set(self._zway, node_id, instance_id, mode, value, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_switch_all_get(self, node_id, instance_id):
        return zw.zway_cc_switch_all_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_switch_all_set(self, node_id, instance_id, mode):
        return zw.zway_cc_switch_all_set(self._zway, node_id, instance_id, mode, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_switch_all_set_on(self, node_id, instance_id):
        return zw.zway_cc_switch_all_set_on(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_switch_all_set_off(self, node_id, instance_id):
        return zw.zway_cc_switch_all_set_off(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_switch_binary_get(self, node_id, instance_id):
        return zw.zway_cc_switch_binary_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_switch_binary_set(self, node_id, instance_id, value):
        return zw.zway_cc_switch_binary_set(self._zway, node_id, instance_id, value, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_switch_multilevel_get(self, node_id, instance_id):
        return zw.zway_cc_switch_multilevel_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_switch_multilevel_set(self, node_id, instance_id, level, duration):
        return zw.zway_cc_switch_multilevel_set(self._zway, node_id, instance_id, level, duration, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_switch_multilevel_start_level_change(self, node_id, instance_id, dir, duration, ignoreStartLevel, startLevel, incdec, step):
        return zw.zway_cc_switch_multilevel_start_level_change(self._zway, node_id, instance_id, dir, duration, ignoreStartLevel, startLevel, incdec, step, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_switch_multilevel_stop_level_change(self, node_id, instance_id):
        return zw.zway_cc_switch_multilevel_stop_level_change(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_multichannel_association_get(self, node_id, instance_id, group_id):
        return zw.zway_cc_multichannel_association_get(self._zway, node_id, instance_id, group_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_multichannel_association_set(self, node_id, instance_id, group_id, include_node, include_instance):
        return zw.zway_cc_multichannel_association_set(self._zway, node_id, instance_id, group_id, include_node, include_instance, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_multichannel_association_remove(self, node_id, instance_id, group_id, exclude_node, exclude_instance):
        return zw.zway_cc_multichannel_association_remove(self._zway, node_id, instance_id, group_id, exclude_node, exclude_instance, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_multichannel_association_groupings_get(self, node_id, instance_id):
        return zw.zway_cc_multichannel_association_groupings_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_multichannel_get(self, node_id, instance_id, cc_id):
        return zw.zway_cc_multichannel_get(self._zway, node_id, instance_id, cc_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_multichannel_endpoint_find(self, node_id, instance_id, generic, specific):
        return zw.zway_cc_multichannel_endpoint_find(self._zway, node_id, instance_id, generic, specific, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_multichannel_endpoint_get(self, node_id, instance_id):
        return zw.zway_cc_multichannel_endpoint_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_multichannel_capabilities_get(self, node_id, instance_id, endpoint):
        return zw.zway_cc_multichannel_capabilities_get(self._zway, node_id, instance_id, endpoint, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_node_naming_get(self, node_id, instance_id):
        return zw.zway_cc_node_naming_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_node_naming_get_name(self, node_id, instance_id):
        return zw.zway_cc_node_naming_get_name(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_node_naming_get_location(self, node_id, instance_id):
        return zw.zway_cc_node_naming_get_location(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_node_naming_set_name(self, node_id, instance_id, name):
        return zw.zway_cc_node_naming_set_name(self._zway, node_id, instance_id, name, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_node_naming_set_location(self, node_id, instance_id, location):
        return zw.zway_cc_node_naming_set_location(self._zway, node_id, instance_id, location, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_thermostat_setpoint_get(self, node_id, instance_id, mode):
        return zw.zway_cc_thermostat_setpoint_get(self._zway, node_id, instance_id, mode, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_thermostat_setpoint_set(self, node_id, instance_id, mode, value):
        return zw.zway_cc_thermostat_setpoint_set(self._zway, node_id, instance_id, mode, value, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_thermostat_mode_get(self, node_id, instance_id):
        return zw.zway_cc_thermostat_mode_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_thermostat_mode_set(self, node_id, instance_id, mode):
        return zw.zway_cc_thermostat_mode_set(self._zway, node_id, instance_id, mode, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_thermostat_fan_mode_get(self, node_id, instance_id):
        return zw.zway_cc_thermostat_fan_mode_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_thermostat_fan_mode_set(self, node_id, instance_id, on, mode):
        return zw.zway_cc_thermostat_fan_mode_set(self._zway, node_id, instance_id, on, mode, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_thermostat_fan_state_get(self, node_id, instance_id):
        return zw.zway_cc_thermostat_fan_state_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_thermostat_operating_state_get(self, node_id, instance_id):
        return zw.zway_cc_thermostat_operating_state_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_thermostat_operating_state_logging_get(self, node_id, instance_id, state):
        return zw.zway_cc_thermostat_operating_state_logging_get(self._zway, node_id, instance_id, state, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_alarm_sensor_supported_get(self, node_id, instance_id):
        return zw.zway_cc_alarm_sensor_supported_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_alarm_sensor_get(self, node_id, instance_id, type):
        return zw.zway_cc_alarm_sensor_get(self._zway, node_id, instance_id, type, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_door_lock_get(self, node_id, instance_id):
        return zw.zway_cc_door_lock_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_door_lock_configuration_get(self, node_id, instance_id):
        return zw.zway_cc_door_lock_configuration_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_door_lock_set(self, node_id, instance_id, mode):
        return zw.zway_cc_door_lock_set(self._zway, node_id, instance_id, mode, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_door_lock_configuration_set(self, node_id, instance_id, opType, outsideState, insideState, lockMin, lockSec):
        return zw.zway_cc_door_lock_configuration_set(self._zway, node_id, instance_id, opType, outsideState, insideState, lockMin, lockSec, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_door_lock_logging_get(self, node_id, instance_id, record):
        return zw.zway_cc_door_lock_logging_get(self._zway, node_id, instance_id, record, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_user_code_get(self, node_id, instance_id, user):
        return zw.zway_cc_user_code_get(self._zway, node_id, instance_id, user, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_user_code_set(self, node_id, instance_id, user, code, status):
        return zw.zway_cc_user_code_set(self._zway, node_id, instance_id, user, code, status, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_time_time_get(self, node_id, instance_id):
        return zw.zway_cc_time_time_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_time_date_get(self, node_id, instance_id):
        return zw.zway_cc_time_date_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_time_offset_get(self, node_id, instance_id):
        return zw.zway_cc_time_offset_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_time_parameters_get(self, node_id, instance_id):
        return zw.zway_cc_time_parameters_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_time_parameters_set(self, node_id, instance_id):
        return zw.zway_cc_time_parameters_set(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_clock_get(self, node_id, instance_id):
        return zw.zway_cc_clock_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_clock_set(self, node_id, instance_id):
        return zw.zway_cc_clock_set(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_scene_activation_set(self, node_id, instance_id, sceneId, dimmingDuration):
        return zw.zway_cc_scene_activation_set(self._zway, node_id, instance_id, sceneId, dimmingDuration, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_scene_controller_conf_get(self, node_id, instance_id, group):
        return zw.zway_cc_scene_controller_conf_get(self._zway, node_id, instance_id, group, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_scene_controller_conf_set(self, node_id, instance_id, group, scene, duration):
        return zw.zway_cc_scene_controller_conf_set(self._zway, node_id, instance_id, group, scene, duration, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_scene_actuator_conf_get(self, node_id, instance_id, scene):
        return zw.zway_cc_scene_actuator_conf_get(self._zway, node_id, instance_id, scene, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_scene_actuator_conf_set(self, node_id, instance_id, scene, level, dimming, override):
        return zw.zway_cc_scene_actuator_conf_set(self._zway, node_id, instance_id, scene, level, dimming, override, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_indicator_get(self, node_id, instance_id):
        return zw.zway_cc_indicator_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_indicator_set(self, node_id, instance_id, val):
        return zw.zway_cc_indicator_set(self._zway, node_id, instance_id, val, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_protection_get(self, node_id, instance_id):
        return zw.zway_cc_protection_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_protection_set(self, node_id, instance_id, state, rfState):
        return zw.zway_cc_protection_set(self._zway, node_id, instance_id, state, rfState, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_protection_exclusive_get(self, node_id, instance_id):
        return zw.zway_cc_protection_exclusive_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_protection_exclusive_set(self, node_id, instance_id, controlNodeId):
        return zw.zway_cc_protection_exclusive_set(self._zway, node_id, instance_id, controlNodeId, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_protection_timeout_get(self, node_id, instance_id):
        return zw.zway_cc_protection_timeout_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_protection_timeout_set(self, node_id, instance_id, timeout):
        return zw.zway_cc_protection_timeout_set(self._zway, node_id, instance_id, timeout, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_schedule_entry_lock_enable(self, node_id, instance_id, user, enable):
        return zw.zway_cc_schedule_entry_lock_enable(self._zway, node_id, instance_id, user, enable, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_schedule_entry_lock_weekday_get(self, node_id, instance_id, user, slot):
        return zw.zway_cc_schedule_entry_lock_weekday_get(self._zway, node_id, instance_id, user, slot, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_schedule_entry_lock_weekday_set(self, node_id, instance_id, user, slot, dayOfWeek, startHour, startMinute, stopHour, stopMinute):
        return zw.zway_cc_schedule_entry_lock_weekday_set(self._zway, node_id, instance_id, user, slot, dayOfWeek, startHour, startMinute, stopHour, stopMinute, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_schedule_entry_lock_year_get(self, node_id, instance_id, user, slot):
        return zw.zway_cc_schedule_entry_lock_year_get(self._zway, node_id, instance_id, user, slot, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_schedule_entry_lock_year_set(self, node_id, instance_id, user, slot, startYear, startMonth, startDay, startHour, startMinute, stopYear, stopMonth, stopDay, stopHour, stopMinute):
        return zw.zway_cc_schedule_entry_lock_year_set(self._zway, node_id, instance_id, user, slot, startYear, startMonth, startDay, startHour, startMinute, stopYear, stopMonth, stopDay, stopHour, stopMinute, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_climate_control_schedule_override_get(self, node_id, instance_id):
        return zw.zway_cc_climate_control_schedule_override_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_climate_control_schedule_override_set(self, node_id, instance_id, overrideType, overrideState):
        return zw.zway_cc_climate_control_schedule_override_set(self._zway, node_id, instance_id, overrideType, overrideState, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_meter_table_monitor_status_date_get(self, node_id, instance_id, maxResults, startDate, endDate):
        return zw.zway_cc_meter_table_monitor_status_date_get(self._zway, node_id, instance_id, maxResults, startDate, endDate, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_meter_table_monitor_status_depth_get(self, node_id, instance_id, maxResults):
        return zw.zway_cc_meter_table_monitor_status_depth_get(self._zway, node_id, instance_id, maxResults, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_meter_table_monitor_current_data_get(self, node_id, instance_id, setId):
        return zw.zway_cc_meter_table_monitor_current_data_get(self._zway, node_id, instance_id, setId, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_meter_table_monitor_historical_data_get(self, node_id, instance_id, setId, maxResults, startDate, endDate):
        return zw.zway_cc_meter_table_monitor_historical_data_get(self._zway, node_id, instance_id, setId, maxResults, startDate, endDate, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_alarm_get(self, node_id, instance_id, type, event):
        return zw.zway_cc_alarm_get(self._zway, node_id, instance_id, type, event, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_alarm_set(self, node_id, instance_id, type, level):
        return zw.zway_cc_alarm_set(self._zway, node_id, instance_id, type, level, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_power_level_get(self, node_id, instance_id):
        return zw.zway_cc_power_level_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_power_level_set(self, node_id, instance_id, level, timeout):
        return zw.zway_cc_power_level_set(self._zway, node_id, instance_id, level, timeout, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_power_level_test_node_get(self, node_id, instance_id):
        return zw.zway_cc_power_level_test_node_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_power_level_test_node_set(self, node_id, instance_id, testNodeId, level, frameCount):
        return zw.zway_cc_power_level_test_node_set(self._zway, node_id, instance_id, testNodeId, level, frameCount, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_zwave_plus_info_get(self, node_id, instance_id):
        return zw.zway_cc_zwave_plus_info_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_firmware_update_get(self, node_id, instance_id):
        return zw.zway_cc_firmware_update_get(self._zway, node_id, instance_id, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_association_group_information_get_info(self, node_id, instance_id, groupId):
        return zw.zway_cc_association_group_information_get_info(self._zway, node_id, instance_id, groupId, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_association_group_information_get_name(self, node_id, instance_id, groupId):
        return zw.zway_cc_association_group_information_get_name(self._zway, node_id, instance_id, groupId, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_association_group_information_get_commands(self, node_id, instance_id, groupId):
        return zw.zway_cc_association_group_information_get_commands(self._zway, node_id, instance_id, groupId, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_switch_color_get(self, node_id, instance_id, capabilityId):
        return zw.zway_cc_switch_color_get(self._zway, node_id, instance_id, capabilityId, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_switch_color_set(self, node_id, instance_id, capabilityId, state, duration):
        return zw.zway_cc_switch_color_set(self._zway, node_id, instance_id, capabilityId, state, duration, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_switch_color_set_multiple(self, node_id, instance_id, length, capabilityIds, states, duration):
        return zw.zway_cc_switch_color_set_multiple(self._zway, node_id, instance_id, length, capabilityIds, states, duration, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_switch_color_start_state_change(self, node_id, instance_id, capabilityId, dir, ignoreStartLevel, startLevel):
        return zw.zway_cc_switch_color_start_state_change(self._zway, node_id, instance_id, capabilityId, dir, ignoreStartLevel, startLevel, c_job_success_callback, c_job_failure_callback, <void *> self)

    def cc_switch_color_stop_state_change(self, node_id, instance_id, capabilityId):
        return zw.zway_cc_switch_color_stop_state_change(self._zway, node_id, instance_id, capabilityId, c_job_success_callback, c_job_failure_callback, <void *> self)



