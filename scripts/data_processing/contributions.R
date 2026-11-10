get_aggregated_contributions <- function() {
  # Read the data file
  contributions_data <- read_tsv(github_contributions_file, col_types = cols()) %>%
    mutate(
      quarter = quarter(ym(Month), type = "year.quarter")
    )

  quarter_ranges <- get_quarter_ranges()

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
