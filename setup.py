from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

setup(
    name = "RaZberry ZWay",
    ext_modules = cythonize([
        Extension(
            "zway", ["zway.pyx"],
            include_dirs=["/opt/z-way-server/libzway-dev"],
            library_dirs=["/opt/z-way-server/libs"],
            libraries=["zway", "pthread", "xml2", "z", "m", "crypto", "archive"]
        )
    ])
)