FROM centos:7
# RUN yum install -y epel-release
RUN yum install -y libtool automake autoconf unzip file make
ADD https://github.com/jkroepke/liblogfaf/archive/master.zip .
RUN unzip master.zip && cd liblogfaf-master && autoreconf -i && ./configure && make
RUN ls /liblogfaf-master/src/.libs/liblogfaf.so.0.0.0