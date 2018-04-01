FROM        centos:7

COPY        root .

RUN         yum install epel-release -y \
            && yum install exim gettext -y \
            && yum clean all \
            && rm -rf /var/cache/yum \
            && chmod +x /docker-entrypoint.sh

ENTRYPOINT  ["/docker-entrypoint.sh"]
CMD         ["/usr/sbin/exim"]