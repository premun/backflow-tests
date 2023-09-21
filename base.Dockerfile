# syntax=docker/dockerfile:1.3-labs

FROM ubuntu:20.04

RUN apt-get update && apt-get install -y git tree wget vim

# Update git
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common \
 && add-apt-repository ppa:git-core/ppa -y \
 && apt-get update \
 && apt-get upgrade -y git \
 && git --version

RUN git config --global user.email "prvysoky@microsoft.com" \
 && git config --global user.name "Premek Vysoky"

RUN mkdir -p /work/repo \
 && mkdir -p /work/vmr/src

RUN cd /work/repo \
 && git init -b main \
 && echo "111" > A.txt \
 && git add -A \
 && git commit -m "A.txt set to 111"

RUN cd /work/vmr \
 && git init -b main \
 && echo "111" > src/A.txt \
 && git -C /work/repo rev-parse HEAD > last_sync \
 && git add -A \
 && git commit -m "A.txt set to 111"

COPY [ "scripts/tools.sh", "/work/tools.sh" ]

RUN cd /work/repo \
 && echo "222" > A.txt \
 && git commit -am "A.txt set to 222" \
 && echo "333" > A.txt \
 && git commit -am "A.txt set to 333"

WORKDIR /work

ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT 1
ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE true
