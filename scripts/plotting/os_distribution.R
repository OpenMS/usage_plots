create_os_distribution_plot <- function(data_to_plot, title_type)
{
  operating_system <- ggplot(data_to_plot, aes(x = "", y = count, fill = label)) +
    geom_bar(stat = "identity", linewidth=0.2, color="darkgray") +
    coord_polar("y", start = pi/2, direction=1) +
    theme_void(base_size=16) +
    scale_fill_brewer(palette = "Pastel1", name = "OS") +
    labs(title = paste("Distribution of Operating Systems \nover", scales::comma(sum(data_to_plot$count)), title_type)) +
    theme(legend.position = "right",
          plot.title = element_text(colour = "black", face="bold", size=20, hjust = 0.5),
          text=element_text(colour="black", family="Helvetica"),
          legend.key.spacing.y = unit(3, "points"),
          aspect.ratio = 9/9)

    return(list(plot = operating_system, raw = data_to_plot))
}

os_by_calls <- function()
{
  os_counts <- global_logdata %>%
    select(os) %>%
    group_by(os) %>%
    summarise(count = n()) %>%
    arrange(count) %>%
    # Calculate percentages
    mutate(
      percentage = round(count/sum(count)*100, 1),
      label = paste0(os, " (", percentage, "%)"),
      # Position labels in middle of each slice
      pos = cumsum(count) - count/2
    ) %>%
    arrange(-percentage) %>%
    mutate(label = factor(label, label))

    return(create_os_distribution_plot(os_counts, "Calls"))
}

os_by_users <- function()
{
  os_counts <- global_logdata %>%
    select(ip, os) %>%
    distinct() %>%
    group_by(os) %>%
    summarise(count = n()) %>%
    arrange(count) %>%
    mutate(
      percentage = round(count/sum(count)*100, 1),
      label = paste0(os, " (", percentage, "%)"),
      # Position labels in middle of each slice
      pos = cumsum(count) - count/2
    ) %>%
    arrange(-percentage) %>%
    mutate(label = factor(label, label))

  return(create_os_distribution_plot(os_counts, "Unique Users"))
}
