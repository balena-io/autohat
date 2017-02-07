
# ##################################################################################################
#
# Script that searches for a template inside a system log file
# NOTE: Templates need to have the "old_app_name" and "new_app_name" groups defined in template file
#
# ##################################################################################################

import sys
import logging
import re

if __name__ == '__main__':

    logging.basicConfig(level=logging.DEBUG)

    if len(sys.argv) < 2:
        logging.error("Expected 2 arguments - the two files that are to be read.")
        logging.error("Usage: python %s <template_file> <input_file>" % sys.argv[0])
        sys.exit(100)

    template_file = sys.argv[1]
    file_to_compare = sys.argv[2]

    with open(template_file, "r") as fd:
        lines = fd.readlines()
    template = "".join([x.rstrip("\n") for x in lines])

    pattern = re.compile(template, re.IGNORECASE)

    with open(file_to_compare, "r") as fd:
        to_compare = fd.read()

    matches = pattern.search(to_compare, re.IGNORECASE)
    if matches is None:
        logging.info("Files are different!")
        sys.exit(1)

    new_app_name = matches.group("new_app_name")
    old_app_name = matches.group("old_app_name")

    if new_app_name == old_app_name:
        logging.info("Old app was reinstalled")
        sys.exit(2)

    logging.info("Pattern found in %s" % file_to_compare)
