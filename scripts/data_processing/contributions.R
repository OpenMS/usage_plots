get_aggregated_contributions <- function() {
  # Read the data file
  contributions_data <- read_tsv(github_contributions_file, col_types = cols()) %>%
    mutate(
      quarter = quarter(ym(Month), type = "year.quarter")
    )

  # Get current and previous year for quarter ranges
  current_year <- year(today())
  previous_year <- current_year - 1

  # Define the three quarter ranges
  quarter_ranges <- data.frame(
    Start = c(paste(previous_year, "Q1"),
              paste(previous_year, "Q4"),
              paste(current_year, "Q1")),
    Start_as_Date = c(previous_year + 0.1,
                      previous_year + 0.4,
                      current_year + 0.1),
    End = c(paste(previous_year, "Q4"),
            paste(current_year, "Q3"),
            paste(current_year, "Q4")),
    End_as_Date = c(previous_year + 0.4,
                    current_year + 0.3,
                    current_year + 0.4),
    stringsAsFactors = FALSE
  )

  results <- quarter_ranges %>%
    rowwise() %>%
    mutate(
      Issues_Opened = contributions_data %>%
        filter(between(quarter, Start_as_Date, End_as_Date)) %>%
        summarise(total = sum(Issues_Opened)) %>%
        pull(total),
      Issues_Closed = contributions_data %>%
        filter(between(quarter, Start_as_Date, End_as_Date)) %>%
        summarise(total = sum(Issues_Closed)) %>%
        pull(total),
      PRs_Opened = contributions_data %>%
        filter(between(quarter, Start_as_Date, End_as_Date)) %>%
        summarise(total = sum(PRs_Opened)) %>%
        pull(total),
      PRs_Closed = contributions_data %>%
        filter(between(quarter, Start_as_Date, End_as_Date)) %>%
        summarise(total = sum(PRs_Closed)) %>%
        pull(total)
    ) %>%
    select(Start, End, Issues_Opened, Issues_Closed, PRs_Opened, PRs_Closed) %>%
    ungroup()

  return(results)
}
