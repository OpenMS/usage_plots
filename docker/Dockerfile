from ubuntu_1804
RUN echo "Installing apt packages..."
#sudo apt-get -y update > packages.log
#sudo apt-get -y install dirmngr python python-pip python-dev python-pycurl gawk sshpass >> packages.log
#echo "deb https://cran.uni-muenster.de/bin/linux/ubuntu trusty/" | sudo tee -a /etc/apt/sources.list
#sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

#python python-pip python-dev python-pycurl
RUN sudo apt-get -y update >> packages.log
RUN sudo apt-get -y install gawk sshpass libudunits2-dev libcairo2-dev libgdal-dev r-base r-base-dev pandoc python >> packages.log

RUN export RSTUDIO_PANDOC=/usr/bin/
ENV RSTUDIO_PANDOC=/usr/bin

RUN sudo R --version
RUN echo "Installing R packages..."
## mapview not needed anymore
COPY Rpackages.R Rpackages.R
RUN sudo Rscript --vanilla Rpackages.R
