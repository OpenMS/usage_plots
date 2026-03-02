#!/usr/bin/env Rscript

initial.options <- commandArgs(trailingOnly = FALSE)
script.basename <- basename(sub("--file=", "", initial.options[grep("--file=", initial.options)]))
script.dirname <- dirname(sub("--file=", "", initial.options[grep("--file=", initial.options)]))

source(file.path(script.dirname, "config", "config.R"))

args <- commandArgs(trailingOnly = TRUE)

# Validate arguments
if (length(args) != 5) {
  stop(paste("Usage:", script.basename, "all.log geolocations.csv report.md OUT_DIR tool_tags.tsv",
             "\nNote: You can obtain `all.log` and `geolocations.csv` by executing ./process_log_file.sh on the",
             "concatenated raw log file.",
             "\n\nAll 5 arguments are required."),
       call. = FALSE)
}

# Parse arguments
log_file_name <- args[1]
geo_loc_file_name <- args[2]
report_file_name <- args[3]
output_dir <- args[4]
tooltag_file_name <- args[5]

# Convert output_dir to absolute path if needed
if (!startsWith(output_dir, "/")) {
  output_dir <- file.path(getwd(), output_dir)
}

# Create output directory
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

output_filename <- file.path(output_dir, "report.html")

if (file.exists(output_filename)) {
  message(paste("Overwriting output file", output_filename))
}

# Convert all paths to absolute if needed
if (!startsWith(log_file_name, "/")) {
  log_file_name <- file.path(getwd(), log_file_name)
}
if (!startsWith(geo_loc_file_name, "/")) {
  geo_loc_file_name <- file.path(getwd(), geo_loc_file_name)
}
if (!startsWith(report_file_name, "/")) {
  report_file_name <- file.path(getwd(), report_file_name)
}
if (!startsWith(tooltag_file_name, "/")) {
  tooltag_file_name <- file.path(getwd(), tooltag_file_name)
}

# Statistics files
conda_downloads_file <- file.path(output_dir, paste0("monthly_conda_downloads_", CURRENT_DATE, ".tsv"))
github_downloads_file <- file.path(output_dir, paste0("monthly_github_downloads_", CURRENT_DATE, ".tsv"))
github_contributions_file <- file.path(output_dir, paste0("monthly_github_contributions_", CURRENT_DATE, ".tsv"))
pypi_downloads_file <- file.path(output_dir, paste0("monthly_pypi_downloads_", CURRENT_DATE, ".tsv"))

# Validate all input files exist
required_files <- list(
  "Log file" = log_file_name,
  "Geolocation file" = geo_loc_file_name,
  "Report file" = report_file_name,
  "Tooltag file" = tooltag_file_name,
  "Conda downloads file" = conda_downloads_file,
  "GitHub downloads file" = github_downloads_file,
  "GitHub contributions file" = github_contributions_file,
  "PyPi downloads file" = pypi_downloads_file
)

for (file_desc in names(required_files)) {
  if (!file.exists(required_files[[file_desc]])) {
    stop(paste(file_desc, "not found:", required_files[[file_desc]]), call. = FALSE)
  }
}

tooltag_basename <- tolower(basename(tooltag_file_name))

if (grepl("seqan", tooltag_basename)) {
  project <- "SeqAn"
} else if (grepl("openms", tooltag_basename)) {
  project <- "OpenMS"
} else {
  stop("Error: Tooltag file name must contain either 'seqan' or 'openms'", call. = FALSE)
}

message(paste("Detected project:", project))

# Copy favicon
favicon_source <- file.path(script.dirname, "reporting", "assets", "favicon", paste0(project, ".svg"))
favicon_dest <- file.path(output_dir, "favicon.svg")

if (!file.exists(favicon_source)) {
  warning(paste("Favicon not found:", favicon_source))
} else {
  invisible(file.copy(favicon_source, favicon_dest, overwrite = TRUE))
}

# Source required scripts
source(file.path(script.dirname, "data_processing", "all.R"))
source(file.path(script.dirname, "plotting", "all.R"))

# Render report
message("")
message(paste("--- Rendering report:", report_file_name))
rmarkdown::render(
  report_file_name,
  params = list(project = project),
  output_file = output_filename,
  output_format = "html_document"
)

message(paste("Report created successfully:", output_filename))
