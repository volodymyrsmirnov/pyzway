"""
 Copyright (C) 2014, Vladimir Smirnov (vladimir@smirnov.im)

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the license for more details.
"""

import re

def parse_definition_file(file_name, ignore=list()):
    function_re = re.compile(r"^(?P<export>\w+)\s+(?P<return>\w+)\s+(?P<name>\w+)\((?P<arguments>.*)\);")

    with open(file_name, "r") as def_file:
        lines = def_file.readlines()

    result = []

    for line in lines:
        match_result = function_re.search(line)

        if match_result == None:
            continue

        match_result = match_result.groupdict()

        if match_result["name"] in ignore:
            continue

        function = {
            "return": match_result["return"],
            "name": match_result["name"],
            "arguments": []
        }

        for argument in match_result["arguments"].split(","):
            argument_parts = argument.strip().split()
            function["arguments"].append((
                " ".join(argument_parts[0:-1]), argument_parts[-1]
            ))

        result.append(function)

    return result

def generate_pxd(parsing_result, prepend="    ", append="\n\n"):
    result = ""

    for function in parsing_result:
        result += prepend
        result += "{0} {1}({2})".format (
            function["return"],
            function["name"],
            ", ".join(" ".join(argument) for argument in function["arguments"])
        )

        if function != parsing_result[-1]:
            result += append

    return result


def generate_pyx(parsing_result, prepend="    ", append="\n\n"):
    result = ""

    for function in parsing_result:
        result += prepend
        result += "def {0}(".format(function["name"].replace("zway_", ""))

        has_job_callbacks = False

        def_arguments = ["self"]

        for argument_type, argument_name in function["arguments"]:
            if argument_type == "ZJobCustomCallback":
                has_job_callbacks = True

            if argument_type in ["ZWay", "const ZWay", "ZJobCustomCallback", "void*", "size_t"]:
                continue

            argument_name = argument_name.replace("*", "")

            def_arguments.append(argument_name)

        result += ", ".join(def_arguments) + "):\n"
        result += prepend * 2

        if function["return"] != "void":
            result += "return "

        result += "zw.{0}(self._zway".format(function["name"])

        if len(def_arguments[1:]):
            result += ", " + ", ".join(def_arguments[1:])

        if has_job_callbacks:
            result += ", c_job_success_callback, c_job_failure_callback, <void *> self"

        result += ")"

        if function["return"] == "ZWBOOL":
            result += " != 0"

        if function != parsing_result[-1]:
            result += append

    return result