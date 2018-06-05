FROM        centos:7

EXPOSE      25
VOLUME      /var/spool/mqueue/
HEALTHCHECK CMD ["/healthcheck.sh"]
ENTRYPOINT  ["/entrypoint.sh"]
CMD         ["/usr/sbin/sendmail", "-bs", "-bD", "-qp", "-Am"]

ENV         SENDMAIL_FEATURE_no_default_msa=true \
            SENDMAIL_FEATURE_nouucp=nospecial \
            SENDMAIL_FEATURE_nocanonify=true \
            SENDMAIL_FEATURE_authinfo=true \
            SENDMAIL_DEFINE_QUEUE_DIR=/var/spool/mqueue \
            SENDMAIL_DEFINE_STATUS_FILE=/dev/null \
            SENDMAIL_DEFINE_ALIAS_FILE=/etc/mail/aliases \
            SENDMAIL_DEFINE_confLOG_LEVEL=9 \
            SENDMAIL_DEFINE_confCACERT=/etc/pki/tls/certs/ca-bundle.trust.crt \
            SENDMAIL_DEFINE_confPID_FILE=/tmp/sendmail.pid \
            SENDMAIL_DEFINE_confTRUSTED_USER=openshift \
            SENDMAIL_DEFINE_confRUN_AS_USER=openshift:root \
            SENDMAIL_DEFINE_confMIN_QUEUE_AGE=10 \
            SENDMAIL_DEFINE_confDONT_BLAME_SENDMAIL="`GroupReadableSASLDBFile,GroupWritableAliasFile,GroupReadableKeyFile,GroupWritableDirPathSafe'" \
            SENDMAIL_DEFINE_confSERVER_SSL_OPTIONS="+SSL_OP_NO_SSLv2 +SSL_OP_NO_SSLv3 +SSL_OP_CIPHER_SERVER_PREFERENCE" \
            SENDMAIL_DEFINE_confCLIENT_SSL_OPTIONS="+SSL_OP_NO_SSLv2 +SSL_OP_NO_SSLv3" \
            SENDMAIL_DEFINE_confCIPHER_LIST="HIGH:MEDIUM:!aNULL:!eNULL@STRENGTH" \
            SENDMAIL_DEFINE_confMAX_DAEMON_CHILDREN=20 \
            LIBLOGFAF_SENDTO=/tmp/log

COPY        root /

RUN         yum install -y patch sendmail sendmail-cf cyrus-sasl-plain cyrus-sasl-ntlm && yum clean all && rm -rf /var/cache/yum && \
            setcap 'cap_net_bind_service=+ep' /usr/sbin/sendmail.sendmail && \
            sed -i "/.*EXPOSED_USER.*/d" /etc/mail/sendmail.mc && \
            sed -i "/.*procmail.*/d" /etc/mail/sendmail.mc && \
            sed -i "/.*accept_unresolvable_domains.*/d" /etc/mail/sendmail.mc && \
            sed -i "/.*Addr=127.0.0.1.*/d" /etc/mail/sendmail.mc && \
            newaliases && \
            chmod g+w -R  /etc/aliases /etc/aliases.db /etc/mail/ /etc/passwd /usr/share/sendmail-cf/m4/proto.m4 && \
            chmod 777 -R /var/spool/mqueue && \
            chgrp 0 -R /etc/aliases /etc/aliases.db /var/spool/mqueue && \
            chmod u+s /lib64/liblogfaf.so

USER        1001
