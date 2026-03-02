libraries <- scan(file.path(script.dirname, "config", "r-requirements.txt"), what="", sep="\n", quiet = TRUE)
suppressPackageStartupMessages(lapply(libraries, library, quietly = TRUE, character.only = TRUE))

# Set locale
Sys.setlocale("LC_TIME", "C")

# Set min/max dates
CURRENT_DATE <- Sys.Date()
