contries_and_cities_table <- function()
{
  country <- global_logdata %>%
    group_by(country, app) %>%
    summarise(country_calls = n(), .groups = "drop") %>%
    group_by(app) %>%
    mutate(country_count = n()) %>%
    arrange(app, -country_calls) %>%
    slice(1)

  city <- global_logdata %>%
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

daily_and_weekly_usage_table <- function()
{
  avg_calls <- global_logdata %>%
    group_by(app) %>%
    summarise(calls = sum(calls), .groups = "drop") %>%
    mutate(avg_per_day = calls / DIFF_TIME_DAYS, avg_per_week = calls / DIFF_TIME_WEEKS) %>%
    arrange(-calls) %>%
    setNames(c("Application", "Calls", "Average_per_Day", "Average_per_Week"))

  return(avg_calls)
}
