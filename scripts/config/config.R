libraries <- scan(file.path(script.dirname, "config", "r-requirements.txt"), what="", sep="\n", quiet = TRUE)
suppressPackageStartupMessages(lapply(libraries, library, quietly = TRUE, character.only = TRUE))

# Set locale
Sys.setlocale("LC_TIME", "C")

# Set min/max dates
CURRENT_DATE <- Sys.Date()

# In addition to all data, the report shows each year from FIRST_YEAR to the current year.
# Keep FIRST_YEAR in sync with data_processing/py/github_shared.py, which fetches the statistics from FIRST_YEAR on.
FIRST_YEAR <- 2023
CURRENT_YEAR <- as.integer(format(CURRENT_DATE, "%Y"))
REPORT_YEARS <- FIRST_YEAR:CURRENT_YEAR
