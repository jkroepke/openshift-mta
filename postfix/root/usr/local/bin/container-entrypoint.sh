#!/bin/bash
umask 000

if [ ! -d /var/spool/postfix/pid/ ]; then
    cp -a /var/spool/postfix.bak/* /var/spool/postfix/
    chmod -R 777 /var/spool/postfix/*
fi

while IFS='=' read -r name value ; do
  if [[ $name == 'POSTFIX_'* ]]; then
    echo "$name" ${!name}
  fi
done < <(env)

echo openshift:x:$UID:$UID::/var/spool/postfix:/sbin/nologin >> /etc/passwd
echo mail_owner=openshift >> /etc/postfix/main.cf

LD_PRELOAD="liblogfaf.so" exec /tini -- fakeroot "$@"