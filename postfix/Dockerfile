FROM centos:7 as build-libs
RUN yum install -y epel-release
RUN yum install -y libtool automake autoconf gcc file make git sqlite-devel
RUN git clone https://github.com/jkroepke/liblogfaf
RUN cd liblogfaf && autoreconf -i && ./configure && make && cd
RUN git clone git://git.yoctoproject.org/pseudo
RUN cd pseudo && ./configure --prefix=/usr/local --without-passwd-fallback --enable-memory-db --bits=64 && make && cd


FROM centos:7
EXPOSE 25
ENV TINI_VERSION=v0.17.0
#VOLUME ["/var/spool/postfix"]
CMD ["/usr/libexec/postfix/master", "-d"]
ENTRYPOINT ["/usr/local/bin/container-entrypoint.sh"]
COPY --from=build-libs /liblogfaf/src/.libs/liblogfaf.so.0.0.0 /lib64/liblogfaf.so
COPY --from=build-libs /pseudo/lib64/libpseudo.so /lib64/libpseudo.so
COPY --from=build-libs /pseudo/bin/ /usr/local/bin/

RUN curl -LJ https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -o /tini && \
    chmod +x /tini && \
    yum install -y postfix && \
    yum clean all && \
    rm -rf /var/cache/yum
RUN setcap 'cap_net_bind_service=+ep' /usr/libexec/postfix/master && \
    chmod u+s /lib64/liblogfaf.so /lib64/libpseudo.so && \
    postconf -e import_environment="$(postconf -d import_environment | cut -d ' ' -f3-) LD_PRELOAD LD_DEBUG FAKEROOTKEY FAKED_MODE PSEUDO_PREFIX PSEUDO_BINDIR PSEUDO_LOCALSTATEDIR PSEUDO_PASSWD PSEUDO_PREFIX PSEUDO_LIBDIR" && \
    postconf -e inet_interfaces=all && \
    newaliases && \
    cp -a /var/spool/postfix/ /var/spool/postfix.bak && \
    chgrp 0 -R /etc/postfix/ /var/spool/postfix/ /var/spool/postfix.bak/ /var/lib/postfix/ && \
    chmod g+rwX -R /etc/postfix/ /var/spool/postfix/ /var/spool/postfix.bak/ /var/lib/postfix/

ADD root /