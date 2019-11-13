##getting base image ubuntu
FROM ubuntu

MAINTAINER grennfp

RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils

##install python and PIP

#RUN apt-get install openssl
RUN apt-get install python2.7 python2.7-dev -y
RUN apt-get install python-setuptools -y
RUN apt-get install python-pip -y
RUN apt-get install cython -y

RUN apt-get install zlib1g-dev bzip2 libbz2-dev liblzma-dev -y

RUN apt-get install sudo -y

#set to noninteractive so not prompted for input when setting up R
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install r-base -y


RUN apt-get install libcurl4-openssl-dev libxml2-dev -y

RUN sudo R -e "install.packages('BiocManager')"
RUN sudo R -e "BiocManager::install('DESeq2')"

RUN pip install pysam
RUN pip install TEtranscripts

RUN apt-get install samtools -y

#setup for STAR
RUN sudo apt-get install g++ -y
RUN sudo apt-get install make -y

RUN sudo apt-get install zlib1g-dev -y

RUN apt-get install -y git

RUN git clone https://github.com/alexdobin/STAR.git


WORKDIR STAR/source

RUN make STAR

ENV PATH /STAR/source:$PATH

WORKDIR /
