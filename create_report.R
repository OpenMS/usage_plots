#!/usr/bin/env Rscript

initial.options = commandArgs(trailingOnly=FALSE)
script.basename <- dirname(sub("--file=", "", initial.options[grep("--file=", initial.options)]))

args = commandArgs(trailingOnly=TRUE)

if (length(args) != 3) {
  stop("USAGE ERROR: LOG_FILE GEOLOCATIONS OUT_FILE.pdf\nNote: You obtain the log file and geolocations file by executing ./process_seqan/openms.sh in the directory of the original log files.If you encounter any problems write a mail to svenja.mehringer@fu-berlin.de", call.=FALSE)
}

output_filename=args[3]
output_figure_dir=paste(getwd(), "/", sub("^([^.]*).*", "\\1", basename(output_filename)), "_figures", sep='')

if (file.exists(output_filename))
{
    stop(paste("[ERROR] Output file ", output_filename, "already exists."))
}

dir.create(output_figure_dir, showWarnings = FALSE, recursive = TRUE)
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

#if(!require(mapview)) {
#        install.packages("mapview", repos = c('http://rforge.net', 'http://cran.rstudio.org'), type = 'source', lib=local.lib)
#        library(mapview, lib.loc=local.lib)
#}


log_file_name=paste(getwd(), args[1], sep="/");
geo_loc_file_name=paste(getwd(), args[2], sep="/");

message("")
message(paste("--- Source file ", paste(script.basename, '/global.R', sep='')))
source(paste(script.basename, '/global.R', sep=''));

message("")
message(paste("--- Render file ", args[3]))
rmarkdown::render(paste(script.basename, 'report.Rmd', sep='/'))

if (file.copy(paste(script.basename, "report.html", sep="/"), output_filename))
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
