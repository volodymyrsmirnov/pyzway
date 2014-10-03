"""
 Copyright (C) 2014, Vladimir Smirnov (vladimir@smirnov.im)

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the license for more details.
"""

from distutils.core import setup
from distutils.extension import Extension
from distutils.command.clean import clean
from Cython.Distutils import build_ext
from Cython.Build import cythonize

import os
from prerpocessor import *

INCLUDE_DIRECTORY = os.environ.get("ZWAY_INC_PATH", "/opt/z-way-server/libzway-dev")
LIBRARY_DIRECTORY = os.environ.get("ZWAY_LIB_PATH", "/opt/z-way-server/libs")

TEMPLATES = (
    ("template_libzway.pxd", "libzway.pxd"),
    ("template_zway.pyx", "zway.pyx")
)


class PyzberryCleaner(clean):
    def run(self):
        for template, output in TEMPLATES:
            if os.path.isfile(output):
                os.remove(output)

        clean.run(self)


class PyzberryPreprocessor(build_ext):
    def run(self):
        for template, output in TEMPLATES:
            with open(template, "r") as template_file:
                template_file_content = template_file.read()

                for line in template_file_content.splitlines():
                    if line.startswith("#GENPXD:") or line.startswith("#GENPYX:"):
                        parts = line.split(":")
                        method = parts[0]
                        filename = parts[1]
                        ignore = parts[2].split(",")

                        if method == "#GENPXD":
                            content = generate_pxd(
                                parse_definition_file(os.path.join(INCLUDE_DIRECTORY, filename), ignore))
                        else:
                            content = generate_pyx(
                                parse_definition_file(os.path.join(INCLUDE_DIRECTORY, filename), ignore))

                        with open(output, "w") as output_file:
                            template_file_content = template_file_content.replace(line, content)
                            output_file.write(template_file_content)

        build_ext.run(self)

setup(
    name="PyZWay",
    version="0.0.2",
    description="Cython wrapper for PyZWay C API",
    author="Vladimir Smirnov",
    author_email="vladimir@smirnov.im",
    url="https://github.com/mindcollapse/razberry-python",
    license="BSD",
    cmdclass={
        "build_ext": PyzberryPreprocessor,
        "clean": PyzberryCleaner
    },
    ext_modules=[
        Extension(
            "zway", ["zway.pyx"],
            include_dirs=[INCLUDE_DIRECTORY],
            library_dirs=[LIBRARY_DIRECTORY],
            libraries=["zway", "pthread", "xml2", "z", "m", "crypto", "archive"]
        )
    ]
)