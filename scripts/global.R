## @knitr global_file
if(!require(leaflet)) {install.packages("leaflet"); library(leaflet)}
if(!require(ggplot2)) {install.packages("ggplot2"); library(ggplot2)}
if(!require(lattice)) {install.packages("lattice"); library(lattice)}
if(!require(rworldmap)) {install.packages("rworldmap"); library(rworldmap)}
if(!require(RColorBrewer)) {install.packages("RColorBrewer"); library(RColorBrewer)}

# global:
seqan_apps <- c("alf"     ,"bisar"   ,"casbar"  ,"four2three"      ,"dfi"     ,"compute_gain"    ,"fiona"   ,
	            "fiona_illumina"  ,"fx_bam_coverage" ,"fx_fastq_stats"  ,"gustaf"  ,"gustaf_mate_joining"     ,
	            "insegt"  ,"mason_genome"    ,"mason_methylation"       ,"mason_frag_sequencing"   ,
	            "mason_variator"  ,"mason_materializer"      ,"mason_simulator" ,"mason_splicing"  ,
	            "mason_tests"     ,"micro_razers"    ,"roi_plot_thumbnails"     ,"bam2roi" ,
	            "roi_feature_projection"  ,"pair_align"      ,"param_chooser"   ,"test_funcs_param_chooser",
	            "rabema_prepare_sam"      ,"rabema_build_gold_standard"      ,"rabema_evaluate" ,
	            "rabema_do_search"        ,"razers"  ,"razers3" ,"razers3_compPHSens"      ,
	            "razers3_simulate_reads"  ,"razers3_quality2prob"    ,"rep_sep" ,"sak"     ,
	            "sam2matrix"      ,"samcat"  ,"s4_search"       ,"s4_join" ,"seqan_tcoffee" ,"seqcons2",
	            "sgip"    ,"snp_store"       ,"splazers"        ,"stellar","tree_recon"      ,"yara_indexer"  ,
	            "yara_mapper")

###############################################################################
#                               Prepare logdata
###############################################################################

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ read in csv ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if (!exists("log_file_name"))
{
    print("[ERROR - global.R]: variable 'log_file_name' is not defined. Please define variable manually.");
    stop();
}

if (!exists("geo_loc_file_name"))
{
    print("[ERROR - global.R]: variable 'geo_loc_file_name' is not defined. Please define variable manually.");
    stop();
}

log_data_new <- read.table(log_file_name, sep = "\t",
                           fill = T, header = T, quote = "",
                           stringsAsFactors = F)

if (nrow(log_data_new)==0)
{
    print(paste("[ERROR - global.R]: Cannot work on empty log data file (file name:",log_file_name,")"));
    stop();
}

geolocations <- read.table(geo_loc_file_name, sep = "\t",
                           fill = T, header = T, quote = "",
                           stringsAsFactors = F)

if (nrow(geolocations)==0)
{
    print(paste("[ERROR - global.R]: Cannot work on empty geolocations file (file name:",geo_loc_file_name,")"));
    stop();
}

geolocations <- read.table(geo_loc_file_name, sep = "\t",
                           fill = T, header = T, quote = "",
                           stringsAsFactors = F)

global_logdata <- merge(log_data_new, geolocations, by="ip")

## Add tooltags if present
if (exists("tooltag_file_name"))
{
	tool_tags <- read.table(tooltag_file_name, sep = "\t",
	                           fill = T, header = T, quote = "",
	                           stringsAsFactors = F)
	global_logdata <- merge(global_logdata, tool_tags, by.x="app", by.y="Tool", all.x=T)
	global_logdata[is.na(global_logdata[,"DevelopedBy"]),"DevelopedBy"] = "unknown"
} else {
	global_logdata$DevelopedBy = "any"
}



# ~~~~~~~~~~~~~~~~~~~ process cluster information ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# count number of cluster uses per app
df <- global_logdata[ order(global_logdata[,"date"],
                           global_logdata[,"ip"],
                           global_logdata[,"app"]), ]
for (i in 1:nrow(df))
{
  if (df$clustered[i] != 0)
    df$clustered[i] = df$clustered[i]+df$clustered[i-1]
}
df <- df[which(df$clustered == 1),c("app", "clustered")]
df <- data.frame(aggregate(df$clustered, list(df$app), sum))
df <- rbind(df,setNames(data.frame(unique(global_logdata$app),0), names(df)))
df <- df[!duplicated(df[,1]),]
cluster_data <- df[,2]
names(cluster_data) <- df[,1]

