#!/usr/bin/env Rscript

initial.options <- commandArgs(trailingOnly = FALSE)
script.dirname <- dirname(sub("--file=", "", initial.options[grep("--file=", initial.options)]))

libraries <- scan(file.path(script.dirname, "r-requirements.txt"), what="", sep="\n", quiet = TRUE)
install.packages(libraries, repos='https://cloud.r-project.org/')
q()
