#!/bin/bash

export SENDMAIL_DEFINE_confRUN_AS_USER=${SENDMAIL_DEFINE_confRUN_AS_USER:-openshift:root}
export SENDMAIL_DEFINE_confDEF_USER_ID=${SENDMAIL_DEFINE_confDEF_USER_ID:-openshift:root}
export SENDMAIL_DEFINE_confPRIVACY_FLAGS=${SENDMAIL_DEFINE_confPRIVACY_FLAGS:-novrfy,noexpn,restrictqrun}
export SENDMAIL_DEFINE_confCT_FILE=/etc/mail/trusted-users

if [ -z "${SENDMAIL_RELAYHOST_USER}" ] && [ -z "${SENDMAIL_RELAYHOST_PASSWORD}" ]; then
    export SENDMAIL_RELAYHOST_AUTH=${SENDMAIL_RELAYHOST_AUTH:-PLAIN}
    export SENDMAIL_FEATURE_authinfo=true
    echo AuthInfo:${SENDMAIL_DEFINE_SMARTHOST} "U:${SENDMAIL_RELAYHOST_USER}" "P:${SENDMAIL_RELAYHOST_PASSWORD}" "M:${SENDMAIL_RELAYHOST_AUTH}" >> /etc/mail/authinfo
fi

while IFS='=' read -r name value ; do
    if [[ $name == 'SENDMAIL_'* ]]; then
        if [[ $name == 'SENDMAIL_DEFINE_'* ]]; then
            echo define\(\`${name/SENDMAIL_DEFINE_/}\', \`${!name}\'\)dnl >> /etc/mail/sendmail.mc
        elif [[ $name == 'SENDMAIL_FEATURE_'* ]]; then
            echo -e FEATURE\(\`${name/SENDMAIL_FEATURE_/}\'\)dnl"\n$(cat /etc/mail/sendmail.mc)" > /etc/mail/sendmail.mc
        fi
        unset ${name}
    fi
done < <(env)

echo "openshift:x:$(id -u):$(id -g)::/var/spool/mqueue:/sbin/nologin" >> /etc/passwd

/etc/mail/make

exec "$@"