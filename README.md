# PyZberry Pi

## Python wrapper for RaZberry C API

PyZberry is an attempt to make a wrapper for RaZberry C API for Python programming language.

## Prerequisites

This extension can be complied on Raspberry Pi only after installation of Z-Way libraries and headers. Use the following manual http://razberry.z-wave.me/index.php?id=24.

## Installation

* Install Cython - `sudo pip install cython` or `sudo apt-get install cython`
* Install required dependencies  - `sudo apt-get install python-dev libarchive-dev build-essential`
* Compile and install the extension - `sudo python setup.py install`

## Usage

Import ZWay class from zway module. You can inherit from it in order to override callbacks. Detailed documentation is pending, see pyzberry/zway.pyx comments for now.

If you have a problem with error saying `ImportError: libzway.so: cannot open shared object file: No such file or directory` - execute the following `export LD_LIBRARY_PATH=/opt/z-way-server/libs/:$LD_LIBRARY_PATH` or just copy /opt/z-way-server/libs/libzway.so to /usr/lib directory.

Example application is pending.

## Limitations

Because we use the global variable to store ZWay pointer, you can use this lib in single-threaded applications only. Only 1 instance of ZWay class is possible in one application at the same time. This might (and definitely would) change in a future.