FROM centos:7 as build-liblogfaf
RUN yum install -y epel-release
RUN yum install -y libtool automake autoconf gcc file make git
RUN git clone https://github.com/jkroepke/liblogfaf
RUN cd liblogfaf &&  autoreconf -i && ./configure && make

FROM centos:7
EXPOSE 25
ENV TINI_VERSION v0.17.0
#VOLUME ["/var/spool/postfix"]
CMD ["/usr/libexec/postfix/master", "-d"]
ENTRYPOINT ["/usr/local/bin/container-entrypoint.sh"]
COPY --from=build-liblogfaf /liblogfaf/src/.libs/liblogfaf.so.0.0.0 /lib64/liblogfaf.so
RUN yum install -y strace
RUN setcap 'cap_net_bind_service=+ep' /usr/bin/strace
RUN chmod u+s /usr/bin/strace

RUN curl -LJ https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -o /tini && \
    chmod +x /tini && \
    yum install -y epel-release && \
    yum install -y postfix fakeroot && \
    yum clean all && \
    rm -rf /var/cache/yum
RUN echo liblogfaf.so > /etc/ld.so.preload && \
    setcap 'cap_net_bind_service=+ep' /usr/libexec/postfix/master && \
    ln -s /usr/lib64/libfakeroot/libfakeroot-tcp.so /lib64/ && \
    chmod u+s /lib64/liblogfaf.so /lib64/libfakeroot-*.so && \
    postconf -e import_environment="$(postconf -d import_environment | cut -d ' ' -f3-) LD_PRELOAD LD_DEBUG FAKEROOTKEY FAKED_MODE" && \
    postconf -e inet_interfaces=all && \
    newaliases && \
    cp -a /var/spool/postfix/ /var/spool/postfix.bak && \
    chgrp 0 -R /etc/passwd /etc/postfix/ /var/spool/postfix/ /var/spool/postfix.bak/ /var/lib/postfix/ && \
    chmod g+rwX -R /etc/passwd /etc/postfix/ /var/spool/postfix/ /var/spool/postfix.bak/ /var/lib/postfix/


ADD root /