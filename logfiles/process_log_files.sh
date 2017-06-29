#!/bin/bash

# This little bash file (re-)processes all log files
# that are found in the directory given as a commandline argument
if [ $# -ne 2 ]; then
    echo '[USER ERROR] Please provide the directory (path) that contains log files you want to process and the output name'
    exit 1
fi

CURRENT_DIR=$(pwd)
LOG_DIR=$1
OUTFILE=$2

# go to directory
cd $LOG_DIR

# First, delete all former prepped files
rm *.log.*.prepped.txt
 
# Now process all log files
for file in $(find . -name "*.log*"); do ./process.sh $file; done

cd $CURRENT_DIR

# concatenate all log files
cat $LOG_DIR/*.log.*.prepped.txt > $OUTFILE.logs
