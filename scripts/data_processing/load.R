log_data_new <- read.table(log_file_name, sep = "\t",
                           fill = T, header = T, quote = "",
                           stringsAsFactors = F)

geolocations <- read.table(geo_loc_file_name, sep = "\t",
                           fill = T, header = T, quote = "",
                           stringsAsFactors = F)

global_logdata <- merge(log_data_new, geolocations, by="ip")

    tool_tags <- read.table(tooltag_file_name, sep = "\t",
                            fill = T, header = T, quote = "",
                            stringsAsFactors = F)
    global_logdata <- merge(global_logdata, tool_tags, by.x="app", by.y="Tool", all.x=T)
  ## If not DevelopedBy tag registered, assume "external" tool
    global_logdata[is.na(global_logdata[,"DevelopedBy"]),"DevelopedBy"] = "extern"

# Process cluster information
cluster_data <- global_logdata %>%
  # Sort data
  arrange(date, ip, app) %>%
  # Calculate cumulative clustered values within groups
  group_by(date, ip) %>%
  mutate(clustered = cumsum(clustered)) %>%
  ungroup() %>%
  # Filter rows where clustered equals 1
  filter(clustered == 1) %>%
  # Count clusters by app
  group_by(app) %>%
  summarise(cluster_count = n()) %>%
  # Add missing apps with zero count
  right_join(
    tibble(app = unique(global_logdata$app)),
    by = "app"
  ) %>%
  # Replace NAs with zeros
  mutate(cluster_count = replace_na(cluster_count, 0)) %>%
  # Create named vector
  pull(cluster_count, name = app)

# Remove clustered entries from global data
global_logdata <- global_logdata %>%
  filter(clustered == 0)

# Transform date column from string to R date format
global_logdata <- global_logdata %>%
  mutate(
    date = as.Date(date, format = "%Y-%b-%d"),
    # Fix the duplicate longitude line and convert to numeric
    longitude = as.numeric(longitude),
    latitude = as.numeric(latitude)
  ) %>%
  # Remove rows with NA values
  drop_na()

MAX_DATE <- max(global_logdata$date)
MIN_DATE <- min(global_logdata$date)
DIFF_TIME_DAYS <- as.numeric(difftime(MAX_DATE + 1, MIN_DATE, units = "days"))
DIFF_TIME_WEEKS <- as.numeric(difftime(MAX_DATE + 1, MIN_DATE, units = "weeks"))
