# Version 0.0.1
FROM ubuntu:18.10

# base tools
RUN apt-get update
RUN apt-get install -y \
   unzip \
   build-essential \
   wget \
   g++ \
   git \
   subversion \
   automake \
   libtool \
   zlib1g-dev \
   libboost-all-dev \
   libbz2-dev \
   liblzma-dev \
   python-dev \
   libgoogle-perftools-dev \
   libxmlrpc-core-c3-dev \
   libxmlrpc-c++8-dev \
   cmake 

RUN mkdir -p /home/moses
WORKDIR /home/moses
RUN mkdir moses-smt
RUN mkdir moses-models

WORKDIR /home/moses
RUN wget http://downloads.sourceforge.net/project/boost/boost/1.55.0/boost_1_55_0.tar.gz
RUN tar zxvf boost_1_55_0.tar.gz
WORKDIR /home/moses/boost_1_55_0
RUN ./bootstrap.sh
RUN ./b2 -j8 --prefix=$PWD --libdir=$PWD/lib64 --layout=system link=static install || echo FAILURE

WORKDIR /home/moses
RUN wget -O /home/moses/RELEASE-4.0.zip https://github.com/moses-smt/mosesdecoder/archive/RELEASE-4.0.zip
RUN unzip /home/moses/RELEASE-4.0.zip
RUN rm RELEASE-4.0.zip
RUN mv mosesdecoder-RELEASE-4.0 mosesdecoder

WORKDIR /home/moses
RUN wget -O giza-pp.zip "http://github.com/moses-smt/giza-pp/archive/master.zip" 
RUN unzip giza-pp.zip
RUN rm giza-pp.zip
RUN mv giza-pp-master giza-pp
WORKDIR /home/moses/giza-pp
RUN make

WORKDIR /home/moses
RUN wget -O fast_align.zip "https://github.com/clab/fast_align/archive/master.zip"
RUN unzip fast_align.zip
RUN rm fast_align.zip
RUN mv fast_align-master fast_align
WORKDIR /home/moses/fast_align
RUN cmake .
RUN make

RUN wget -O wikipedia-parallel-titles.zip "https://github.com/clab/wikipedia-parallel-titles/archive/master.zip"
RUN unzip wikipedia-parallel-titles.zip
RUN rm wikipedia-parallel-titles.zip
RUN mv wikipedia-parallel-titles-master wikipedia-parallel-titles

WORKDIR /home/moses/
RUN mkdir -p mosesdecoder/tools
RUN cp giza-pp/GIZA++-v2/GIZA++ mosesdecoder/tools
RUN cp giza-pp/GIZA++-v2/snt2cooc.out mosesdecoder/tools
RUN cp giza-pp/mkcls-v2/mkcls mosesdecoder/tools

WORKDIR /home/moses/
RUN wget -O cmph-2.0.tar.gz "http://downloads.sourceforge.net/project/cmph/cmph/cmph-2.0.tar.gz?r=&ts=1426574097&use_mirror=cznic"
RUN tar zxvf cmph-2.0.tar.gz

WORKDIR /home/moses/cmph-2.0
RUN ./configure
RUN make
RUN make install

WORKDIR /home/moses/mosesdecoder
RUN ./bjam --with-boost=/home/moses/boost_1_55_0 --with-cmph=/usr/local/cmph -j8 --with-xmlrpc-c=/usr
