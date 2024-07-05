Usage Statistics of OpenMS and SeqAn
====================================

This repo contains scripts, data and other files, that are helpful for acquiring and analysing the usage statistics for OpenMS and SeqAn.

A cron job which triggers the analysis of log files is set up on [Jenkins](https://abibuilder.cs.uni-tuebingen.de/jenkins/job/usage_statistics/job/usageStatistics/).

:exclamation:**Important**:exclamation:: The top level `seqan_versions.txt` and `openms_versions.txt` must not be moved to a different location because it is needed to ensure a correct server response to a user call. The Tübingen REST server pulls both file once per night, so if a version changes, they can be directly updated in this repository.

How the scripts are used
------------------------

1. Get log files:
   The original server calls are stored in Tuebingen.
   Ask someone in Tuebingen to send you a zipped file or get access to the server yourself.

2. Prepare log files:
   The log files are originally not in a nice format to process.
   You need to use the script `process_seqan_log_files.sh` or `process_openms_log_files.sh` first.
   ```
   $ /path/to/script/process_seqan_log_files.sh seqan-all.log
   ```
   Now the directory should have a file `all.log` and a file `geolocations.csv`
   Those are the files you need for generating a plots and stuff

3. Generate the user statistics report pdf:
   To generate the pdf file execute the R script `create_report.R` and supply the according files.
   Note: you will also get a new directory in your current path with all the single figures.
   ```
   $ /path/to/script/create_report.R all.log geolocations.csv report.pdf
   ```
   Note: The database file for ip geo locations was obtained from : https://lite.ip2location.com.
   The pyhton code to access the database binary was obtained from: https://github.com/chrislim2888/IP2Location-Python
