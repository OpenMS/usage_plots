plot_citations <- function(scholar_id) {
  cit <- get_citation_history(scholar_id)
  profile <- get_profile(scholar_id)

  citations <- ggplot(cit,aes(x=year,y=cites))+
    geom_bar(stat='identity')+
    scale_x_continuous(breaks = cit$year, labels = cit$year, minor_breaks = NULL) +
    scale_y_continuous(labels = scales::comma) +
    common_theme +
    labs(title = "Google Scholar Citations", y = "Citations", x = "Year") +
    theme(axis.text.x = element_text(angle = 45, vjust = 1.0, hjust = 1.0)) +
    annotate('text',label=format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),x=-Inf,y=Inf,vjust=1.5,hjust=-0.05,size=4,colour='darkgrey') +
    annotate('text',x=-Inf,y=Inf,vjust=1.5,hjust=0,size=5,color="#595959",
            label=paste0("  Citations: ", scales::comma(profile$total_cites), "\n",
                         "  h-index: ", profile$h_index, "\n",
                         "  i10-index: ", profile$i10_index))

  return(list(plot = citations, raw = cit))
}
