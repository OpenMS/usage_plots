create_top_10_apps_plot <- function(data_to_plot, clustered, agg_type)
{
  firstup <- function(x) {
    substr(x, 1, 1) <- toupper(substr(x, 1, 1))
    x
  }

  plot_data <- data_to_plot |>
                sort_by(~calls) |>
                tail(10)
  plot_legend <- c(agg_type)
  plot_colors <- c("#3182bd")

  if (clustered)
  {
    plot_data$cluster_calls <- cluster_data[plot_data$app]
    plot_legend <- c(paste("cluster",agg_type), paste("individual",agg_type))
    plot_colors <- c("#9ecae1", "#3182bd")
  }

  plot_data$app <- factor(plot_data$app, levels=unique(plot_data$app))
  plot_data <- plot_data %>%
               pivot_longer(-app) %>%
               mutate(name = factor(name, levels = rev(unique(name))))

  plot <- ggplot(plot_data, aes(fill = name, y = app, x = value)) + common_theme +
    theme(axis.title.y=element_blank(),
          legend.position.inside = c(1, 0),
          legend.justification.inside = c(1, 0),
          legend.background = element_rect(fill = "white", color = "black"),
          legend.title=element_blank(),
          aspect.ratio = 9/16) +
    guides(fill = guide_legend(position = "inside", reverse=T)) +
    geom_bar(stat = "identity", position="stack") + scale_fill_manual(labels = plot_legend, values = plot_colors) +
    scale_x_continuous(name=paste("Sum of", firstup(agg_type)), labels = scales::comma) +
    labs(title=paste("Top 10 Applications Based on Overall", firstup(agg_type)), y = "App") +
    geom_text(aes(label = scales::comma(value)), stat="identity", position = position_stack(vjust = 0.5), hjust = 0.5, size = 3, check_overlap = TRUE)

  return(list(plot = plot, raw = plot_data))
}

top_10_apps_calls <- function(clustered = TRUE)
{
    plot_data <- aggregate(calls ~ app, data = global_logdata, sum)
    return(create_top_10_apps_plot(plot_data, clustered, "calls"))
}

top_10_apps_users <- function(clustered = TRUE)
{
    plot_data <- global_logdata %>%
                 select(ip, app) %>%
                 distinct() %>%
                 group_by(app) %>%
                 summarise(calls = n())
    return(create_top_10_apps_plot(plot_data, clustered, "users"))
}
