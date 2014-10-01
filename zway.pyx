cimport libzway
cimport cython
from libc.stdio cimport fopen

cdef void* zway_global = NULL

cdef void c_termination_callback(libzway.ZWay zway):
    global zway_global
    (<ZWay?>zway_global).on_terminate()

cdef void c_device_callback(libzway.ZWay wzay, int type, unsigned char node_id, unsigned char instance_id, unsigned char command_id, void *arg):
    global zway_global
    (<ZWay?>zway_global).on_device(type, node_id, instance_id, command_id)

class ZWDeviceChangeType:
    DeviceAdded = 0x01
    DeviceRemoved = 0x02
    InstanceAdded = 0x04
    InstanceRemoved = 0x08
    CommandAdded = 0x10
    CommandRemoved = 0x20
    ZDDXSaved = 0x100

cdef class ZWay:
    cdef libzway.ZWay _zway

    def on_error(self, errno, message, path = None):
        if errno != 0:
            raise EnvironmentError(
                (errno, message) if not path else (errno, message, path)
            )

    def on_terminate(self):
        pass

    def on_device(self, int type, unsigned char node_id, unsigned char instance_id, unsigned char command_id):
        pass

    def __cinit__ (self, bytes port, bytes config_folder, bytes translations_folder, bytes zddx_folder, bytes log, int level = 0):
        global zway_global
        zway_global = <void *>self

        self.on_error(
            libzway.zway_init(
                &self._zway, port,
                config_folder, translations_folder, zddx_folder,
                fopen(<char *> log, "wb") if log else NULL, level
            ), "zway initialization failed"
        )

    def terminate(self):
        libzway.zway_terminate(&self._zway)

    def set_log(self, bytes log, int level = 0):
        self.on_error(
            libzway.zway_set_log(
                self._zway, fopen(<char *> log, "wb") if log else NULL, level
            ), "zway setting log failed", (log,)
        )

    def start(self):
        self.on_error(
            libzway.zway_start(
                self._zway, c_termination_callback
            ), "zway initialization failed"
        )

    def stop(self):
        self.on_error(
            libzway.zway_stop(
                self._zway
            ), "zway stop failed"
        )

    def discover(self):
        self.on_error(
            libzway.zway_discover(
                self._zway
            ), "zway discover failed"
        )

    def is_idle(self):
        return libzway.zway_is_idle(self._zway) != 0

    def is_running(self):
        return libzway.zway_is_running(self._zway) != 0

    def device_send_nop(self, int node_id):
        self.on_error(
            libzway.zway_device_send_nop(
                self._zway, <unsigned char> node_id
            ), "zway discover failed", node_id
        )

    def device_load_xml(self, int node_id, bytes file_name):
        self.on_error(
            libzway.zway_device_load_xml(
                self._zway, <unsigned char> node_id, file_name
            ), "zway device load xml failed", (node_id, file_name)
        )

    def device_guess(self, int node_id):
        cdef libzway.ZGuessedProduct *products = libzway.zway_device_guess(self._zway, <unsigned char> node_id)
        cdef libzway.ZGuessedProduct product =  <libzway.ZGuessedProduct> cython.operator.dereference(products)

        result = []

        while product != NULL:
            result.append({
                "score": product.score,
                "vendor": product.vendor,
                "product": product.product,
                "image_url": product.image_url,
                "file_name": product.file_name,
            })

            cython.operator.preincrement(product)

        libzway.zway_device_guess_free(products)

        return result

    def device_awake_queue(self, int node_id):
        libzway.zway_device_awake_queue(self._zway, <unsigned char> node_id)

    def device_add_callback(self, int mask, device_callback):
        self.on_error(
            libzway.zway_device_add_callback(
                self._zway, mask, c_device_callback, NULL
            ), "zway device add callback failed", mask
        )

    def device_remove_callback(self):
        self.on_error(
            libzway.zway_device_remove_callback(
                self._zway, c_device_callback
            ), "zway device remove callback failed"
        )

    def command_interview(self, int device_id, int instance_id, int cc_id):
        self.on_error(
            libzway.zway_command_interview(
                self._zway, <unsigned char> device_id, <unsigned char> instance_id, <unsigned char> cc_id
            ), "zway command interview failed", (device_id, instance_id, cc_id)
        )

    def device_interview_force(self, int node_id):
        self.on_error(
            libzway.zway_device_interview_force(
                self._zway, <unsigned char> node_id
            ), "zway device force interview failed", node_id
        )

    def zway_device_is_interview_done(self, int device_id):
        return libzway.zway_device_is_interview_done(self._zway, <unsigned char> device_id)

    def device_assign_return_route(self, int device_id, int node_id):
        self.on_error(
            libzway.zway_device_assign_return_route(
                self._zway, <unsigned char> device_id, <unsigned char> node_id
            ), "zway device assign return route failed", (device_id, node_id)
        )

    def device_delete_return_route(self, int device_id):
        self.on_error(
            libzway.zway_device_delete_return_route(
                self._zway, <unsigned char> device_id
            ), "zway device delete return route failed", device_id
        )

    def device_assign_suc_return_route(self, int device_id):
        self.on_error(
            libzway.zway_device_assign_suc_return_route(
                self._zway, <unsigned char> device_id
            ), "zway device assign suc return route failed", device_id
        )

    def controller_set_suc_node_id(self, int node_id):
        self.on_error(
            libzway.zway_controller_set_suc_node_id(
                self._zway, <unsigned char> node_id
            ), "zway controller set suc node id failed", node_id
        )

    def controller_set_sis_node_id(self, int node_id):
        self.on_error(
            libzway.zway_controller_set_sis_node_id(
                self._zway, <unsigned char> node_id
            ), "zway controller set sis node id failed", node_id
        )

    def controller_disable_suc_node_id(self, int node_id):
        self.on_error(
            libzway.zway_controller_disable_suc_node_id(
                self._zway, <unsigned char> node_id
            ), "zway controller disable suc node id failed", node_id
        )

    def controller_change(self, bool activate = True):
        self.on_error(
            libzway.zway_controller_change(
                self._zway, <unsigned char> (1 if activate else 0)
            ), "zway controller change failed", activate
        )

    def controller_add_node_to_network(self, bool activate = True):
        self.on_error(
            libzway.zway_controller_add_node_to_network(
                self._zway, <unsigned char> (1 if activate else 0)
            ), "zway controller add node to network failed", activate
        )

    def controller_remove_node_from_network(self, bool activate = True):
        self.on_error(
            libzway.zway_controller_remove_node_from_network(
                self._zway, <unsigned char> (1 if activate else 0)
            ), "zway controller remove node from network failed", activate
        )

    def controller_set_learn_mode(self, bool activate = True):
        self.on_error(
            libzway.zway_controller_set_learn_mode(
                self._zway, <unsigned char> (1 if activate else 0)
            ), "zway controller set learn mode failed", activate
        )

    def controller_set_default(self):
        self.on_error(
            libzway.zway_controller_set_default(
                self._zway
            ), "zway controller set default failed"
        )



























