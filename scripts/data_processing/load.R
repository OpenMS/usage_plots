log_data_new <- read.table(log_file_name, sep = "\t",
                           fill = T, header = T, quote = "",
                           stringsAsFactors = F)

# "NA" is the country code of Namibia, not a missing value.
geolocations <- read.table(geo_loc_file_name, sep = "\t",
                           fill = T, header = T, quote = "",
                           na.strings = character(),
                           stringsAsFactors = F)

tool_tags <- read.table(tooltag_file_name, sep = "\t",
                        fill = T, header = T, quote = "",
                        stringsAsFactors = F)

# A view is the data shown in one tab of the report, computed from the rows of `log_data_new` in `calls`
# as if the log contained only these rows.
# `label` is the tab name and `suffix` is added to the file names of the tab's plots and tables.
# Returns NULL if there are no calls.
create_view <- function(calls, label, suffix)
{
  logdata <- merge(calls, geolocations, by="ip")
  logdata <- merge(logdata, tool_tags, by.x="app", by.y="Tool", all.x=T)
  ## If not DevelopedBy tag registered, assume "external" tool
  logdata[is.na(logdata[,"DevelopedBy"]),"DevelopedBy"] = "extern"

  # Cluster calls are only shown in the top 10, all other statistics use the remaining (individual) calls
  cluster_calls <- logdata %>%
    filter(clustered == 1)
  logdata <- logdata %>%
    filter(clustered == 0)

  # Transform date column from string to R date format
  logdata <- logdata %>%
    mutate(
      date = as.Date(date, format = "%Y-%b-%d"),
      # Fix the duplicate longitude line and convert to numeric
      longitude = as.numeric(longitude),
      latitude = as.numeric(latitude)
    ) %>%
    # Remove rows with NA values
    drop_na()

  if (nrow(logdata) == 0) {
    return(NULL)
  }

  # Named vector of the cluster calls (or users) of each app, 0 for apps without cluster calls
  per_app <- function(counts) {
    counts <- counts %>%
      right_join(tibble(app = unique(c(cluster_calls$app, logdata$app))), by = "app") %>%
      mutate(n = replace_na(n, 0))
    return(pull(counts, n, name = app))
  }

  min_date <- min(logdata$date)
  max_date <- max(logdata$date)

  return(list(
    label = label,
    suffix = suffix,
    logdata = logdata,
    # Number of cluster calls of each app
    cluster_calls = per_app(cluster_calls %>% count(app)),
    # Number of IP addresses whose calls of the app are all cluster calls
    cluster_users = per_app(cluster_calls %>%
                              distinct(app, ip) %>%
                              anti_join(distinct(logdata, app, ip), by = c("app", "ip")) %>%
                              count(app)),
    min_date = min_date,
    max_date = max_date,
    diff_time_days = as.numeric(difftime(max_date + 1, min_date, units = "days")),
    diff_time_weeks = as.numeric(difftime(max_date + 1, min_date, units = "weeks"))
  ))
}

VIEW_ALL <- create_view(log_data_new, "All data", "")

if (is.null(VIEW_ALL)) {
  stop("The log does not contain any calls.", call. = FALSE)
}

# Date in the file names of the plots and tables of the log
LOG_DATE <- VIEW_ALL$max_date

# One view per year; calls from other years are not considered at all. Years without calls are skipped.
log_years <- as.integer(format(as.Date(log_data_new$date, format = "%Y-%b-%d"), "%Y"))
YEAR_VIEWS <- lapply(REPORT_YEARS, function(year) {
  create_view(log_data_new[which(log_years == year), ], as.character(year), paste0(year, "_"))
})
YEAR_VIEWS <- Filter(Negate(is.null), YEAR_VIEWS)

# Views of the sections with a tab per view
VIEWS <- c(list(VIEW_ALL), YEAR_VIEWS)
