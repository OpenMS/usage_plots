get_aggregated_downloads <- function() {
  # Read the data files
  github_data <- read_tsv(github_downloads_file, col_types = cols())
  conda_data <- read_tsv(conda_downloads_file, col_types = cols())
  pypi_data <- read_tsv(pypi_downloads_file, col_types = cols())

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

  # Function to convert Month (YYYY-MM) to quarter
  add_quarter <- function(data) {
    data %>%
      mutate(
        quarter = quarter(ym(Month), type = "year.quarter")
      )
  }

  # Function to aggregate by quarter ranges
  aggregate_by_quarters <- function(data, type_name) {
    data_with_quarter <- data %>%
      filter(Type == type_name) %>%
      add_quarter()

    # Calculate downloads for each quarter range
    quarter_ranges %>%
      rowwise() %>%
      mutate(
        Downloads = data_with_quarter %>%
          filter(between(quarter, Start_as_Date, End_as_Date)) %>%
          summarise(total = sum(Downloads)) %>%
          pull(total)
      ) %>%
      select(Start, End, Downloads) %>%
      ungroup()
  }

  # Function to process data for a specific type
  process_type <- function(type_name) {
    # Aggregate each source by quarters
    github_quarterly <- aggregate_by_quarters(github_data, type_name) %>%
      rename(GitHub_Downloads = Downloads)

    conda_quarterly <- aggregate_by_quarters(conda_data, type_name) %>%
      rename(Conda_Downloads = Downloads)

    pypi_quarterly <- aggregate_by_quarters(pypi_data, type_name) %>%
      rename(PyPI_Downloads = Downloads)

    # Combine all sources
    combined <- github_quarterly %>%
      left_join(conda_quarterly, by = c("Start", "End")) %>%
      left_join(pypi_quarterly, by = c("Start", "End")) %>%
      mutate(
        GitHub_Downloads = replace_na(GitHub_Downloads, 0),
        Conda_Downloads = replace_na(Conda_Downloads, 0),
        PyPI_Downloads = replace_na(PyPI_Downloads, 0),
        Total_Downloads = GitHub_Downloads + Conda_Downloads + PyPI_Downloads
      )

    return(combined)
  }

  # Process libraries and apps
  message("\n=== Processing Libraries ===")
  library_total <- process_type("Library")

  message("\n=== Processing Apps ===")
  app_total <- process_type("Application")

  return(list(
    libraries = library_total,
    apps = app_total
  ))
}
