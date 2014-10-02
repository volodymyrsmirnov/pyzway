from libc.stdio cimport fopen
from libc.stdlib cimport free
from src cimport libzway

cdef ZWay zway_global


cdef void c_termination_callback(const libzway.ZWay zway):
    """
    Callback for on_terminate method from ZWay instance

    :param zway: ZWay pointer
    """
    global zway_global
    zway_global.on_terminate()


cdef void c_device_callback(const libzway.ZWay zway, libzway.ZWDeviceChangeType type, libzway.ZWBYTE node_id,
                            libzway.ZWBYTE instance_id, libzway.ZWBYTE command_id, void *arg):
    """
    Callback for on_device method from ZWay instance

    :param zway: ZWay pointer
    :param type: change type
    :param node_id: node id
    :param instance_id: instance id
    :param command_id: command id
    :param arg: callback arguments pointer
    """
    global zway_global
    zway_global.on_device(type, node_id, instance_id, command_id)


cdef class ZWay:
    cdef libzway.ZWay _zway


    def on_terminate(self):
        """
        Callback to execute on termination
        Can be overridden in child classes to handle the action
        """
        pass


    def on_device(self, type, node_id, instance_id, command_id):
        """
        Callback to execute on device change action
        See c_device_callback for params references
        Can be overridden in child classes to handle the action
        """
        pass


    def __cinit__ (self, bytes port, bytes config_folder, bytes translations_folder, bytes zddx_folder,
                   bytes log, int level = 0):
        """
        Allocate and initialize a ZWay object

        :param port: TTY port, usually is is /dev/ttyAMA0
        :param config_folder: folder to store configs
        :param translations_folder: folder to store translations
        :param log: path to the log file
        :param level: logging level, from 0 to 7 where 7 is silent log
        """
        global zway_global
        zway_global = self

        errno =  libzway.zway_init(
            &self._zway, port, config_folder, translations_folder, zddx_folder,
            fopen(<char *> log, "wb") if log else NULL, level
        )

        if errno != 0:
            raise EnvironmentError((errno, "zway library init error"))


    def terminate(self):
        """
        Save state, close all handles and deallocate a ZWay object
        """
        libzway.zway_terminate(&self._zway)


    def set_log(self, bytes log, int level):
        """
        Assigns a log file and logging level to a ZWay instance

        :param log: path to the log file
        :param level: logging level, from 0 to 7 where 7 is silent log
        """
        return libzway.zway_set_log(self._zway, fopen(<char *> log, "wb") if log else NULL, level)


    def start(self):
        """
        Start worker thread and open port
        """
        return libzway.zway_start(self._zway, c_termination_callback)


    def stop(self):
        """ Stop processing of commands and terminate worker thread """
        return libzway.zway_stop(self._zway)


    def discover(self):
        """ Discover Home ID, get network topology, version, capabilities etc. """
        return libzway.zway_discover(self._zway)


    def is_idle(self):
        """ Check if queue is empty (or has only jobs in state 'Done') """
        return libzway.zway_is_idle(self._zway) != 0


    def is_running(self):
        """ Check that Z-Way is still running (Z-Way working thread still works) """
        return libzway.zway_is_running(self._zway) != 0


    def device_send_nop(self, node_id):
        """
        Send NoOperation to a node and wake up it's queue

        :param node_id: node id
        """
        return libzway.zway_device_send_nop(self._zway, node_id)


    def device_load_xml(self, node_id, bytes file_name):
        """
        Loads Device Description XML file for specified device

        :param node_id: node id
        :param file_name: XML file name
        """
        return libzway.zway_device_load_xml(self._zway, node_id, file_name)


    def device_guess(self, node_id):
        """
        Returns a list of ZDDX files with match score for the desired devices.

        :param node_id: node id
        """
        results = []

        cdef libzway.ZGuessedProduct* products = libzway.zway_device_guess(self._zway, node_id)
        cdef libzway.ZGuessedProduct product = NULL

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

        libzway.zway_device_guess_free(products)

        return results


    def device_awake_queue(self, node_id):
        """
        Force queue wake-up for a device

        :param node_id: node id
        """
        libzway.zway_device_awake_queue(self._zway, node_id)


    def device_add_callback(self, mask):
        """
        Attach callback function from Device change event

        :param mask: bitmask for events

        Values for mask:
        DeviceAdded = 0x01,
        DeviceRemoved = 0x02,
        InstanceAdded = 0x04,
        InstanceRemoved = 0x08,
        CommandAdded = 0x10,
        CommandRemoved = 0x20,
        ZDDXSaved = 0x100
        """
        return libzway.zway_device_add_callback(self._zway, mask, c_device_callback, NULL)


    def device_remove_callback(self):
        """
        Detach callback function from Device change event
        """
        return libzway.zway_device_remove_callback(self._zway, c_device_callback)


    def command_interview(self, device_id, instance_id, cc_id):
        """
        Run Command Class Interview

        :param device_id: device id
        :param instance_id: instance id
        :param cc_id: command class id
        """
        return libzway.zway_command_interview(self._zway, device_id, instance_id, cc_id)


    def device_interview_force(self, device_id):
        """
        Force re-interview of the device

        :param device_id: device id
        """
        return libzway.zway_device_interview_force(self._zway, device_id)


    def device_is_interview_done(self, device_id):
        """
        Check if device interview is done

        :param device_id: device id
        """
        return libzway.zway_device_is_interview_done(self._zway, device_id) != 0


    def device_assign_return_route(self, device_id, node_id):
        """
        Assigns return route to a device

        :param device_id:
        :param node_id:
        :return:
        """
        return libzway.zway_device_assign_return_route(self._zway, device_id, node_id)


    def device_delete_return_route(self, device_id):
        """
        Deletes ALL return route in device

        :param device_id: device id
        """
        return libzway.zway_device_delete_return_route(self._zway, device_id)


    def device_assign_suc_return_route(self, device_id):
        """
        Assigns SUC return route to a device

        :param device_id: device id
        """
        return libzway.zway_device_assign_suc_return_route(self._zway, device_id)


    def device_delete_suc_return_route(self, device_id):
        """
        Deletes SUC return route in device

        :param device_id: device id
        """
        return libzway.zway_device_delete_suc_return_route(self._zway, device_id)


    def controller_set_suc_node_id(self, node_id):
        """
        Set Static Update Controller (SUC) in the network and inform other devices about the assignment.

        :param node_id: node id
        """
        return libzway.zway_controller_set_suc_node_id(self._zway, node_id)


    def controller_set_sis_node_id(self, node_id):
        """
        Set SUC ID Server (SIS) in the network and inform other devices about the assignment.

        :param node_id: node id
        """
        return libzway.zway_controller_set_sis_node_id(self._zway, node_id)


    def controller_disable_suc_node_id(self, node_id):
        """
        Disable SUC/SIS in the network and inform other devices about the assignment.

        :param node_id: node id
        """
        return libzway.zway_controller_disable_suc_node_id(self._zway, node_id)


    def controller_change(self, state):
        """
        Set new primary controller (also known as Controller Shift)
        Same as Inclusion, but the newly included device will get the role of primary.

        :param state: disable if 0 else enable
        """
        return libzway.zway_controller_change(self._zway, state)


    def controller_add_node_to_network(self, state):
        """
        Start/stop inclusion of a new node

        :param state: disable if 0 else enable
        """
        return libzway.zway_controller_add_node_to_network(self._zway, state)


    def controller_remove_node_from_network(self, state):
        """
        Start/stop exclusion of a node

        :param state: disable if 0 else enable
        """
        return libzway.zway_controller_remove_node_from_network(self._zway, state)


    def controller_set_learn_mode(self, state):
        """
        Set/stop Learn mode

        :param state: disable if 0 else enable:
        """
        return libzway.zway_controller_set_learn_mode(self._zway, state)


    def controller_set_default(self):
        """
        Reset the controller
        """
        return libzway.zway_controller_set_default(self._zway)


    def controller_config_save(self, file_name):
        """
        Saves controller configuration, defaults and other needed files as tgz archive

        :param file_name: file name to save config
        """
        cdef size_t data_length = 0
        cdef libzway.ZWBYTE *data = NULL

        errno = libzway.zway_controller_config_save(self._zway, &data, &data_length)

        if errno == 0 and data != NULL:
            bytes_string = data[:data_length]

            with open(file_name, "wb") as config_file:
                config_file.write(bytes_string)

            free(data)

        return errno


    def config_restore(self, file_name, full):
        """
        Restores controller configuration, defaults and other needed files from tgz archive

        :param file_name: file name to restore from
        :param full: 1 if full else 0
        """
        bytes_string = ""

        with open(file_name, "wb") as config_file:
            bytes_string = config_file.readall()

        return libzway.zway_controller_config_restore(self._zway, bytes_string, len(bytes_string), full)


    def zddx_save_to_xml(self):
        """
        Save all Z-Way data to the disc
        """
        return libzway.zddx_save_to_xml(self._zway)


    def devices_list(self):
        """
        Returns list of registered devices Node Id
        """
        results = []

        cdef libzway.ZWDevicesList devices = libzway.zway_devices_list(self._zway)
        cdef libzway.ZWBYTE node_id = 0

        i = 0

        while True:
            node_id = devices[i]

            if node_id == 0:
                break

            results.append(node_id)

            i += 1

        libzway.zway_devices_list_free(devices)

        return results


    def instances_list(self, device_id):
        """
        Returns list of registered instances Id for specified device

        :param device_id: device id
        """
        results = []

        cdef libzway.ZWInstancesList instances = libzway.zway_instances_list(self._zway, device_id)
        cdef libzway.ZWBYTE instance_id = 0

        i = 0

        while True:
            instance_id = instances[i]

            if instance_id == 0:
                break

            results.append(instance_id)

            i += 1

        libzway.zway_instances_list_free(instances)

        return results


    def command_classes_list(self, device_id, instance_id):
        """
        Returns list of registered Command Classes Id for specified instance of device

        :param device_id: device id
        :param instance_id: instance id
        """
        results = []

        cdef libzway.ZWCommandClassesList c_classes = libzway.zway_command_classes_list(self._zway, device_id,
                                                                                        instance_id)
        cdef libzway.ZWBYTE c_class = 0

        i = 0

        while True:
            c_class = c_classes[i]

            if c_class == 0:
                break

            results.append(c_class)

            i += 1

        libzway.zway_command_classes_list_free(c_classes)

        return results


    def command_is_supported(self, node_id, instance_id, command_id):
        """
        Returns if command class both exists for specified instance of device, and is rendered as supported

        :param node_id: device id
        :param instance_id: instance id
        :param command_id: command id
        """
        return libzway.zway_command_is_supported(self._zway, node_id, instance_id, command_id) != 0































