# syntax=docker/dockerfile:1

FROM jenkins/agent:latest-trixie

ENV DEBIAN_FRONTEND=noninteractive
ENV GNUMAKEFLAGS="-j2 --no-print-directory --output-sync=target"
ENV MAKEFLAGS="-j2 --no-print-directory --output-sync=target"
ENV RSTUDIO_PANDOC=/usr/bin
ENV TZ=Europe/Berlin

USER root

# Overwrite TZ from jenkins image.
RUN ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && \
    echo "${TZ}" > /etc/timezone && \
    dpkg-reconfigure tzdata

SHELL ["/bin/bash", "-Eeuxo", "pipefail", "-c"]

COPY docker_scripts /docker_scripts

# Disable compiler warnings when R compiles packages from source.
ENV EXTRA_CXXFLAGS=-w
COPY config/Makevars /root/.R/Makevars

RUN /docker_scripts/install_apt_packages.sh

COPY --from=config r-requirements.txt /docker_scripts/
RUN /docker_scripts/install_R_packages.R

COPY --from=config requirements.txt /docker_scripts/
RUN pip3 install --break-system-packages -r /docker_scripts/requirements.txt

ARG user=jenkins
RUN echo "${user}    ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER "${user}"
