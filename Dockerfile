FROM        centos:8

EXPOSE      25
VOLUME      /var/spool/mqueue/ /var/spool/clientmqueue
ENTRYPOINT  ["/entrypoint.sh"]
CMD         ["/usr/sbin/sendmail", "-bs", "-bD", "-Am"]

ENV         SENDMAIL_FEATURE_nouucp=nospecial \
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
            SENDMAIL_DEFINE_confREFUSE_LA=0 \
            SENDMAIL_DEFINE_confQUEUE_LA=0 \
            SENDMAIL_DEFINE_confDONT_BLAME_SENDMAIL="`GroupReadableSASLDBFile,GroupWritableAliasFile,GroupReadableKeyFile,GroupWritableDirPathSafe'" \
            SENDMAIL_DEFINE_confSERVER_SSL_OPTIONS="+SSL_OP_NO_SSLv2 +SSL_OP_NO_SSLv3 +SSL_OP_CIPHER_SERVER_PREFERENCE" \
            SENDMAIL_DEFINE_confCLIENT_SSL_OPTIONS="+SSL_OP_NO_SSLv2 +SSL_OP_NO_SSLv3" \
            SENDMAIL_DEFINE_confCIPHER_LIST="HIGH:MEDIUM:!aNULL:!eNULL@STRENGTH" \
            SENDMAIL_DEFINE_confAUTH_MECHANISMS="LOGIN PLAIN CRAM-MD5 DIGEST-MD5 NTLM" \
            SENDMAIL_DEFINE_confPRIVACY_FLAGS=needmailhelo \
            SENDMAIL_FORCE_TLS_VERIFY=true \
            SENDMAIL_CLIENT_OPTIONS="Family=inet" \
            SENDMAIL_LISTEN_MODIFIER="CE" \
            SENDMAIL_ROOT_ALIAS=/dev/null \
            SENDMAIL_ACCESS="Connect:10 RELAY\nConnect:127 RELAY\nConnect:172 RELAY\nConnect:192.168 RELAY" \
            LIBLOGFAF_SENDTO=/dev/tty

RUN         set -euo pipefail \
            && yum install --nodocs -y patch sendmail sendmail-cf cyrus-sasl-plain cyrus-sasl-ntlm cyrus-sasl-md5 && yum clean all && rm -rf /var/cache/yum \
            && setcap 'cap_net_bind_service=+ep' /usr/sbin/sendmail.sendmail \
            && sed -i "/.*EXPOSED_USER.*/d" /etc/mail/sendmail.mc \
            && sed -i "/.*procmail.*/d" /etc/mail/sendmail.mc \
            && sed -i "/.*accept_unresolvable_domains.*/d" /etc/mail/sendmail.mc \
            && sed -i "/.*Addr=127.0.0.1.*/d" /etc/mail/sendmail.mc \
            && newaliases \
            && printf 'pwcheck_method: auxprop\nauxprop_plugin: sasldb\nsasldb_path: /etc/mail/sasldb2\nmech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5 NTLM' > /etc/sasl2/Sendmail.conf \
            && echo NOOP | saslpasswd2 -c -p NOOP && saslpasswd2 -d NOOP \
            && chgrp 0   -R /etc/pki/tls/private/sendmail.key /var/spool/clientmqueue /var/spool/mqueue /etc/sasldb2 /etc/aliases /etc/aliases.db \
            && chmod g=u -R /etc/pki/tls/private/sendmail.key /var/spool/clientmqueue /var/spool/mqueue /etc/sasldb2 /etc/aliases /etc/aliases.db /etc/mail/ /etc/passwd /usr/share/sendmail-cf/m4/proto.m4

COPY        root /

RUN         chmod u+s    /lib64/liblogfaf.so

USER        1001
