contries_and_cities_table <- function(view)
{
  country <- view$logdata %>%
    group_by(country, app) %>%
    summarise(country_calls = n(), .groups = "drop") %>%
    group_by(app) %>%
    mutate(country_count = n()) %>%
    arrange(app, -country_calls) %>%
    slice(1)

  # Cities with the same name in different regions or countries are different cities
  city <- view$logdata %>%
    mutate(city = paste0(city, " (", region, ", ", country, ")")) %>%
    group_by(city, app) %>%
    summarise(city_calls = n(), .groups = "drop") %>%
    group_by(app) %>%
    mutate(city_count = n()) %>%
    arrange(app, -city_calls) %>%
    slice(1)

  result <- country %>%
    left_join(city, by = "app") %>%
    relocate(c("app", "country_count", "city_count", "country", "country_calls", "city", "city_calls")) %>%
    arrange(-country_count) %>%
    setNames(c("Application", "Countries", "Cities", "Country_with_most_calls", "Calls_from_Country", "City_with_most_calls", "Calls_from_City"))

  return(result)
}

daily_and_weekly_usage_table <- function(view)
{
  avg_calls <- view$logdata %>%
    group_by(app) %>%
    summarise(calls = sum(calls), .groups = "drop") %>%
    mutate(avg_per_day = calls / view$diff_time_days, avg_per_week = calls / view$diff_time_weeks) %>%
    arrange(-calls) %>%
    setNames(c("Application", "Calls", "Average_per_Day", "Average_per_Week"))

  return(avg_calls)
}

# One row per period of get_quarter_ranges(). `summarise_period` returns a one-row data frame for the rows of
# `data` whose date is within the period.
aggregate_per_period <- function(data, summarise_period)
{
  ranges <- get_quarter_ranges()
  rows <- lapply(seq_len(nrow(ranges)), function(i) {
    in_period <- data %>%
      filter(between(date, ranges$First_Day[i], ranges$Last_Day[i]))
    bind_cols(tibble(Start = ranges$Start[i], End = ranges$End[i]), summarise_period(in_period))
  })
  return(bind_rows(rows))
}

# Calls per tool tag, as in general_usage(), but per period instead of cumulative
general_usage_per_period <- function(view)
{
  logdata <- view$logdata %>%
    mutate(DevelopedBy = ifelse(DevelopedBy == "denbi", "de.NBI", DevelopedBy))
  developers <- levels(as.factor(logdata$DevelopedBy))

  return(aggregate_per_period(logdata, function(period) {
    calls <- sapply(developers, function(developer) sum(period$calls[period$DevelopedBy == developer]))
    as_tibble(as.list(c(calls, Total = sum(period$calls))))
  }))
}

# Sums of the monthly values `column` of a monthly plot (see plotting/monthly.R) per period of
# get_quarter_ranges(). The sums are the same as summing up the rows of the plot's TSV.
monthly_per_period <- function(plot_data, column, name = column)
{
  return(aggregate_per_period(plot_data %>% rename(date = Month), function(period) {
    tibble(!!name := sum(period[[column]]))
  }))
}
