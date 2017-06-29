#!/bin/bash

if [ $# -ne 1 ]; then
    echo [USER ERROR] need FILE_NAME as second argument
    exit 1
fi

FILE=$1

# filter out valuable information
# ouput file will have the following structre:
# date(year-mon-d) ip seqan os cpu appname version
sed -rn 's;(^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\s.*\[([0-9]+)/([a-zA-Z]+)/([0-9]+)\:[0-9]+\:[0-9]+\:[0-9]+.*\] \"GET /check/([a-zA-Z]+_[a-zA-Z]+)_([a-zA-Z]+)_([0-9]+)_([a-zA-Z0-9_]+)_([0-9]+\.[0-9]+\.[0-9]+).*;\4-\3-\2\t\1\t\8\t\9\t\7\t\6\t\5;p' $FILE | \
sort | \
uniq | \
sed 's/\(.*\)/1\t\1/' |
gawk '{
		split($3,IP,".",seps);
		if ($2==PREV_DATE && $4==PREV_APP && $5==PREV_VERSION && IP[1]==PREV_IP[1] && IP[2]==PREV_IP[2])
			print $0,"\t",1;
		else
			print $0,"\t",0;
		PREV_DATE=$2;
		PREV_APP=$4;
		PREV_VERSION=$5;
		split($3,PREV_IP,".",seps); 
      }' > $FILE.tmp
#sed -e 's/ *//' -e 's/ /\t/' > "$FILE.prepared"

# count ips
TOTAL=$(wc -l $FILE.tmp)

# append geolocation
python prepareLog.py $FILE.tmp $FILE.prepped.txt $TOTAL

# remove temporary file
rm $FILE.tmp

