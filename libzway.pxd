from libc.stdio cimport FILE

cdef extern from "ZWayLib.h":
    ctypedef long time_t

    cdef struct _ZWay:
        pass

    ctypedef _ZWay* ZWay

    cdef struct _ZDataHolder
    ctypedef _ZDataHolder *ZDataHolder

    cdef struct _ZDataIterator:
        ZDataHolder data

    ctypedef _ZDataIterator *ZDataIterator

    cdef struct _ZGuessedProduct:
        int score
        char* vendor
        char* product
        char* image_url
        char* file_name

    ctypedef _ZGuessedProduct *ZGuessedProduct

    ctypedef unsigned char * ZWDevicesList
    ctypedef unsigned char * ZWInstancesList
    ctypedef unsigned char * ZWCommandClassesList

    ctypedef void (*ZTerminationCallback)(ZWay zway)
    ctypedef void (*ZDeviceCallback)(ZWay wzay, int type, unsigned char node_id, unsigned char instance_id, unsigned char command_id, void *arg)
    ctypedef void (*ZJobCustomCallback)(ZWay zway, unsigned char functionId, void* arg)
    ctypedef void (*ZDataChangeCallback)(ZWay wzay, int type, ZDataHolder data, void *arg)

    # Taken from ZWayLib.h
    # Excludes zway_device_add_callback_ex, zway_device_remove_callback_ex
    int zway_init(ZWay *pzway, char* port, char* config_folder, char* translations_folder, char* zddx_folder, FILE* log, int level)
    void zway_terminate(ZWay *pzway)
    int zway_set_log(ZWay zway, FILE* log, int level)
    int zway_start(ZWay zway, ZTerminationCallback termination_callback)
    int zway_stop(ZWay zway)
    int zway_discover(ZWay zway)
    unsigned char zway_is_idle(ZWay zway)
    unsigned char zway_is_running(ZWay zway)
    int zway_device_send_nop(ZWay zway, unsigned char)
    int zway_device_load_xml(ZWay zway, unsigned char node_id, char* file_name)
    ZGuessedProduct *zway_device_guess(ZWay zway, unsigned char node_id)
    void zway_device_guess_free(ZGuessedProduct *products)
    void zway_device_awake_queue(ZWay zway, unsigned char node_id)
    int zway_device_add_callback(ZWay zway, int mask, ZDeviceCallback callback, void *arg)
    int zway_device_remove_callback(ZWay zway, ZDeviceCallback callback)
    int zway_command_interview(ZWay zway, unsigned char device_id, unsigned char instance_id, unsigned char cc_id)
    int zway_device_interview_force(ZWay zway, unsigned char device_id)
    unsigned char zway_device_is_interview_done(ZWay zway, unsigned char device_id)
    int zway_device_assign_return_route(ZWay zway, unsigned char device_id, unsigned char node_id)
    int zway_device_delete_return_route(ZWay zway, unsigned char device_id)
    int zway_device_assign_suc_return_route(ZWay zway, unsigned char device_id)
    int zway_controller_set_suc_node_id(ZWay zway, unsigned char node_id)
    int zway_controller_set_sis_node_id(ZWay zway, unsigned char node_id)
    int zway_controller_disable_suc_node_id(ZWay zway, unsigned char node_id)
    int zway_controller_change(ZWay zway, unsigned char startStop)
    int zway_controller_add_node_to_network(ZWay zway, unsigned char startStop)
    int zway_controller_remove_node_from_network(ZWay zway, unsigned char startStop)
    int zway_controller_set_learn_mode(ZWay zway, unsigned char startStop)
    int zway_controller_set_default(ZWay zway)
    int zway_controller_config_restore(ZWay zway, unsigned char *data, size_t length, unsigned char full)
    int zddx_save_to_xml(ZWay zway)
    ZWDevicesList zway_devices_list(ZWay zway)
    void zway_devices_list_free(ZWDevicesList list)
    ZWInstancesList zway_instances_list(ZWay zway, unsigned char deviceId)
    void zway_command_classes_list_free(ZWCommandClassesList list)
    ZWCommandClassesList zway_command_classes_list(ZWay zway, unsigned char deviceId, unsigned char instanceId)
    void zway_command_classes_list_free(ZWCommandClassesList list)
    unsigned char zway_command_is_supported(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char command_id)

    # Taken from FunctionClassesPublic.h
    int zway_fc_get_serial_api_capabilities(ZWay zway, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_serial_api_set_timeouts(ZWay zway, unsigned char ackTimeout, unsigned char byteTimeout, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_serial_api_get_init_data(ZWay zway, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_serial_api_application_node_info(ZWay zway, unsigned char listening, unsigned char optional, unsigned char flirs1000, unsigned char flirs250, unsigned char generic_class, unsigned char specific_class, unsigned char nif_size, unsigned char* nif, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_watchdog_start(ZWay zway, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_watchdog_stop(ZWay zway, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_get_home_id(ZWay zway, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_get_controller_capabilities(ZWay zway, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_get_version(ZWay zway, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_get_suc_node_id(ZWay zway, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_enable_suc(ZWay zway, unsigned char enable, unsigned char sis, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_set_suc_node_id(ZWay zway, unsigned char node_id, unsigned char enable, unsigned char sis, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_memory_get_byte(ZWay zway, unsigned short offset, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_memory_get_buffer(ZWay zway, unsigned short offset, unsigned char length, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_memory_put_byte(ZWay zway, unsigned short offset, unsigned char data, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_memory_put_buffer(ZWay zway, unsigned short offset, unsigned char length, unsigned char* data, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_nvm_get_id(ZWay zway, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_nvm_ext_read_long_byte(ZWay zway, unsigned int offset, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_nvm_ext_read_long_buffer(ZWay zway, unsigned int offset, unsigned short length, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_nvm_ext_write_long_byte(ZWay zway, unsigned int offset, unsigned char data, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_nvm_ext_write_long_buffer(ZWay zway, unsigned int offset, unsigned short length, unsigned char* data, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_is_failed_node(ZWay zway, unsigned char node_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_send_data_abort(ZWay zway, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_serial_api_soft_reset(ZWay zway, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_send_data(ZWay zway, unsigned char node_id, unsigned char length, unsigned char* data, unsigned char* description, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_get_node_protocol_info(ZWay zway, unsigned char node_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_get_routing_table_line(ZWay zway, unsigned char node_id, unsigned char remove_bad, unsigned char remove_repeaters, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_assign_return_route(ZWay zway, unsigned char node_id, unsigned char dest_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_assign_suc_return_route(ZWay zway, unsigned char node_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_delete_return_route(ZWay zway, unsigned char node_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_delete_suc_return_route(ZWay zway, unsigned char node_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_set_default(ZWay zway, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_send_suc_node_id(ZWay zway, unsigned char node_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_send_node_information(ZWay zway, unsigned char node_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_request_node_information(ZWay zway, unsigned char node_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_remove_failed_node(ZWay zway, unsigned char node_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_replace_failed_node(ZWay zway, unsigned char node_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_request_network_update(ZWay zway, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_request_node_neighbour_update(ZWay zway, unsigned char node_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_set_learn_mode(ZWay zway, unsigned char startStop, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_add_node_to_network(ZWay zway, unsigned char startStop, unsigned char highPower,  ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_remove_node_from_network(ZWay zway, unsigned char startStop, unsigned char highPower, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_controller_change(ZWay zway, unsigned char startStop, unsigned char highPower, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_create_new_primary(ZWay zway, unsigned char startStop, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_fc_zme_freq_change(ZWay zway, unsigned char freq, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    # Taken from CommandClassesPublic.h
    int zway_cc_basic_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_basic_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char value, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_wakeup_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_wakeup_capabilities_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_wakeup_sleep(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_wakeup_set(ZWay zway, unsigned char node_id, unsigned char instance_id, int interval, unsigned char notification_node_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_battery_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_manufacturer_specific_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_configuration_get(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char parameter, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_configuration_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char parameter, int value, unsigned char size, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_configuration_set_default(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char parameter, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_sensor_binary_get(ZWay zway, unsigned char node_id, unsigned char instance_id, int sensorType, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_association_get(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char group_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_association_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char group_id, unsigned char include_node, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_association_remove(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char group_id, unsigned char exclude_node, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_association_groupings_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_meter_get(ZWay zway, unsigned char node_id, unsigned char instance_id, int scale, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_meter_reset(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_meter_supported(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_sensor_multilevel_get(ZWay zway, unsigned char node_id, unsigned char instance_id, int sensor_type, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_sensor_configuration_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_sensor_configuration_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char mode, float value, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_switch_all_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_switch_all_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char mode, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_switch_all_set_on(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_switch_all_set_off(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_switch_binary_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_switch_binary_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char value, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_switch_multilevel_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_switch_multilevel_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char level, unsigned char duration, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_switch_multilevel_start_level_change(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char dir, unsigned char duration, unsigned char ignoreStartLevel, unsigned char startLevel, unsigned char incdec, unsigned char step, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_switch_multilevel_stop_level_change(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_multichannel_association_get(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char group_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_multichannel_association_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char group_id, unsigned char include_node, unsigned char include_instance, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_multichannel_association_remove(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char group_id, unsigned char exclude_node, unsigned char exclude_instance, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_multichannel_association_groupings_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_multichannel_get(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char cc_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_multichannel_endpoint_find(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char generic, unsigned char specific, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_multichannel_endpoint_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_multichannel_capabilities_get(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char endpoint, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_node_naming_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_node_naming_get_name(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_node_naming_get_location(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_node_naming_set_name(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char* name, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_node_naming_set_location(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char* location, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_thermostat_setpoint_get(ZWay zway, unsigned char node_id, unsigned char instance_id, int mode, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_thermostat_setpoint_set(ZWay zway, unsigned char node_id, unsigned char instance_id, int mode, float value, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_thermostat_mode_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_thermostat_mode_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char mode, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_thermostat_fan_mode_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_thermostat_fan_mode_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char on, unsigned char mode, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_thermostat_fan_state_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_thermostat_operating_state_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_thermostat_operating_state_logging_get(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char state, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_alarm_sensor_supported_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_alarm_sensor_get(ZWay zway, unsigned char node_id, unsigned char instance_id, int type, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_door_lock_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_door_lock_configuration_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_door_lock_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char mode, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_door_lock_configuration_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char opType, unsigned char outsideState, unsigned char insideState, unsigned char lockMin, unsigned char lockSec, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_door_lock_logging_get(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char record, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_user_code_get(ZWay zway, unsigned char node_id, unsigned char instance_id, int user, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_user_code_set(ZWay zway, unsigned char node_id, unsigned char instance_id, int user, unsigned char* code, unsigned char status, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_user_code_set_raw(ZWay zway, unsigned char node_id, unsigned char instance_id, int user, unsigned char length, unsigned char *code, unsigned char status, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_time_time_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_time_date_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_time_offset_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_time_parameters_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_time_parameters_set(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_clock_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_clock_set(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_scene_activation_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char sceneId, unsigned char dimmingDuration, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_scene_controller_conf_get(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char group, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_scene_controller_conf_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char group, unsigned char scene, unsigned char duration, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_scene_actuator_conf_get(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char scene, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_scene_actuator_conf_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char scene, unsigned char level, unsigned char dimming, unsigned char override, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_indicator_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_indicator_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char val, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_protection_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_protection_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char state, unsigned char rfState, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_protection_exclusive_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_protection_exclusive_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char controlNodeId, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_protection_timeout_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_protection_timeout_set(ZWay zway, unsigned char node_id, unsigned char instance_id, int timeout, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_schedule_entry_lock_enable(ZWay zway, unsigned char node_id, unsigned char instance_id, int user, unsigned char enable, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_schedule_entry_lock_weekday_get(ZWay zway, unsigned char node_id, unsigned char instance_id, int user, unsigned char slot, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_schedule_entry_lock_weekday_set(ZWay zway, unsigned char node_id, unsigned char instance_id, int user, unsigned char slot, unsigned char dayOfWeek, unsigned char startHour, unsigned char startMinute, unsigned char stopHour, unsigned char stopMinute, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_schedule_entry_lock_year_get(ZWay zway, unsigned char node_id, unsigned char instance_id, int user, unsigned char slot, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_schedule_entry_lock_year_set(ZWay zway, unsigned char node_id, unsigned char instance_id, int user, unsigned char slot, unsigned char startYear, unsigned char startMonth, unsigned char startDay, unsigned char startHour, unsigned char startMinute, unsigned char stopYear, unsigned char stopMonth, unsigned char stopDay, unsigned char stopHour, unsigned char stopMinute, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_climate_control_schedule_override_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_climate_control_schedule_override_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char overrideType, unsigned char overrideState, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_meter_table_monitor_status_date_get(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char maxResults, time_t startDate, time_t endDate, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_meter_table_monitor_status_depth_get(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char maxResults, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_meter_table_monitor_current_data_get(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char setId, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_meter_table_monitor_historical_data_get(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char setId, unsigned char maxResults, time_t startDate, time_t endDate, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_alarm_get(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char type, unsigned char event, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_alarm_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char type, unsigned char level, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_power_level_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_power_level_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char level, unsigned char timeout, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_power_level_test_node_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_power_level_test_node_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char testNodeId, unsigned char level, int frameCount, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_zwave_plus_info_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_firmware_update_get(ZWay zway, unsigned char node_id, unsigned char instance_id, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_firmware_update_perform(ZWay zway, unsigned char node_id, unsigned char instance_id, int manufacturerId, int firmwareId, unsigned char firmwareTarget, size_t length, unsigned char *data, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_association_group_information_get_info(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char groupId, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_association_group_information_get_name(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char groupId, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_association_group_information_get_commands(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char groupId, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_switch_color_get(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char capabilityId, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_switch_color_set(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char capabilityId, unsigned char state, unsigned char duration, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_switch_color_set_multiple(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char length, unsigned char * capabilityIds, unsigned char * states, unsigned char duration, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_switch_color_start_state_change(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char capabilityId, unsigned char dir, unsigned char ignoreStartLevel, unsigned char startLevel, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)
    int zway_cc_switch_color_stop_state_change(ZWay zway, unsigned char node_id, unsigned char instance_id, unsigned char capabilityId, ZJobCustomCallback successCallback, ZJobCustomCallback failureCallback, void* callbackArg)

    # Taken from ZDataPublic.h
    # Excludes zway_data_add_callback_ex, zway_data_remove_callback_ex
    int zway_data_invalidate(ZWay zway, ZDataHolder data, unsigned char invalidate_children)
    int zway_data_add_callback(ZWay zway, ZDataHolder data, ZDataChangeCallback callback, unsigned char watch_children, void *arg)
    int zway_data_remove_callback(ZWay zway, ZDataHolder data, ZDataChangeCallback callback)
    int zway_data_add_callback_ex(ZWay zway, ZDataHolder data, ZDataChangeCallback callback, unsigned char watch_children, void *arg)
    int zway_data_remove_callback_ex(ZWay zway, ZDataHolder data, ZDataChangeCallback callback, void *arg)
    int zway_data_set_empty(ZWay zway, ZDataHolder data)
    int zway_data_set_boolean(ZWay zway, ZDataHolder data, unsigned char value)
    int zway_data_set_integer(ZWay zway, ZDataHolder data, int value)
    int zway_data_set_float(ZWay zway, ZDataHolder data, float value)
    int zway_data_set_string(ZWay zway, ZDataHolder data, unsigned char* value, unsigned char copy)
    int zway_data_set_string_fmt(ZWay zway, ZDataHolder data, unsigned char* format, ...)
    int zway_data_set_integer_array(ZWay zway, ZDataHolder data, int *value, size_t count)
    int zway_data_set_float_array(ZWay zway, ZDataHolder data, float *value, size_t count)
    int zway_data_set_binary(ZWay zway, ZDataHolder data, unsigned char *value, size_t length, unsigned char copy)
    int zway_data_set_string_array(ZWay zway, ZDataHolder data, unsigned char* *value, size_t count, unsigned char copy)
    int zway_data_get_type(ZWay zway, ZDataHolder data, unsigned char *type)
    int zway_data_get_boolean(ZWay zway, ZDataHolder data, unsigned char* value)
    int zway_data_get_integer(ZWay zway, ZDataHolder data, int *value)
    int zway_data_get_float(ZWay zway, ZDataHolder data, float *value)
    int zway_data_get_string(ZWay zway, ZDataHolder data, unsigned char* *value)
    int zway_data_get_integer_array(ZWay zway, ZDataHolder data, int **value, size_t *count)
    int zway_data_get_float_array(ZWay zway, ZDataHolder data, float **value, size_t *count)
    int zway_data_get_string_array(ZWay zway, ZDataHolder data, unsigned char* **value, size_t *count)
    int zway_data_get_binary(ZWay zway, ZDataHolder data, unsigned char **value, size_t *length)
    ZDataHolder zway_find_data(ZWay zway, ZDataHolder root, char* path)
    ZDataHolder zway_find_controller_data(ZWay zway, char* path)
    ZDataHolder zway_find_device_data(ZWay zway, unsigned char device_id, char* path)
    ZDataHolder zway_find_device_instance_data(ZWay zway, unsigned char device_id, unsigned char instance_id, char* path)
    ZDataHolder zway_find_device_instance_cc_data(ZWay zway, unsigned char device_id, unsigned char instance_id, unsigned char cc_id, char* path)
    unsigned char zway_data_is_empty(ZWay zway, ZDataHolder data)
    char* zway_data_get_path(ZWay zway, ZDataHolder data)
    char* zway_data_get_name(ZWay zway, ZDataHolder data)
    ZDataIterator zway_data_first_child(ZWay zway, ZDataHolder data)
    ZDataIterator zway_data_next_child(ZDataIterator child)
    int zway_data_remove_child(ZWay zway, ZDataHolder data, ZDataHolder child)
    time_t zway_data_get_update_time(ZDataHolder data)
    time_t zway_data_get_invalidate_time(ZDataHolder data)
    void zway_data_acquire_lock(ZWay zway)
    void zway_data_release_lock(ZWay zway)