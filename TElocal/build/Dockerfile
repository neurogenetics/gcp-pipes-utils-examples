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


RUN apt-get install samtools -y
RUN apt-get install bcftools -y

RUN pip install pysam


RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y git && \ 
    apt-get install curl -y
    
RUN git clone https://github.com/mhammell-laboratory/TElocal.git

WORKDIR TElocal

RUN python setup.py install

#add the annotation files to the docker image so we don't need to push them to google cloud
COPY /hg38_gene_annotation.gtf /annotations/
COPY /hg38_rmsk_wHSAT2_TElocus.ind /annotations/

#add google cloud sdk so we can use gsutil to copy sample bams to the container
RUN curl https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz > /tmp/google-cloud-sdk.tar.gz

RUN mkdir -p /usr/local/gcloud \
  && tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz \
  && /usr/local/gcloud/google-cloud-sdk/install.sh

ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin

WORKDIR /

