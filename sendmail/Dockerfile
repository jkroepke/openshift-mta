FROM centos:7

EXPOSE 25
# VOLUME /var/spool/mqueue/
CMD ["/usr/sbin/sendmail", "-bs", "-bD", "-n", "-v", "-d"]
# /usr/sbin/sendmail -bs -bD -n -v -d
ENTRYPOINT ["/entrypoint.sh"]

RUN yum install -y sendmail sendmail-cf && yum clean all && rm -rf /var/cache/yum \
    && setcap 'cap_net_bind_service=+ep' /usr/sbin/sendmail.sendmail

RUN echo "Connect:10 RELAY" >> /etc/mail/access && \
    echo openshift >> /etc/mail/trusted-users && \
    echo DAEMON_OPTIONS\(\`Port=smtp, Name=MTA\'\)dnl  >> /etc/mail/sendmail.mc && \
    sed -i "/.*EXPOSED_USER.*/d" /etc/mail/sendmail.mc && \
    sed -i "/.*accept_unresolvable_domains.*/d" /etc/mail/sendmail.mc && \
    sed -i "/.*local_procmail.*/d" /etc/mail/sendmail.mc && \
    chmod g+w -R /etc/mail/ /etc/passwd && \
    chmod 770 -R /var/spool/mqueue && \
    chgrp 0 -R /var/spool/mqueue && \
    /etc/mail/make

COPY root /