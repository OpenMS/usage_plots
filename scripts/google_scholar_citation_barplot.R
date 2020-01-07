## TODO try to use the same library as the other scripts from svenja
## TODO integrate into report
install.packages("scholar")
library(scholar)
library(ggplot2)

## The ID at the end of your profile link: https://scholar.google.de/citations?hl=de&user=tQ26gxIAAAAJ
cit <- get_citation_history('tQ26gxIAAAAJ')
cit_all <- get_publications('tQ26gxIAAAAJ')

## TODO make the output file specifiable
png('scholar_citations_tQ26gxIAAAAJ.png',width=800,height=300,res=150)
ggplot(cit,aes(x=year,y=cites))+
  geom_bar(stat='identity')+
  ## TODO make the years scale automatically
  scale_x_continuous(breaks=2006:2020,
                     labels=c("2006","2007","2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018","2019","2020"))+
  theme_bw()+
  xlab('Year of citation')+
  ylab('Google Scholar\n cites')+
  annotate('text',label=format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),x=-Inf,y=Inf,vjust=1.5,hjust=-0.05,size=3,colour='grey')
dev.off()
