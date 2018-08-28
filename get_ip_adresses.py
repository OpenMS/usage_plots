import os
import sys
import re

sys.path.insert(0, './IP2Location-Python/') # add submodule package locally

import IP2Location

# Import database
database = IP2Location.IP2Location(sys.argv[3])

# open files
ips_file = open(sys.argv[1], "r")
geo_locations_file = open(sys.argv[2], "w")

# Global variables
ip_pattern = re.compile("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")

ouput_file_seperator="\t"

# ---------------------------------------- process ips --------------------------------------------- 
# write header line
geo_locations_file.write("ip")
geo_locations_file.write(ouput_file_seperator)
geo_locations_file.write("country_code")
geo_locations_file.write(ouput_file_seperator)
geo_locations_file.write("country")
geo_locations_file.write(ouput_file_seperator)
geo_locations_file.write("region")
geo_locations_file.write(ouput_file_seperator)
geo_locations_file.write("city")
geo_locations_file.write(ouput_file_seperator)
geo_locations_file.write("longitude")
geo_locations_file.write(ouput_file_seperator)
geo_locations_file.write("latitude")
geo_locations_file.write("\n")

# fill rest of geolocations file
for ip in ips_file:
	# test if ip is a valid string to avoid errors
	if not (re.search(ip_pattern, ip.strip())):
		print "get_ip_adress.py # Error: Skipping non-valid ip adress:",ip.strip()
		continue

	geo_locations_file.write(ip.strip()) # write before database access for debug information
        
	rec = database.get_all(ip.strip())
	
	# write all data base information
	geo_locations_file.write(ouput_file_seperator)
        geo_locations_file.write(rec.country_short)
	geo_locations_file.write(ouput_file_seperator)
        geo_locations_file.write(rec.country_long)
        geo_locations_file.write(ouput_file_seperator)
	geo_locations_file.write(rec.region)
	geo_locations_file.write(ouput_file_seperator)
        geo_locations_file.write(rec.city)
	geo_locations_file.write(ouput_file_seperator)
        geo_locations_file.write(str(rec.longitude))
	geo_locations_file.write(ouput_file_seperator)
        geo_locations_file.write(str(rec.latitude))
	geo_locations_file.write("\n")

ips_file.close()
geo_locations_file.close()

print "get_ip_adress.py # Done."
