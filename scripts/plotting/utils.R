common_theme <- theme_gray(base_size=16, base_family="Helvetica") +
  theme(axis.line = element_line(colour = "black", linewidth = 0.8/.pt),
        axis.ticks = element_line(colour = "black", linewidth = 1/.pt),
        axis.text.x = element_text(colour="black"),
        axis.text.y = element_text(colour = "black"),
        axis.title.x = element_text(colour = "black", face="bold"),
        axis.title.y = element_text(colour = "black", face="bold"),
        plot.title = element_text(colour = "black", face="bold", size=20, hjust = 0.5),
        text=element_text(colour="black"),
        legend.key.spacing.y = unit(3, "points"),
        aspect.ratio = 9/16)

savePlots <- function(name, plot_data)
{
    plot_basename_pdf <- paste(name, CURRENT_DATE, ".pdf", sep = "")
    plot_basename_png <- paste(name, CURRENT_DATE, ".png", sep = "")
    plot_basename_tsv <- paste(name, CURRENT_DATE, ".tsv", sep = "")

    plot_output_pdf <- paste(output_dir, plot_basename_pdf, sep = "/")
    plot_output_png <- paste(output_dir, plot_basename_png, sep = "/")
    plot_output_tsv <- paste(output_dir, plot_basename_tsv, sep = "/")

    ggsave(plot_output_pdf, plot_data$plot, width = 9.6, height = 6, units = "in")
    ggsave(plot_output_png, plot_data$plot, width = 9.6, height = 6, dpi = 300, units = "in")
    write.table(plot_data$raw, sep = "\t", file = plot_output_tsv, row.names = FALSE)

    result <- list(pdf = list(basename = plot_basename_pdf,
                              absolute = plot_output_pdf),
                   png = list(basename = plot_basename_png,
                              absolute = plot_output_png),
                   tsv = list(basename = plot_basename_tsv,
                              absolute = plot_output_tsv))

    return(result)
}

display_plot_with_buttons <- function(plot_files) {
  image_html <- paste0('![](', plot_files$png$absolute, ')\n\n')
  buttons_html <- paste0(
    '<a href="', plot_files$pdf$basename, '" download class="btn btn-info btn-dl" target="_blank">PDF</a> ',
    '<a href="', plot_files$png$basename, '" download class="btn btn-info btn-dl" target="_blank">PNG</a> ',
    '<a href="', plot_files$tsv$basename, '" download class="btn btn-info btn-dl" target="_blank">TSV</a> '
  )
  return(paste0(image_html, buttons_html))
}
