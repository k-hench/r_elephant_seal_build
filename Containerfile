FROM docker.io/debian:11.3
LABEL authors="Kosmas Hench" \
      description="Contains the R environment for an elephant seal sequencing project"

# install R dependencies
RUN apt update && \
    apt install -y wget dirmngr gnupg apt-transport-https ca-certificates software-properties-common

# install R
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-key '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7' && \
    add-apt-repository 'deb http://cloud.r-project.org/bin/linux/debian bullseye-cran40/'
RUN apt update && \
    apt install -y r-base-dev openssl libudunits2-0 libudunits2-dev libgdal-dev libgsl-dev libatlas3-base git wget libasound2

# install rstudio
RUN wget https://download1.rstudio.org/desktop/bionic/amd64/rstudio-2022.07.0-548-amd64.deb && \
    apt install -y ./rstudio-2022.07.0-548-amd64.deb
ENV LC_ALL=C.UTF-8
ENV RSTUDIO_WHICH_R=/usr/bin/R

# restrict R libs to the container (when using singularity) and fix system timezone
RUN sed 's/^R_LIBS_USER/# R_LIBS_USER/' /etc/R/Renviron > /etc/R/Renviron.control && \
    mv /etc/R/Renviron.control /etc/R/Renviron && \
    echo 'TZ="UTC"' >> /etc/R/Renviron

# setup R environment
COPY renv.lock ./
RUN R --slave -e 'install.packages("renv", version = "0.15.5")' && \
    R -e 'renv::restore()'

# setting up conda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.12.0-Linux-x86_64.sh && \
    bash Miniconda3-py39_4.12.0-Linux-x86_64.sh -b -p /miniconda
ENV PATH ${PATH}:/miniconda/bin

# install mamba for fast installation and set up channels
RUN conda install mamba -y -n base -c conda-forge
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge

# install packages available via conda
COPY env.yml /
RUN mamba env create -f /env.yml && conda clean -a
ENV PATH ${PATH}:/miniconda/envs/r_elephant_seal-0.1/bin