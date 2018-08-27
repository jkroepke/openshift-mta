#!/bin/bash

set -e
if [ ! -z "${ENTRYPOINT_DEBUG}" ]; then
    set -x
fi

export SENDMAIL_DEFINE_confCACERT_PATH=${SENDMAIL_DEFINE_confCACERT_PATH:-${SENDMAIL_DEFINE_confCACERT%%${SENDMAIL_DEFINE_confCACERT##*/}}}


cp /etc/aliases /etc/mail/aliases
touch /etc/mail/authinfo

# Set custom port for relay host
if [ ! -z "${SENDMAIL_DEFINE_SMART_HOST}" ] && [[ "${SENDMAIL_DEFINE_SMART_HOST}" == *':'* ]]; then
    export SENDMAIL_DEFINE_RELAY_MAILER_ARGS="TCP \$h ${SENDMAIL_DEFINE_SMART_HOST#*:}"
    export SENDMAIL_DEFINE_SMART_HOST="${SENDMAIL_DEFINE_SMART_HOST%:*}";
fi

# Add authentication for relay hosts
if [ ! -z "${SENDMAIL_DEFINE_SMART_HOST}" ] && [ ! -z "${SENDMAIL_SMART_HOST_USER}" ] && [ ! -z "${SENDMAIL_SMART_HOST_PASSWORD}" ]; then
    echo "Setting AuthInfo for relayhost '${SENDMAIL_DEFINE_SMART_HOST}'"
    export SENDMAIL_SMART_HOST_AUTH=${SENDMAIL_SMART_HOST_AUTH:-PLAIN}
    printf 'AuthInfo:%s "U:%s" "P:%s" "M:%s"' "${SENDMAIL_DEFINE_SMART_HOST}" "${SENDMAIL_SMART_HOST_USER}" "${SENDMAIL_SMART_HOST_PASSWORD}" "${SENDMAIL_SMART_HOST_AUTH}" >> /etc/mail/authinfo
fi

# Override sendmails access files.
if [ ! -z "${SENDMAIL_FORCE_TLS_VERIFY}" ] && [ "${SENDMAIL_FORCE_TLS_VERIFY}" == "true" ]; then
    export SENDMAIL_ACCESS="${SENDMAIL_ACCESS}\\nTLS_Srv VERIFY+CN\\n"
fi

# Override sendmails access files.
if [ ! -z "${SENDMAIL_ACCESS}" ]; then
    echo -e "${SENDMAIL_ACCESS}" > /etc/mail/access
fi

# Disable check for lookup sender IP. Require for kubernetes based environments
if [ ! -z "${SENDMAIL_DISABLE_SENDER_RDNS}" ] && [ "${SENDMAIL_DISABLE_SENDER_RDNS}" == "true" ]; then
    echo "Disable rDNS for senders..."
    cp /usr/share/sendmail-cf/m4/proto.m4 /tmp
    patch -s /tmp/proto.m4 < /usr/local/src/remove-sender-lookup-check.patch
    cp /tmp/proto.m4 /usr/share/sendmail-cf/m4/proto.m4
    rm /tmp/proto.m4
fi

# Listen on specific address
if [ ! -z "${SENDMAIL_LISTEN}" ]; then
    echo "DAEMON_OPTIONS(\`Port=smtp, Name=MTA, Addr=${SENDMAIL_LISTEN}')dnl" >> /etc/mail/sendmail.mc
else
    echo "DAEMON_OPTIONS(\`Port=smtp, Name=MTA')dnl" >> /etc/mail/sendmail.mc
fi

# Use TZ env
if [ ! -z "${TZ}" ]; then
  export SENDMAIL_DEFINE_confTIME_ZONE=USE_TZ
fi

# TODO: Drop bounces
if [ ! -z "${SENDMAIL_DROP_BOUNCE_MAILS}" ] && [ "${SENDMAIL_DROP_BOUNCE_MAILS}" == "true" ]; then
    echo '| /dev/null' > /tmp/.forward
    export SENDMAIL_DEFINE_LUSER_RELAY=local:openshift
fi

# Define root alias
if [ ! -z "${SENDMAIL_ROOT_ALIAS}" ]; then
    echo -e "root:\\t${SENDMAIL_ROOT_ALIAS}" >> /etc/mail/aliases
fi

# Queue interval
if [ ! -z "${SENDMAIL_QUEUE_INTERVAL}" ]; then
    set -- "$@" "-q" "${SENDMAIL_QUEUE_INTERVAL}"
fi

# Enable debug
if [ ! -z "${SENDMAIL_DEBUG}" ] && [ "${SENDMAIL_DEBUG}" == "true" ]; then
    set -- "$@" "-d" "-X" "/proc/self/fd/1"
fi

# Force receiver address
if [ ! -z "${SENDMAIL_FORCE_SENDER_ADDRESS}" ]; then
    # http://www.harker.com/sendmail/rules-overview.html
    export SENDMAIL_RAW_APPEND=$(cat <<EOF
${SENDMAIL_RAW_APPEND}\\n
LOCAL_RULE_1
R \$+@\$+\\t\$@ ${SENDMAIL_FORCE_RECEIVER_ADDRESS%%@*} < @ ${SENDMAIL_FORCE_RECEIVER_ADDRESS##*@}. >
EOF
)
fi

# Force receiver address
if [ ! -z "${SENDMAIL_FORCE_RECEIVER_ADDRESS}" ]; then
    # https://serverfault.com/questions/356160/configure-sendmail-to-only-send-to-local-domain
    export SENDMAIL_RAW_APPEND=$(cat <<EOF
${SENDMAIL_RAW_APPEND}\\n
LOCAL_RULE_0
R\$* < \$*. > \$*\\t\$: ${SENDMAIL_FORCE_RECEIVER_ADDRESS%%@*} < @ ${SENDMAIL_FORCE_RECEIVER_ADDRESS##*@}. > \$3
EOF
)
fi

if [ ! -z "${SENDMAIL_RAW_PREPEND}" ]; then
    sed -i "s/MAILER(smtp)dnl/FEATURE(\`${SENDMAIL_RAW_PREPEND}')dnl\\nMAILER(smtp)dnl/" /etc/mail/sendmail.mc
fi

# OpenSSL Options are available in 8.15.1 or later
if [ ! -z "${SENDMAIL_DEFINE_confSERVER_SSL_OPTIONS}" ]; then
    export SENDMAIL_LOCAL_CONFIG="${SENDMAIL_LOCAL_CONFIG}\\nO ServerSSLOptions=${SENDMAIL_DEFINE_confSERVER_SSL_OPTIONS}"
    unset SENDMAIL_DEFINE_confSERVER_SSL_OPTIONS
fi

if [ ! -z "${SENDMAIL_DEFINE_confCLIENT_SSL_OPTIONS}" ]; then
    export SENDMAIL_LOCAL_CONFIG="${SENDMAIL_LOCAL_CONFIG}\\nO ClientSSLOptions=${SENDMAIL_DEFINE_confCLIENT_SSL_OPTIONS}"
    unset SENDMAIL_DEFINE_confCLIENT_SSL_OPTIONS
fi

if [ ! -z "${SENDMAIL_DEFINE_confCIPHER_LIST}" ]; then
    export SENDMAIL_LOCAL_CONFIG="${SENDMAIL_LOCAL_CONFIG}\\nO CipherList=${SENDMAIL_DEFINE_confCIPHER_LIST}"
    unset SENDMAIL_DEFINE_confCIPHER_LIST
fi

if [ ! -z "${SENDMAIL_LOCAL_CONFIG}" ]; then
    export SENDMAIL_RAW_APPEND="${SENDMAIL_RAW_APPEND}\\n\\nLOCAL_CONFIG\\n${SENDMAIL_LOCAL_CONFIG}"
fi

# Save SENDMAIL_RAW_APPEND because the loop will remove all SENDMAIL_ envs
if [ ! -z "${SENDMAIL_RAW_APPEND}" ]; then
    export _RAW_APPEND="${SENDMAIL_RAW_APPEND}"
fi

if [ ! -z "${SENDMAIL_EXCLUDE_LOG_PATTERN}" ]; then
    export _EXCLUDE_LOG_PATTERN="${SENDMAIL_EXCLUDE_LOG_PATTERN}"
fi

# https://stackoverflow.com/a/25765360
# Configure sendmail from environments
while IFS='=' read -r name value ; do
    if [[ $name == 'SENDMAIL_'* ]]; then
        if [[ $name == 'SENDMAIL_DEFINE_'* ]]; then
            sed -i "s/MAILER(smtp)dnl/define(\`${name/SENDMAIL_DEFINE_/}', \`${value//\//\\/}')dnl\\nMAILER(smtp)dnl/" /etc/mail/sendmail.mc
        elif [[ $name == 'SENDMAIL_FEATURE_'* ]]; then
            if [[ "${value}" == "true" ]]; then
                sed -i "s/MAILER(smtp)dnl/FEATURE(\`${name/SENDMAIL_FEATURE_/}')dnl\\nMAILER(smtp)dnl/" /etc/mail/sendmail.mc
            else
                sed -i "s/MAILER(smtp)dnl/FEATURE(\`${name/SENDMAIL_FEATURE_/}', \`${value//\//\\/}')dnl\\nMAILER(smtp)dnl/" /etc/mail/sendmail.mc
            fi
        fi
        unset "${name}"
    fi
done < <(env)

if [ ! -z "${_RAW_APPEND}" ]; then
    echo -e "${_RAW_APPEND}" >> /etc/mail/sendmail.mc
    unset _RAW_APPEND
fi

# From https://docs.openshift.com/container-platform/3.9/creating_images/guidelines.html#use-uid
if ! whoami &> /dev/null; then
    if [ -w /etc/passwd ]; then
        echo "${USER_NAME:-openshift}:x:$(id -u):0:${USER_NAME:-openshift}:/tmp:/sbin/nologin" >> /etc/passwd
    fi
fi

if [ ! -z "${ENTRYPOINT_DEBUG}" ]; then
    cat /etc/mail/sendmail.mc
fi

# prevent error:
# makemap: error opening type hash map *.db: File changed after open
rm -f /etc/mail/*.db
/etc/mail/make

# newaliases need an existing file.?
touch /etc/mail/aliases.db
/usr/bin/newaliases

# Setup log environment (missing /dev/console on openshift containers)
if [[ "${LIBLOGFAF_SENDTO}" == '/tmp/'* ]]; then
    mkfifo "${LIBLOGFAF_SENDTO}"
    if [ ! -z "${_EXCLUDE_LOG_PATTERN}" ]; then
        tail --pid=1 -f "${LIBLOGFAF_SENDTO}" | egrep -v "${_EXCLUDE_LOG_PATTERN}" &

        unset _EXCLUDE_LOG_PATTERN
    else
        tail --pid=1 -f "${LIBLOGFAF_SENDTO}" &
    fi
fi

LD_PRELOAD="/lib64/liblogfaf.so" exec "$@"
