general_usage <- function(project) {
  plot_data <- global_logdata %>%
    mutate(DevelopedBy = ifelse(DevelopedBy == "denbi", "de.NBI", DevelopedBy)) %>%
    # Group by DevelopedBy and date, calculate sum of calls
    group_by(DevelopedBy, date) %>%
    summarise(calls = sum(calls), .groups = "drop") %>%
    # Convert to factor
    mutate(DevelopedBy = as.factor(DevelopedBy)) %>%
    # Complete all combinations
    complete(DevelopedBy, date, fill = list(calls = 0)) %>%
    # Convert to wide format
    pivot_wider(names_from = DevelopedBy, values_from = calls) %>%
    # Calculate cumulative sum for each DevelopedBy column
    mutate(across(-date, cumsum)) %>%
    # Convert back to long format
    pivot_longer(cols = -date,
                names_to = "DevelopedBy",
                values_to = "calls",
                names_ptypes = list(DevelopedBy = factor()))

  # Create the plot
  general_usage_plot <- ggplot(plot_data, aes(x = date, y = calls)) +
    common_theme +
    geom_area(aes(colour = DevelopedBy, fill = DevelopedBy),
              colour = "black", linewidth = .3, alpha = .7) +
    scale_x_date(limits = c(as.Date(MIN_DATE + 30), NA),
                oob = scales::oob_keep,
                date_labels = "%b %Y",
                minor_breaks = "1 months",
                date_breaks = "6 months") +
    theme(axis.text.x = element_text(angle = 25, vjust = 1.0, hjust = 1.0)) +
    scale_y_continuous(name = "Calls", labels = scales::comma) +
    labs(title = paste("Number of Calls of", project, "Applications"),
         fill = "Developed by:",
         x = "Month",
         y = "Calls")

  return(list(plot = general_usage_plot, raw = plot_data))
}
