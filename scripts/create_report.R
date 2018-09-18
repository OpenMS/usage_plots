#!/usr/bin/env Rscript

initial.options = commandArgs(trailingOnly=FALSE)
script.basename <- dirname(sub("--file=", "", initial.options[grep("--file=", initial.options)]))

args = commandArgs(trailingOnly=TRUE)

if (length(args) != 4) {
  stop("USAGE ERROR - please provide the following: all.log geolocations.csv report.md OUT_DIR\nNote: You obtain the log file and geolocations file by executing ./process_[seqan/openms]_log_files.sh on the concatenated raw log file. If you encounter any problems write a mail to svenja.mehringer@fu-berlin.de", call.=FALSE)
}

output_dir=args[4]

if (!(output_dir[1] == "/")) # relative path
{
	output_dir = paste(getwd(), output_dir, sep = "/")
}

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

output_filename=paste(output_dir, "report.html", sep = "/")

if (file.exists(output_filename))
{
    stop(paste("[ERROR] Output file ", output_filename, "already exists."))
}

local.lib <- "/tmp/R-lib/"
dir.create(local.lib, showWarnings = FALSE, recursive = TRUE)
.libPaths( c( .libPaths(), local.lib) )

message("=============================================================================")
message("                                 START")
message("=============================================================================")

message("")
message("--- load neccessary packages")

if(!require(knitr)) {
	install.packages('knitr', repos = c('http://rforge.net', 'http://cran.rstudio.org'), type = 'source', lib=local.lib)
	library(knitr, lib.loc=local.lib)
}

if(!require(rmarkdown)) {
	install.packages('rmarkdown', repos = c('http://rforge.net', 'http://cran.rstudio.org'), type = 'source', lib=local.lib)
    	library(rmarkdown, lib.loc=local.lib);
}

if(!require(sp)) {
        install.packages('sp', repos = c('http://rforge.net', 'http://cran.rstudio.org'), type = 'source', lib=local.lib)
        library(sp, lib.loc=local.lib);
}

if(!require(leaflet)) {
	install.packages("leaflet", repos = c('http://rforge.net', 'http://cran.rstudio.org'), type = 'source', lib=local.lib) 
	library(leaflet, lib.loc=local.lib)
}

if(!require(lattice)) {
	install.packages("lattice", repos = c('http://rforge.net', 'http://cran.rstudio.org'), type = 'source', lib=local.lib) 
	library(lattice, lib.loc=local.lib)
}

if(!require(rworldmap)) {
	install.packages("rworldmap", repos = c('http://rforge.net', 'http://cran.rstudio.org'), type = 'source', lib=local.lib) 
	library(rworldmap, lib.loc=local.lib)
}

if(!require(RColorBrewer)) {
	install.packages("RColorBrewer", repos = c('http://rforge.net', 'http://cran.rstudio.org'), type = 'source', lib=local.lib) 
	library(RColorBrewer, lib.loc=local.lib)
}

if(!require(yaml)) {
        install.packages("yaml", repos = c('http://rforge.net', 'http://cran.rstudio.org'), type = 'source', lib=local.lib)
        library(yaml, lib.loc=local.lib)
}

#if(!require(mapview)) {
#        install.packages("mapview", repos = c('http://rforge.net', 'http://cran.rstudio.org'), type = 'source', lib=local.lib)
#        library(mapview, lib.loc=local.lib)
#}


log_file_name=paste(getwd(), args[1], sep="/");
geo_loc_file_name=paste(getwd(), args[2], sep="/");
report_file_name=paste(getwd(), args[3], sep="/");

message("")
message(paste("--- Source file ", paste(script.basename, '/global.R', sep='')))
source(paste(script.basename, '/global.R', sep=''));

message("")
message(paste("--- Render file ", args[3]))
rmarkdown::render(report_file_name)

if (file.copy(report_file_name, output_filename))
{
    message("=============================================================================")
    message(paste("SUCCESS: output file", output_filename, "generated"))
    message("=============================================================================")
    file.remove(paste(script.basename, "report.html", sep="/"))
} else {
    message("=============================================================================")
    message(paste("FAILURE: could not generate output file", output_filename))
    message("=============================================================================")
}
