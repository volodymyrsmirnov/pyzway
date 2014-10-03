"""
 Copyright (C) 2014, Vladimir Smirnov (vladimir@smirnov.im)

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the license for more details.
"""

from libc.stdio cimport FILE

cdef extern from "Python.h":
    void PyEval_InitThreads()

cdef extern from "ZWayLib.h":
    ctypedef long time_t

    cdef struct _ZWay:
        pass

    ctypedef _ZWay* ZWay

    cdef struct _ZGuessedProduct:
        int score
        char *vendor
        char *product
        char *image_url
        char *file_name

    ctypedef _ZGuessedProduct *ZGuessedProduct

    ctypedef int ZWError
    ctypedef char* ZWCSTR
    ctypedef int ZWLogLevel
    ctypedef int ZWDeviceChangeType
    ctypedef unsigned char ZWBOOL
    ctypedef unsigned char ZWBYTE
    ctypedef ZWBYTE* ZWDevicesList
    ctypedef ZWBYTE* ZWInstancesList
    ctypedef ZWBYTE* ZWCommandClassesList

    ctypedef void (*ZTerminationCallback)(const ZWay zway)
    ctypedef void (*ZDeviceCallback)(const ZWay wzay, ZWDeviceChangeType type, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE command_id, void *arg)
    ctypedef void (*ZJobCustomCallback)(const ZWay zway, ZWBYTE functionId, void* arg)

    # ZWayLib.h

    ZGuessedProduct *zway_device_guess(const ZWay zway, ZWBYTE node_id)

    ZWError zway_init(ZWay *pzway, ZWCSTR port, ZWCSTR config_folder, ZWCSTR translations_folder, ZWCSTR zddx_folder, FILE* log, ZWLogLevel level)

    void zway_terminate(ZWay *pzway)

    ZWError zway_set_log(ZWay zway, FILE* log, ZWLogLevel level)

    ZWError zway_start(ZWay zway, ZTerminationCallback termination_callback)

    ZWError zway_stop(ZWay zway)

    ZWError zway_discover(ZWay zway)

    ZWBOOL zway_is_idle(ZWay zway)

    ZWBOOL zway_is_running(ZWay zway)

    ZWError zway_device_send_nop(ZWay zway, ZWBYTE node_id)

    ZWError zway_device_load_xml(const ZWay zway, ZWBYTE node_id, ZWCSTR file_name)

    void zway_device_guess_free(ZGuessedProduct *products)

    void zway_device_awake_queue(const ZWay zway, ZWBYTE node_id)

    ZWError zway_device_add_callback(const ZWay zway, ZWDeviceChangeType mask, ZDeviceCallback callback, void *arg)

    ZWError zway_device_remove_callback(const ZWay zway, ZDeviceCallback callback)

    ZWError zway_command_interview(const ZWay zway, ZWBYTE device_id, ZWBYTE instance_id, ZWBYTE cc_id)

    ZWError zway_device_interview_force(const ZWay zway, ZWBYTE device_id)

    ZWBOOL zway_device_is_interview_done(const ZWay zway, ZWBYTE device_id)

    ZWError zway_device_assign_return_route(const ZWay zway, ZWBYTE device_id, ZWBYTE node_id)

    ZWError zway_device_delete_return_route(const ZWay zway, ZWBYTE device_id)

    ZWError zway_device_assign_suc_return_route(const ZWay zway, ZWBYTE device_id)

    ZWError zway_device_delete_suc_return_route(const ZWay zway, ZWBYTE device_id)

    ZWError zway_controller_set_suc_node_id(ZWay zway, ZWBYTE node_id)

    ZWError zway_controller_set_sis_node_id(ZWay zway, ZWBYTE node_id)

    ZWError zway_controller_disable_suc_node_id(ZWay zway, ZWBYTE node_id)

    ZWError zway_controller_change(ZWay zway, ZWBOOL startStop)

    ZWError zway_controller_add_node_to_network(ZWay zway, ZWBOOL startStop)

    ZWError zway_controller_remove_node_from_network(ZWay zway, ZWBOOL startStop)

    ZWError zway_controller_set_learn_mode(ZWay zway, ZWBOOL startStop)

    ZWError zway_controller_set_default(ZWay zway)

    ZWError zway_controller_config_save(ZWay zway, ZWBYTE **data, size_t *length)

    ZWError zway_controller_config_restore(ZWay zway, const ZWBYTE *data, size_t length, ZWBOOL full)

    ZWError zddx_save_to_xml(const ZWay zway)

    ZWDevicesList zway_devices_list(const ZWay zway)

    void zway_devices_list_free(ZWDevicesList list)

    ZWInstancesList zway_instances_list(const ZWay zway, ZWBYTE deviceId)

    void zway_instances_list_free(ZWInstancesList list)

    ZWCommandClassesList zway_command_classes_list(const ZWay zway, ZWBYTE deviceId, ZWBYTE instanceId)

    void zway_command_classes_list_free(ZWCommandClassesList list)

    ZWBOOL zway_command_is_supported(const ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE command_id)



    # CommandClassesPublic.h

    ZWError zway_cc_basic_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_basic_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE value, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_wakeup_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_wakeup_capabilities_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_wakeup_sleep(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_wakeup_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int interval, ZWBYTE notification_node_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_battery_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_manufacturer_specific_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_configuration_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE parameter, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_configuration_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE parameter, int value, ZWBYTE size, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_configuration_set_default(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE parameter, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_sensor_binary_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int sensorType, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_association_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE group_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_association_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE group_id, ZWBYTE include_node, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_association_remove(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE group_id, ZWBYTE exclude_node, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_association_groupings_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_meter_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int scale, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_meter_reset(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_meter_supported(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_sensor_multilevel_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int sensor_type, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_sensor_configuration_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_sensor_configuration_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE mode, float value, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_switch_all_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_switch_all_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE mode, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_switch_all_set_on(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_switch_all_set_off(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_switch_binary_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_switch_binary_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBOOL value, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_switch_multilevel_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_switch_multilevel_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE level, ZWBYTE duration, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_switch_multilevel_start_level_change(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE dir, ZWBYTE duration, ZWBOOL ignoreStartLevel, ZWBYTE startLevel, ZWBYTE incdec, ZWBYTE step, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_switch_multilevel_stop_level_change(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_multichannel_association_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE group_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_multichannel_association_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE group_id, ZWBYTE include_node, ZWBYTE include_instance, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_multichannel_association_remove(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE group_id, ZWBYTE exclude_node, ZWBYTE exclude_instance, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_multichannel_association_groupings_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_multichannel_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE cc_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_multichannel_endpoint_find(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE generic, ZWBYTE specific, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_multichannel_endpoint_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_multichannel_capabilities_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE endpoint, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_node_naming_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_node_naming_get_name(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_node_naming_get_location(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_node_naming_set_name(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWCSTR name, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_node_naming_set_location(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWCSTR location, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_thermostat_setpoint_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int mode, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_thermostat_setpoint_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int mode, float value, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_thermostat_mode_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_thermostat_mode_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE mode, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_thermostat_fan_mode_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_thermostat_fan_mode_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBOOL on, ZWBYTE mode, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_thermostat_fan_state_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_thermostat_operating_state_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_thermostat_operating_state_logging_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE state, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_alarm_sensor_supported_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_alarm_sensor_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int type, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_door_lock_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_door_lock_configuration_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_door_lock_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE mode, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_door_lock_configuration_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE opType, ZWBYTE outsideState, ZWBYTE insideState, ZWBYTE lockMin, ZWBYTE lockSec, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_door_lock_logging_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE record, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_user_code_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int user, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_user_code_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int user, ZWCSTR code, ZWBYTE status, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_time_time_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_time_date_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_time_offset_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_time_parameters_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_time_parameters_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_clock_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_clock_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_scene_activation_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE sceneId, ZWBYTE dimmingDuration, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_scene_controller_conf_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE group, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_scene_controller_conf_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE group, ZWBYTE scene, ZWBYTE duration, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_scene_actuator_conf_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE scene, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_scene_actuator_conf_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE scene, ZWBYTE level, ZWBYTE dimming, ZWBOOL override, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_indicator_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_indicator_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE val, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_protection_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_protection_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE state, ZWBYTE rfState, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_protection_exclusive_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_protection_exclusive_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE controlNodeId, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_protection_timeout_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_protection_timeout_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int timeout, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_schedule_entry_lock_enable(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int user, ZWBOOL enable, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_schedule_entry_lock_weekday_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int user, ZWBYTE slot, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_schedule_entry_lock_weekday_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int user, ZWBYTE slot, ZWBYTE dayOfWeek, ZWBYTE startHour, ZWBYTE startMinute, ZWBYTE stopHour, ZWBYTE stopMinute, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_schedule_entry_lock_year_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int user, ZWBYTE slot, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_schedule_entry_lock_year_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int user, ZWBYTE slot, ZWBYTE startYear, ZWBYTE startMonth, ZWBYTE startDay, ZWBYTE startHour, ZWBYTE startMinute, ZWBYTE stopYear, ZWBYTE stopMonth, ZWBYTE stopDay, ZWBYTE stopHour, ZWBYTE stopMinute, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_climate_control_schedule_override_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_climate_control_schedule_override_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE overrideType, ZWBYTE overrideState, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_meter_table_monitor_status_date_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE maxResults, time_t startDate, time_t endDate, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_meter_table_monitor_status_depth_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE maxResults, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_meter_table_monitor_current_data_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE setId, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_meter_table_monitor_historical_data_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE setId, ZWBYTE maxResults, time_t startDate, time_t endDate, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_alarm_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE type, ZWBYTE event, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_alarm_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE type, ZWBYTE level, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_power_level_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_power_level_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE level, ZWBYTE timeout, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_power_level_test_node_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_power_level_test_node_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE testNodeId, ZWBYTE level, int frameCount, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_zwave_plus_info_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_firmware_update_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_firmware_update_perform(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, int manufacturerId, int firmwareId, ZWBYTE firmwareTarget, size_t length, const ZWBYTE *data, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_association_group_information_get_info(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE groupId, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_association_group_information_get_name(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE groupId, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_association_group_information_get_commands(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE groupId, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_switch_color_get(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE capabilityId, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_switch_color_set(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE capabilityId, ZWBYTE state, ZWBYTE duration, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_switch_color_set_multiple(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE length, const ZWBYTE * capabilityIds, const ZWBYTE * states, ZWBYTE duration, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_switch_color_start_state_change(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE capabilityId, ZWBYTE dir, ZWBOOL ignoreStartLevel, ZWBYTE startLevel, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    ZWError zway_cc_switch_color_stop_state_change(ZWay zway, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE capabilityId, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)



# Internal definitions

cdef struct _DeviceCallbackInfo:
        ZWDeviceChangeType type
        ZWBYTE node_id
        ZWBYTE instance_id
        ZWBYTE command_id
        void* instance

ctypedef _DeviceCallbackInfo* DeviceCallbackInfo

cdef struct _JobCallbackInfo:
    ZWBYTE success
    ZWBYTE function_id
    void* instance

ctypedef _JobCallbackInfo* JobCallbackInfo