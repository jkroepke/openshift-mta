FROM centos:7

EXPOSE 25
# VOLUME /var/spool/mqueue/
ENTRYPOINT ["/entrypoint.sh"]

RUN yum install -y sendmail sendmail-cf patch && yum clean all && rm -rf /var/cache/yum \
    && setcap 'cap_net_bind_service=+ep' /usr/sbin/sendmail.sendmail

RUN sed -i "/.*EXPOSED_USER.*/d" /etc/mail/sendmail.mc && \
    sed -i "/.*accept_unresolvable_domains.*/d" /etc/mail/sendmail.mc && \
    sed -i "/.*local_procmail.*/d" /etc/mail/sendmail.mc && \
    sed -i "/.*Addr=127.0.0.1.*/d" /etc/mail/sendmail.mc && \
    chmod g+w -R /etc/mail/ /etc/passwd /usr/share/sendmail-cf/m4/proto.m4 && \
    chmod 777 -R /var/spool/mqueue && \
    chgrp 0 -R /var/spool/mqueue && \
    /etc/mail/make

CMD ["/usr/sbin/sendmail", "-bs", "-bD", "-v", "-d0.1"]

COPY root /