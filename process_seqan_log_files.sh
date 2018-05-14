#!/bin/bash

set -e

EXEC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $# -ne 1 ]; then
    echo "[USER ERROR] provide file name of zipped log files."
    exit 1
fi

ZIP_FILE=$1
RAW_DATA_FILE="all.log.raw"
DATA_FILE="all.log"
IP_FILE="ips.txt"
GEO_FILE="geolocations.csv"

# unzip file into all.log
echo "--- Unzipping file and parsing into text file."
unzip -p $ZIP_FILE | cat > $RAW_DATA_FILE 
echo "--- $(wc -l $RAW_DATA_FILE) lines to process."

# filter out valuable information
# ouput file will have the following structre:
# date(year-mon-d) ip seqan os cpu appname version
echo "--- Start Formatting of the log files into a table format"
echo -e "calls\tdate\tip\tapp\tversion\tcpu\tos\twho\tclustered" > $DATA_FILE
gawk '!/test_version_check/ && !/134.2.9.116/ && !/160.45.111.134/ && !/160.45.111.149/ && !/160.45.111.150/ && !/160.45.112.24/ && !/160.45.43.61/' $RAW_DATA_FILE | \
	sed -rn 's;(^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\s.*\[([0-9]+)/([a-zA-Z]+)/([0-9]+)\:[0-9]+\:[0-9]+\:[0-9]+.*\] \"GET /check/([a-zA-Z]+)_([a-zA-Z]+)_([0-9]+)_([a-zA-Z0-9_]+)_([0-9]+\.[0-9]+\.[0-9]+).*;\4-\3-\2\t\1\t\8\t\9\t\7\t\6\t\5;p' | \
	sort | \
	uniq | \
	sed 's/\(.*\)/1\t\1/' | \
	gawk ' BEGIN {OFS="\t"} {
		split($3,IP,".",seps);
		if ($2==PREV_DATE && $4==PREV_APP && $5==PREV_VERSION && IP[1]==PREV_IP[1] && IP[2]==PREV_IP[2])
			print $0,1;
		else
			print $0,0;
		PREV_DATE=$2;
		PREV_APP=$4;
		PREV_VERSION=$5;
		split($3,PREV_IP,".",seps);
      		}'  >> $DATA_FILE


# get geolocation geolocation
head -n -1 | cut -f 3 $DATA_FILE | sort | uniq > $IP_FILE

ips_to_locate=$(wc -l $IP_FILE)
echo "--- Getting Geo location from www.freegeoip.net for $ips_to_locate uniq ip adresses."
echo "ip,country_code,country,state_code,state,city,zipcode,area,latitude,longitude,metro_code" > $GEO_FILE
COUNT=1
for ip_add in $(cat $IP_FILE)
do
	echo -ne "$COUNT of $ips_to_locate\r"
	curl -s https://www.freegeoip.net/csv/$ip_add >> $GEO_FILE
	COUNT=$((COUNT+1))
done

echo "--- Done."

