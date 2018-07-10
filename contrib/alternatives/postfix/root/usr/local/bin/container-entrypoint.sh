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

PSEUDO_LIBDIR=/lib64 PSEUDO_PASSWD=/ PSEUDO_BINDIR=/usr/local/bin PSEUDO_LOCALSTATEDIR=/tmp PSEUDO_DEBUG=5 LD_PRELOAD="liblogfaf.so libpseudo.so" exec /tini -- "$@"