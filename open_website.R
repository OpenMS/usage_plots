#!/usr/bin/env Rscript

initial.options = commandArgs(trailingOnly=FALSE)
script.basename <- dirname(sub("--file=", "", initial.options[grep("--file=", initial.options)]))

args = commandArgs(trailingOnly=TRUE)

if (length(args) != 2) {
  stop("USAGE ERROR: LOG_FILE GEOLOCATIONS \nNote: For retrieval of those files see READMA.txt") 
}

message("")
message("--- load shiny packges")

if(!require(shiny)) {
        install.packages('shiny', repos = c('http://rforge.net', 'http://cran.rstudio.org'), type = 'source')
        library(shiny)
}


log_file_name=args[1]
geo_loc_file_name=args[2]

message("")
message(paste("--- Source file ", paste(script.basename, '/global.R', sep='')))
source(paste(script.basename, '/global.R', sep=''));

message("")
message(paste("--- Source file ", paste(script.basename, '/worldmap.R', sep='')))
source(paste(script.basename, '/worldmap.R', sep=''));


runApp(app, port = 1234)

