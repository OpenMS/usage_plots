#!/bin/bash

R -e "library(knitr);setwd('$(pwd)'); rmarkdown::render('report_seqan.Rmd')"

R -e "library(knitr);setwd('$(pwd)'); rmarkdown::render('report_openms.Rmd')"
