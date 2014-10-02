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
    ctypedef void (*ZDeviceCallback)(const ZWay wzay, ZWDeviceChangeType type, ZWBYTE node_id, ZWBYTE instance_id, ZWBYTE command_id, void *arg);

    # ZWayLib.h

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

    ZGuessedProduct *zway_device_guess(const ZWay zway, ZWBYTE node_id)

    void zway_device_guess_free(ZGuessedProduct *products)

    void zway_device_awake_queue(const ZWay zway, ZWBYTE node_id)

    ZWError zway_device_add_callback(const ZWay zway, ZWDeviceChangeType mask, ZDeviceCallback callback, void *arg)

    ZWError zway_device_remove_callback(const ZWay zway, ZDeviceCallback callback)

    # ZWError zway_device_add_callback_ex(const ZWay zway, ZWDeviceChangeType mask, ZDeviceCallback callback, void *arg)

    # ZWError zway_device_remove_callback_ex(const ZWay zway, ZDeviceCallback callback, void *arg)

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
