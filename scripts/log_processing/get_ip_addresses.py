#!/usr/bin/env python3

import os
import sys
import re
import IP2Location

# Import database
database = IP2Location.IP2Location(sys.argv[3])

with open(sys.argv[2], "w") as geo_locations_file:
    ip_pattern = re.compile(r"^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")
    sep = "\t"

    # ---------------------------------------- process ips ---------------------------------------------
    # write header line
    geo_locations_file.write(f"ip{sep}country_code{sep}country{sep}region{sep}city{sep}longitude{sep}latitude\n")

    # fill rest of geolocations file
    with open(sys.argv[1], "r") as ip_file:
        for number, line in enumerate(ip_file):
            ip = line.strip()

            # validate ip address
            if not (re.search(ip_pattern, ip)):
                print(f"--- [get_ip_adress.py] Warning: Skipping non-valid ip adress on line {number}: {ip}")
                continue

            geo_locations_file.write(f"{ip}{sep}") # write before database access for debug information

            rec = database.get_all(ip)

            # write all data base information
            geo_locations_file.write(
                f"{rec.country_short}{sep}{rec.country_long}{sep}{rec.region}{sep}"
                f"{rec.city}{sep}{str(rec.longitude)}{sep}{str(rec.latitude)}\n"
            )
