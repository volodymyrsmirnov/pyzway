# PyZWay

## Python wrapper for Z-Way C API

PyZWay is an attempt to make a wrapper for Z-Way C API for Python programming language.

## Prerequisites

This extension can be complied on any linux platform only after installation of Z-Way libraries and headers. 

Use the following manual for Raspberry Pi http://razberry.z-wave.me/index.php?id=24.

## Installation

* Install Cython - `sudo pip install cython`, tested on version 0.20.1, the one provided in apt (0.15) wouldn't work.
* Install required dependencies  - `sudo apt-get install python-dev libarchive-dev build-essential`
* Compile and install the extension - `sudo python setup.py prepare build_ext install`

## Usage

Import ZWay class from zway module. You can inherit from it in order to override callbacks.

If you have a problem with error saying `ImportError: libzway.so: cannot open shared object file: No such file or directory` - execute the following `export LD_LIBRARY_PATH=/opt/z-way-server/libs/:$LD_LIBRARY_PATH` or just copy /opt/z-way-server/libs/libzway.so to /usr/lib directory.

Example application is pending.