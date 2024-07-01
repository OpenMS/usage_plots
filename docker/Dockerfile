FROM ubuntu_2204
RUN echo "Installing apt packages..."

RUN sudo apt-get -y update >> packages.log
RUN sudo apt-get -y install gawk libssl-dev sshpass libpng-dev libudunits2-dev libcairo2-dev libgdal-dev r-base r-base-dev pandoc python >> packages.log

RUN export RSTUDIO_PANDOC=/usr/bin/
ENV RSTUDIO_PANDOC=/usr/bin

RUN echo "Installing R packages..."
## mapview not needed anymore
COPY Rpackages.R Rpackages.R
RUN sudo Rscript --vanilla Rpackages.R
