# How to generate user statistics
# ===============================

# 1) Get log files
# ----------------
# The original server calls are stored in Tuebingen.
# Ask someone in Tuebingen to send you a zipped file or get access to the server yourself

# 2) Prepare log files
# --------------------
# The log files are originally not in a nice format to process.
# Therefore, you need to use the script process_seqan_log_files.sh or process_openms_log_files.sh or first.

/path/to/script/process_seqan_log_files.sh seqan-all.log

# Now the directory should have a file all.log and a file geolocations.csv
# Those are the files you need for generating a plots and stuff

# 3) Generate the user statistics report pdf
# To generate the pdf file execute the R script create_report.R and supply the according files.
# Note: you will also get a new directory in your current path with all the single figures.

/path/to/script/create_report.R all.log geolocations.csv report.pdf

# Note: The database file for ip geo locations was obtained from : https://lite.ip2location.com
# The pyhton code to access the database binary was obtained from: https://github.com/chrislim2888/IP2Location-Python
