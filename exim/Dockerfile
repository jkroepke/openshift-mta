FROM        centos:7

RUN         yum install epel-release -y \
            && yum install exim gettext -y \
            && yum clean all \
            && rm -rf /var/cache/yum \
            && chmod g+w /etc/passwd \
            && setcap 'cap_net_bind_service=+ep' /usr/sbin/exim

COPY        root .

ENTRYPOINT  ["/docker-entrypoint.sh"]
CMD         ["/usr/sbin/exim", "-bdf", "-v"]