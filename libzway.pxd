from libc.stdio cimport FILE

cdef extern from "ZWayLib.h":
    cdef struct _ZWay:
        pass

    ctypedef _ZWay* ZWay

    ctypedef void (*ZTerminationCallback)(ZWay zway)
    ctypedef void (*ZDeviceCallback)(ZWay wzay, int type, unsigned char node_id, unsigned char instance_id, unsigned char command_id, void *arg)

    cdef struct _ZGuessedProduct:
        int score
        char* vendor
        char* product
        char* image_url
        char* file_name

    ctypedef _ZGuessedProduct *ZGuessedProduct

    ctypedef unsigned char * ZWDevicesList;
    ctypedef unsigned char * ZWInstancesList;
    ctypedef unsigned char * ZWCommandClassesList;

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