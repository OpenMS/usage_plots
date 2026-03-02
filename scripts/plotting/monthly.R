# Generic function to create monthly metric plots
create_monthly_plots <- function(plot_data, y_col, cumulative_col,
                                title, y_axis_label, cumulative_label) {

  # Calculate scale factor
  scale_factor <- max(plot_data[[cumulative_col]]) / max(plot_data[[y_col]])

  # Plot 1: Bar chart with cumulative line
  p1 <- ggplot(plot_data) +
    geom_col(aes(x = Month, y = .data[[y_col]]), fill = "lightblue") +
    geom_step(aes(x = Month, y = .data[[cumulative_col]]/scale_factor, group = 1),
              color = "red", linewidth = 1) +
    scale_x_date(limits = c(as.Date(MIN_DATE + 30), NA),
                oob = scales::oob_keep,
                date_labels = "%b %Y",
                minor_breaks = "1 months",
                date_breaks = "3 months") +
    scale_y_continuous(name = y_axis_label,
                       labels = scales::comma,
                       sec.axis = sec_axis(~.*scale_factor, name = cumulative_label, labels = scales::comma)) +
    labs(title = title) +
    common_theme +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5),
      axis.title.y.right = element_text(color = "red"),
      axis.text.y.right = element_text(color = "red"),
      axis.line.y.right = element_line(colour = "red"),
      axis.ticks.y.right = element_line(colour = "red")
    )

  # Plot 2: Line chart
  p2 <- ggplot(plot_data) +
    geom_step(aes(x = Month, y = .data[[y_col]], group = 1), color = "blue", linewidth = 1) +
    labs(title = title, y = y_axis_label) +
    scale_x_date(limits = c(as.Date(MIN_DATE + 30), NA),
                oob = scales::oob_keep,
                date_labels = "%b %Y",
                minor_breaks = "1 months",
                date_breaks = "3 months") +
    scale_y_continuous(labels = scales::comma) +
    common_theme +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5))

  result <- list(bar = list(plot = p1,
                            raw = plot_data),
                 line = list(plot = p2,
                             raw = plot_data))

  return(result)
}

# Update the three functions to use the generic implementation
new_unique_ips_per_month <- function() {
  plot_data <- global_logdata %>%
    # Get unique users
    filter(!duplicated(ip)) %>%
    # Format date
    mutate(date = format(date, "%Y-%m")) %>%
    # Group and summarise
    group_by(Month = date) %>%
    summarise(New_Unique_Users = sum(calls)) %>%
    # Fill Missing Months
    mutate(Month = as.Date(paste0(Month, "-01"))) %>%
    complete(Month = seq(first(Month), last(Month), by = "month"), fill=list(New_Unique_Users=0)) %>%
    # Remove last month
    slice(-n()) %>%
    # Add cumulative sum
    mutate(Cumulative_Users = cumsum(New_Unique_Users))

  return(create_monthly_plots(
    plot_data = plot_data,
    y_col = "New_Unique_Users",
    cumulative_col = "Cumulative_Users",
    title = "New Unique Users per Month",
    y_axis_label = "New Unique Users per Month",
    cumulative_label = "Cumulative Sum of Unique Users"
  ))
}

unique_ips_per_month <- function() {
  plot_data <- global_logdata %>%
    # Format date to year-month
    mutate(date = format(date, "%Y-%m")) %>%
    # Group by date and IP, sum calls for each combination
    group_by(Month = date, ip) %>%
    summarise(calls = sum(calls), .groups = "drop") %>%
    # Count unique IPs per month
    group_by(Month) %>%
    summarise(Unique_Users = n()) %>%
    # Fill Missing Months
    mutate(Month = as.Date(paste0(Month, "-01"))) %>%
    complete(Month = seq(first(Month), last(Month), by = "month"), fill=list(Unique_Users=0)) %>%
    # Remove the last month
    slice(-n()) %>%
    # Add cumulative sum
    mutate(Cumulative_Users = cumsum(Unique_Users))

  return(create_monthly_plots(
    plot_data = plot_data,
    y_col = "Unique_Users",
    cumulative_col = "Cumulative_Users",
    title = "Unique User Count per Month",
    y_axis_label = "Unique Users per Month",
    cumulative_label = "Cumulative Sum of Unique Users"
  ))
}

total_ips_per_month <- function() {
  plot_data <- global_logdata %>%
    # Format date
    mutate(date = format(date, "%Y-%m")) %>%
    # Group and summarize
    group_by(Month = date) %>%
    summarise(Total_Calls = sum(calls)) %>%
    # Fill Missing Months
    mutate(Month = as.Date(paste0(Month, "-01"))) %>%
    complete(Month = seq(first(Month), last(Month), by = "month"), fill=list(Total_Calls=0)) %>%
    # Remove last month
    slice(-n()) %>%
    # Add cumulative sum
    mutate(Cumulative_Calls = cumsum(Total_Calls))

  return(create_monthly_plots(
    plot_data = plot_data,
    y_col = "Total_Calls",
    cumulative_col = "Cumulative_Calls",
    title = "Calls per Month",
    y_axis_label = "Calls per Month",
    cumulative_label = "Cumulative Sum of Calls"
  ))
}
