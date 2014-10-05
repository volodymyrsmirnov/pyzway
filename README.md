# PyZWay

## Python wrapper for Z-Way C API

PyZWay is a one-to-one Z-Way C API to Python wrapper written on Cython. 

The goal was to archive the semi-automatic conversion process with Cython definition and logic file generation from Z-Way library header. See preprocessor.py and setup.py source code.

**Important**, the library is not even in beta state, but somewhere in between alpha and PoC versions. Do not use in production environments since library have not yet been fully tested.

The library been developed and tested on Python 2.7 version. Python 3 support to be announced later.

## Prerequisites

This extension can be complied on any supported Linux platform after the installation of Z-Way libraries and headers. 

Use the following manual for Raspberry Pi: http://razberry.z-wave.me/index.php?id=24

## Installation

* Clone the repository and navigate to its folder.
* Install Cython - `sudo pip install cython`. Tested on version 0.20.1, but should work for >= 0.18. The one from Debian Wheezy / Raspbian apt (0.15) is not supported. 
* Install required build dependencies  - `sudo apt-get install python-dev libarchive-dev build-essential`
* If Z-Way library is installed in directory different from */opt/z-way-server*, you can define the path to headers and libraries path by assigning the following environment variables: ZWAY_INC_PATH, ZWAY_LIB_PATH.
* Compile and install the extension - `sudo python setup.py clean prepare build_ext -i`. This will generate zway.so file in the current directory. You can move it to your application and import from it. Yuo can use *install* switch to move the zway.so into your site-packages directory of python or virtualenv installation, but we don't recommend it for now.

## Usage

Import from zway classes ZWay and ZWayData.

If you have a problem with error saying `ImportError: libzway.so: cannot open shared object file: No such file or directory` - execute the following `export LD_LIBRARY_PATH=/opt/z-way-server/libs/:$LD_LIBRARY_PATH` or just run `sudo ln -s /opt/z-way-server/libs/libzway.so /usr/lib/libzway.so`.


## General API description

ZWay class wraps all methods from ZWayLib.h, CommandClassesPublic.h and FunctionClassesPublic.h.

We use the following naming rule: if function has name "zway_cc_time_time_get" in header file, then in ZWay class it is cc_time_time_get method of instance.

Mostly all methods except for the ones which return data or execute a void function return the numeric errno.

For parameters we convert all camel-case name to underscore-style. I.e. powerLevelValue becomes power_level_value.

You can inherit from ZWay class in order to override 2 callbacks: 

```
def on_device(self, type, node_id, instance_id, command_id)
type, node_id, instance_id, command_id - int or None if not defined

def on_job(self, success, function_id)
success - bool
function_id - int
```

on_device callback is executed on device actions if enabled with device_add_callback(mask) ZWay instance method.
 
on_job callback is executed automatically for every cc_ and fc_ commands.
 
### Caveats

Even though we tried to follow one-to-one conversion rules, there are some peculiarities of PyZWay API.
 
#### ZWayLib.h

* zway_init is executed in instance constructor, all arguments are mandatory, but log argument is not a file instance, but a string with file path where the log will be written.
* start does not have a termination callback argument.
* set_log accepts same log argument as instance constructor described above.
* device_add_callback does not have a callback arguments, it enabled on_device callback execution instead.
* device_remove_callback does not have a callback arguments, it disables on_device callback execution instead.
* device_guess returns the list of dict with following keys: score, vendor, product, image_url, file_name.
* controller_config_save and config_restore accepts file_name argument with config file path instead of data buffer.
* devices_list, instances_list and command_classes_list return the list of int.
* zway_device_add_callback_ex, zway_device_remove_callback_ex are not supported. 
* all _free functions are implemented in required getters and are not available as instance methods.

#### CommandClassesPublic.h

* zway_cc_firmware_update_perform accepts bytes in data parameter and does not need length argument.

#### FunctionClassesPublic.h

No caveats.

## Data Model

Data model is implemented in ZWayData class. Yuu can use 2 static methods for getting the data:

* ZWayData.find_controller_data(ZWay controller, bytes path) to get the controller specific data.
* ZWayData.find_device_data(ZWay controller, bytes path, device, instance=None, command_class=None) to get the device specific data. 

In second case you can specify device, instance and command_class to get results of zway_find_device_instance_cc_data call, device and instance to get results from zway_find_device_instance_data or just device to get results from zway_find_device_data.

Use empty string in path to get the root object.

For wrong queries (the ones that return NULL) the KeyError exception will be thrown.

ZWayData has the following callback executed when data in holder been changed and the callback been enabled with appropriate instance method:

```
def on_data_change(self, change_type)
change_type - int
```

ZWayData instance has the following properties and methods:

* is_empty - bool, returns True if ZWayData holds an empty data.
* type - int, returns the numeric data type identifier.
* path - str, returns the string path to the data.
* name - str, returns the name of the data.
* update_time - datetime, returns the time of last data update.
* invalidate_time - datetime, returns the time when the data will be invalidated.
* value - object, actual type depends on the actual data type in underlying data holder.
* children - the list of children ZWayData instances. 
* set(value, is_binary=False) - set the value of data, is you pass bytes in value and is_binary is false - we set data as strings, if is_binary is true - we set the binary data in holder.
* invalidate(children=True) - invalidate instance and its children if children set to True.
* add_callback(watch_children=True) - enable on_data_change callback for data change.
* remove_callback() - disable on_data_change callback for data change.
* find_data(path) - find a child data in current ZWayData, returns new ZWayData instance.
* remove_child(self, ZWayData child) - remove a child data from current (parent) instance.

ZWayData supports basic dict() style operations. Example:

```
data = ZWayData.find_device_data(zway_instance, "") # returns the root controller info
software_revision = data["softwareRevisionVersion"] # get the software revision data from root controller info
print software_revision.value                       # outputs v1.7.2
```