# remove entries marked as clustered from global data
global_logdata <- global_logdata[which(global_logdata["clustered"]==0),]

# debug
# if (length(which(!complete.cases(global_logdata)))!=0)
#    {warning(paste(c("Left our rows", which(!complete.cases(global_logdata))),sep = ""))}

Sys.setlocale("LC_TIME", "C")

# ~~~~~~~~~~~~~~~~~~~~~~~~~ date transformation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# transform the date column from string to the r date format
global_logdata["date"] <- lapply(global_logdata["date"], as.Date, format="%Y-%b-%d")

# min/max dates
MAX_DATE <- max(global_logdata$date)
MIN_DATE <- min(global_logdata$date)

# ~~~~~~~~~~~~~~~~~~~~~~~~~ numeric transformation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
global_logdata["longitude"] <- lapply(global_logdata["longitude"], as.numeric)
global_logdata["longitude"] <- lapply(global_logdata["longitude"], as.numeric)

# ~~~~~~~~~~~~~~~~~~~~~~~~~ remove NA's ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# remove rows containing NA due to parsing errors
global_logdata <- global_logdata[complete.cases(global_logdata),]
###############################################################################
#                               Helper Functions
###############################################################################

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                        create html info text for world map
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

prepare_data_for_worldmap <- function(mapdata)
{
	# ------------------------- add html text for info popup ------------------
	mapdata_aggr_by_pos <- aggregate(mapdata$calls, list(mapdata$latitude,
	                                                     mapdata$longitude,
	                                                     mapdata$country,
	                                                     mapdata$city), sum)
	mapdata_aggr_by_app <- aggregate(mapdata$calls, list(mapdata$latitude,
	                                                     mapdata$longitude,
	                                                     mapdata$app), sum)
	colnames(mapdata_aggr_by_pos) <- c("lat", "lng", "country", "city", "radius_size")
	colnames(mapdata_aggr_by_app) <- c("lat", "lng", "app", "calls")
	mapdata_aggr_by_pos <- mapdata_aggr_by_pos[order(mapdata_aggr_by_pos$lat),]
	mapdata_aggr_by_app <- mapdata_aggr_by_app[order(mapdata_aggr_by_app$lat),]

	n <- nrow(mapdata_aggr_by_pos)

	mapdata_aggr_by_pos["infotext"] <- rep(",", n) # initialize
	j <- 1 # keeps mapdata_aggr_by_pos and mapdata_aggr_by_app synchronized
	for ( i in seq(1, n) ){ # for every location

	  #determine number of apps num_apps for location i
	  curr_apps <- which(mapdata_aggr_by_app$lat == mapdata_aggr_by_pos$lat[i])
	  num_apps <- length(curr_apps)

	  # append city name and (country)
	  content <- c('<table style="width:100%">',
	               '<tr>',
	               '<th></th>',
	               '<th>', mapdata_aggr_by_pos$city[i], ' (',
	               mapdata_aggr_by_pos$country[i], ')</th>',
	               '</tr>')
	  #append 'Expand...' if needed
	  if (num_apps -5 > 0){
	    content <- c(content,'<tr>', '<td></td>',
	                 '<td style="text-align:right;"><a href="#all_apps" data-toggle="collapse">Expand...</a></td>',
	                 '</tr>')
	  }

	  # append first 5 apps
	  for (a in curr_apps[1:min(5, num_apps)]){
	    content <- c(content, '<tr>',
	                 '<td style="padding: 0px 10px 0px 0px">',
	                 mapdata_aggr_by_app$calls[a], '</td>',
	                 '<td>', mapdata_aggr_by_app$app[a],'</td>',
	                 '</tr>'
	    )
	  }

	  # append last ones as expand panel
	  if (num_apps -5 > 0){
	    content <- c(content, '</table><table id=all_apps class="collapse" style="width:100%">')
	    for (a in curr_apps[1:(num_apps - 5)]){
	      content <- c(content, '<tr>',
	                   '<td style="padding:0px 10px 0px 0px">',
	                   mapdata_aggr_by_app$calls[a], '</td>',
	                   '<td>', mapdata_aggr_by_app$app[a],'</td>',
	                   '</tr>'
	      )
	    }
	  }

	  content <- c(content, "</table>")
	  mapdata_aggr_by_pos$infotext[i] <- paste(content, collapse = "")
	  j <- j + num_apps
	}

	# ------------------------- manipulate radius size ------------------

	# +1 pseudocounts, take log for scaling outliers
	mapdata_aggr_by_pos$radius_size <- log(mapdata_aggr_by_pos$radius_size + 1)
    max_calls <- max(mapdata_aggr_by_pos$radius_size)
    max_radius <- 20

    # scale radius so the circles do not get too big
    mapdata_aggr_by_pos$radius_size <- mapdata_aggr_by_pos$radius_size * max_radius / max_calls

	return(mapdata_aggr_by_pos)
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                        count unique ip addresses by month
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

new_unique_ips_per_month <- function(data)
{
  par(mfrow=c(1,2), mar=c(5,5,5,5), cex=0.7)

  # Unique User Count
  local_logdata      <- global_logdata[!duplicated(global_logdata$ip),]
  local_logdata$date <- strftime(local_logdata$date, format = "%Y-%m")
  plot_data <- aggregate(calls ~ date, data = local_logdata, sum)
  plot_data <- plot_data[-nrow(plot_data),] # exclude last month because it is probably incomplete
  colnames(plot_data) <- c("Month", "New_Unique_Users")

  barplot(plot_data$New_Unique_Users, col = "lightblue",
          names.arg = plot_data$Month,
          ylab = "Unique New Users per Month",
          las = 2,
          main = "New (unique) User Count per Month")
  par(new=T)
  plot(cumsum(plot_data$New_Unique_Users), axes=F,
       xlab = "", ylab = "", type = "l", col = "red")
  axis(4, at = round(seq(1, max(cumsum(plot_data$New_Unique_Users)),
                         length.out = 6)), col="red")
  mtext("Cumulative sum of Unique Users", side=4, line=3, cex.lab=1, col="red")

  plot(plot_data$New_Unique_Users, type = "l", col = "blue",
       xlab = "", ylab = "Unique New Users per Month", xaxt='n',
       main = "New (unique) User Count per Month")
  axis(1, at = 1:nrow(plot_data), labels = plot_data$Month, las = 2)
 }

total_ips_per_month <- function(data)
{
  par(mfrow=c(1,2), mar=c(5,5,5,5), cex=0.7)

  # Total User Count
  local_logdata      <- global_logdata#[!duplicated(global_logdata$ip),]
  local_logdata$date <- strftime(local_logdata$date, format = "%Y-%m")
  plot_data <- aggregate(calls ~ date, data = local_logdata, sum)
  plot_data <- plot_data[-nrow(plot_data),] # exclude last month because it is probably incomplete
  colnames(plot_data) <- c("Month", "Total_Usage")

  barplot(plot_data$Total_Usage, col = "lightblue",
          names.arg = plot_data$Month,
          ylab = "Usages per Month",
          las = 2,
          main = "Usage Count per Month")
  par(new=T)
  plot(cumsum(plot_data$Total_Usage), axes=F,
       xlab = "", ylab = "", type = "l", col = "red")
  axis(4, at = round(seq(1, max(cumsum(plot_data$Total_Usage)),
                         length.out = 6)), col="red")
  mtext("Cumulative sum of Usage", side=4, line=3, cex.lab=1, col="red")

  plot(plot_data$Total_Usage, type = "l", col = "blue",
       xlab = "", ylab = " Userage per Month", xaxt='n',
       main = "Usage Count per Month")
  axis(1, at = 1:nrow(plot_data), labels = plot_data$Month, las = 2)
}

###############################################################################
#                               Plot Functions
###############################################################################

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Function pieChart.OS()
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# brief: pie chart for operating system (OS)

# input:
#   data_to_plot	data.frame	a data frame containing the columns ip and os
pieChart.OS.users <- function(data_to_plot)
{
    t <- table(unique(data_to_plot[, c("ip","os")])[,2])
    pie(t, labels = paste(names(t), " ", round(t*100/sum(t), 1), "%", sep = ""),
        radius=0.5)
    title(paste("Distribution of Operating Systems \n over", sum(t), "Unique Users"),
          line=-4)
}

# input:
#   data_to_plot	data.frame	a data frame containing the column os
pieChart.OS.calls <- function(data_to_plot)
{
    t <-table(data_to_plot$os)
    pie(t, labels = paste(names(t), " ", round(t*100/sum(t), 1), "%", sep = ""),
        radius = 0.5)
    title(paste("Distribution of Operating Systems \n over", sum(t), "overall Calls"),
          line=-4)
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Function barPlot.Top10Apps()
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# brief: aggregates calls/users per application and plots the 10 apps that have
#        the highest number of calls/users

# input:
#   data_to_plot	data.frame	a daggregated dataframe with one column containing the numbers
#	clustered 		bool		indicates whether to differentiate between cluster uses
#	mytitle			string 		title used for the plot
barPlot.Top10Apps <- function(data_to_plot, clustered, agg_type)
{
    plot_legend <- c(agg_type)

    data_to_plot <- data_to_plot[order(data_to_plot[,1], decreasing = T), ,drop = F] # sort
    data_to_plot <- data_to_plot[1:10, ,drop = F]                                    # take top 10
    data_to_plot <- data_to_plot[order(data_to_plot[,1], decreasing = F), ,drop = F] # reorder for plot

    if (clustered)
    {
      data_to_plot <- cbind(data_to_plot, cluster_data[rownames(data_to_plot)])  # add cluster info
      data_to_plot[,1] <- data_to_plot[,1] - data_to_plot[,2]
      plot_legend <- c(paste("individual",agg_type), paste("cluster",agg_type))
    }

    par(mar = c(4, 10, 4, 2)) # increase left border for app names
    barplot(as.matrix(t(data_to_plot)),
            space = 0.5,
            xlab=paste("Sum of",agg_type),
            main=paste("Top 10 Applications based on overall",agg_type),
            col=brewer.pal(10,"Paired"),
            horiz = T,
            names.arg = rownames(data_to_plot),
            las = 2,
            legend.text = plot_legend,
            args.legend = list(x = "bottomright"))

    scale <- 1500/max(data_to_plot[,1])
    text(x = data_to_plot[,1]-scale, y = seq(0.9, 1.5*nrow(data_to_plot), by=1.5),
    	 label = data_to_plot[,1], pos = 2, offset=0.1, cex = 0.7, col = "black")
    if (clustered)
    {
    	text(x = data_to_plot[,1]+scale, y = seq(0.9, 1.5*nrow(data_to_plot), by=1.5),
    		 label = data_to_plot[,2], pos = 4, offset=0.05,cex = 0.7, col = "white")
    }
}

# input:
#   data_to_plot	data.frame	a data frame containing the columns calls and app
#	clustered 		bool		indicates whether to differentiate between cluster uses
barPlot.Top10Apps.calls <- function(data_to_plot, clustered)
{
    agg.data <- data.frame(aggregate(data_to_plot$calls, list(data_to_plot$app), sum), row.names = 1)

    return(barPlot.Top10Apps(agg.data, clustered, "calls"))
}

# input:
#   data_to_plot	data.frame	a data frame containing the columns calls and app
#	clustered 		bool		indicates whether to differentiate between cluster uses
barPlot.Top10Apps.users <- function(data_to_plot, clustered)
{
    data_to_plot <- unique(data_to_plot[,c("ip","app")])
    counted.data <- data.frame(apply(table(data_to_plot[,2], data_to_plot[,1]), 1, sum)) # aggregate

    return(barPlot.Top10Apps(counted.data, clustered, "users"))
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Function plotWorldmap()
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# brief: plots a world map and adds circles, sized by the number of app calls, to it

# input:
#	mapdata 	data.frame	a data frame containing columns app, longitude,
#                           latidude, country, city, infotext and radius_size
#                           (obtained by prepare_data_for_worldmap())
plotWorldmap <- function(mapdata)
{
	return(leaflet(mapdata, width = "100%") %>% addTiles() %>% addCircleMarkers(~lng, ~lat,
	                                                            radius = ~radius_size,
	                                                            color = "blue",
	                                                            fill = T,
	                                                            popup = ~infotext))
}

