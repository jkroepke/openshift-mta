#!/bin/bash

set -euo pipefail

if [ -n "${ENTRYPOINT_DEBUG+x}" ]; then
    set -x
fi

SENDMAIL_DEFINE_confCACERT=$(readlink -f "${SENDMAIL_DEFINE_confCACERT}")
SENDMAIL_DEFINE_confCACERT_PATH=${SENDMAIL_DEFINE_confCACERT_PATH:-${SENDMAIL_DEFINE_confCACERT%%${SENDMAIL_DEFINE_confCACERT##*/}}}

export SENDMAIL_DEFINE_confCACERT
export SENDMAIL_DEFINE_confCACERT_PATH

cp /etc/aliases /etc/mail/aliases
touch /etc/mail/access /etc/mail/authinfo

# Set custom port for relay host
if [ -n "${SENDMAIL_DEFINE_SMART_HOST+x}" ] && [[ "${SENDMAIL_DEFINE_SMART_HOST}" == *':'* ]]; then
    SENDMAIL_DEFINE_RELAY_MAILER_ARGS="TCP \$h ${SENDMAIL_DEFINE_SMART_HOST#*:}"
    SENDMAIL_DEFINE_SMART_HOST="${SENDMAIL_DEFINE_SMART_HOST%:*}";

    export SENDMAIL_DEFINE_RELAY_MAILER_ARGS
    export SENDMAIL_DEFINE_SMART_HOST
fi

# Add authentication for relay hosts
if [ -n "${SENDMAIL_DEFINE_SMART_HOST+x}" ] && [ -n "${SENDMAIL_SMART_HOST_USER+x}" ] && [ -n "${SENDMAIL_SMART_HOST_PASSWORD+x}" ]; then
    # http://www.sendmail.org/~ca/email/sm-812.html#812AUTH
    printf 'AuthInfo: "U:%s" "P:%s"\n' "${SENDMAIL_SMART_HOST_USER}" "${SENDMAIL_SMART_HOST_PASSWORD}" >> /etc/mail/authinfo
fi

# Override sendmails access files.
if [ -n "${SENDMAIL_FORCE_TLS_VERIFY+x}" ] && [ "${SENDMAIL_FORCE_TLS_VERIFY}" == "true" ]; then
    SENDMAIL_ACCESS="${SENDMAIL_ACCESS:-}\\nTLS_Srv VERIFY+CN\\n"
    export SENDMAIL_ACCESS
fi

# Override sendmails access files.
if [ -n "${SENDMAIL_ACCESS+x}" ]; then
    echo -e "${SENDMAIL_ACCESS}" > /etc/mail/access
fi

# Configure credentials
if [ -n "${SENDMAIL_AUTH_USER+x}" ] && [ -n "${SENDMAIL_AUTH_PASSWORD+x}" ]; then
    echo "${SENDMAIL_AUTH_PASSWORD}" | saslpasswd2 -f /etc/mail/sasldb2 -p -c "${SENDMAIL_AUTH_USER}"

    SENDMAIL_LISTEN_MODIFIER="${SENDMAIL_LISTEN_MODIFIER}a"
fi

if [ -n "${SENDMAIL_DEFINE_confAUTH_MECHANISMS+x}" ]; then
    SENDMAIL_RAW_APPEND="TRUST_AUTH_MECH(\`${SENDMAIL_DEFINE_confAUTH_MECHANISMS}')dnl\n${SENDMAIL_RAW_APPEND:-}"
fi

if [ -n "${SENDMAIL_CLIENT_OPTIONS+x}" ]; then
    SENDMAIL_RAW_APPEND="CLIENT_OPTIONS(\`${SENDMAIL_CLIENT_OPTIONS}')dnl\n${SENDMAIL_RAW_APPEND:-}"
fi

# Disable check for lookup sender IP. Require for kubernetes based environments
if [ -n "${SENDMAIL_DISABLE_SENDER_RDNS+x}" ] && [ "${SENDMAIL_DISABLE_SENDER_RDNS}" == "true" ]; then
    echo "Disable rDNS for senders..."
    cp /usr/share/sendmail-cf/m4/proto.m4 /tmp
    patch -s /tmp/proto.m4 < /usr/local/src/remove-sender-lookup-check.patch
    cp /tmp/proto.m4 /usr/share/sendmail-cf/m4/proto.m4
    rm /tmp/proto.m4
fi

# Listen on specific address
if [ -n "${SENDMAIL_LISTEN+x}" ]; then
    echo "DAEMON_OPTIONS(\`Port=smtp, Name=MTA, Addr=${SENDMAIL_LISTEN}, M=${SENDMAIL_LISTEN_MODIFIER}')dnl" >> /etc/mail/sendmail.mc
else
    echo "DAEMON_OPTIONS(\`Port=smtp, Name=MTA, M=${SENDMAIL_LISTEN_MODIFIER}')dnl" >> /etc/mail/sendmail.mc
fi

# Use TZ env
if [ -n "${TZ+x}" ]; then
    SENDMAIL_DEFINE_confTIME_ZONE=USE_TZ
    export SENDMAIL_DEFINE_confTIME_ZONE
fi

if [ -n "${SENDMAIL_DROP_BOUNCE_MAILS+x}" ] && [ "${SENDMAIL_DROP_BOUNCE_MAILS}" == "true" ]; then
    echo '| /dev/null' > /tmp/.forward

    SENDMAIL_DEFINE_LUSER_RELAY=local:openshift
    export SENDMAIL_DEFINE_LUSER_RELAY
fi

# Define root alias
if [ -n "${SENDMAIL_ROOT_ALIAS+x}" ]; then
    echo -e "root:\\t${SENDMAIL_ROOT_ALIAS}" >> /etc/mail/aliases
fi

# Enable debug
if [ -n "${SENDMAIL_DEBUG+x}" ] && [ "${SENDMAIL_DEBUG}" == "true" ]; then
    set -- "$@" "-d" "-X" "/proc/self/fd/1"
else
    # SENDMAIL: WARNING: Can not use -d with -q.  Disabling debugging.
    set -- "$@" "-qp"

    # Queue interval
    if [ -n "${SENDMAIL_QUEUE_INTERVAL+x}" ]; then
        set -- "$@" "-q" "${SENDMAIL_QUEUE_INTERVAL}"
    fi
fi

# Force receiver address
if [ -n "${SENDMAIL_FORCE_SENDER_ADDRESS+x}" ]; then
    # http://www.harker.com/sendmail/rules-overview.html
    SENDMAIL_RAW_APPEND=$(cat <<EOF
${SENDMAIL_RAW_APPEND:-}\\n
LOCAL_RULE_1
R \$+@\$+\\t\$@ ${SENDMAIL_FORCE_SENDER_ADDRESS%%@*} < @ ${SENDMAIL_FORCE_SENDER_ADDRESS##*@}. >
EOF
)

    export SENDMAIL_RAW_APPEND
fi

# Force receiver address
if [ -n "${SENDMAIL_FORCE_RECEIVER_ADDRESS+x}" ]; then
    # https://serverfault.com/questions/356160/configure-sendmail-to-only-send-to-local-domain
    export SENDMAIL_RAW_APPEND=$(cat <<EOF
${SENDMAIL_RAW_APPEND:-}\\n
LOCAL_RULE_0
R\$* < \$*. > \$*\\t\$: ${SENDMAIL_FORCE_RECEIVER_ADDRESS%%@*} < @ ${SENDMAIL_FORCE_RECEIVER_ADDRESS##*@}. > \$3
EOF
)

    export SENDMAIL_RAW_APPEND
fi

if [ -n "${SENDMAIL_RAW_PREPEND+x}" ]; then
    sed -i "s/MAILER(smtp)dnl/FEATURE(\`${SENDMAIL_RAW_PREPEND}')dnl\\nMAILER(smtp)dnl/" /etc/mail/sendmail.mc
fi

# OpenSSL Options are available in 8.15.1 or later
if [ -n "${SENDMAIL_DEFINE_confSERVER_SSL_OPTIONS+x}" ]; then
    SENDMAIL_LOCAL_CONFIG="${SENDMAIL_LOCAL_CONFIG:-}\\nO ServerSSLOptions=${SENDMAIL_DEFINE_confSERVER_SSL_OPTIONS}"

    export SENDMAIL_LOCAL_CONFIG
    unset SENDMAIL_DEFINE_confSERVER_SSL_OPTIONS
fi

if [ -n "${SENDMAIL_DEFINE_confCLIENT_SSL_OPTIONS+x}" ]; then
    SENDMAIL_LOCAL_CONFIG="${SENDMAIL_LOCAL_CONFIG:-}\\nO ClientSSLOptions=${SENDMAIL_DEFINE_confCLIENT_SSL_OPTIONS}"

    export SENDMAIL_LOCAL_CONFIG
    unset SENDMAIL_DEFINE_confCLIENT_SSL_OPTIONS
fi

if [ -n "${SENDMAIL_DEFINE_confCIPHER_LIST+x}" ]; then
    SENDMAIL_LOCAL_CONFIG="${SENDMAIL_LOCAL_CONFIG:-}\\nO CipherList=${SENDMAIL_DEFINE_confCIPHER_LIST}"

    export SENDMAIL_LOCAL_CONFIG
    unset SENDMAIL_DEFINE_confCIPHER_LIST
fi

if [ -n "${SENDMAIL_LOCAL_CONFIG+x}" ]; then
    SENDMAIL_RAW_APPEND="${SENDMAIL_RAW_APPEND:-}\\n\\nLOCAL_CONFIG\\n${SENDMAIL_LOCAL_CONFIG}"
    export SENDMAIL_RAW_APPEND
fi

# Save SENDMAIL_RAW_APPEND because the loop will remove all SENDMAIL_ envs
if [ -n "${SENDMAIL_RAW_APPEND+x}" ]; then
    _RAW_APPEND="${SENDMAIL_RAW_APPEND}"
fi

if [ -n "${SENDMAIL_EXCLUDE_LOG_PATTERN+x}" ]; then
    _EXCLUDE_LOG_PATTERN="${SENDMAIL_EXCLUDE_LOG_PATTERN}"
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

if [ -n "${_RAW_APPEND+x}" ]; then
    echo -e "${_RAW_APPEND}" >> /etc/mail/sendmail.mc
    unset _RAW_APPEND
fi

# From https://docs.openshift.com/container-platform/3.9/creating_images/guidelines.html#use-uid
if ! whoami &> /dev/null; then
    if [ -w /etc/passwd ]; then
        echo "${USER_NAME:-openshift}:x:$(id -u):0:${USER_NAME:-openshift}:/tmp:/sbin/nologin" >> /etc/passwd
    fi
fi

if [ -n "${ENTRYPOINT_DEBUG+x}" ]; then
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
    if [ -n "${_EXCLUDE_LOG_PATTERN+x}" ]; then
        tail --pid=1 -f "${LIBLOGFAF_SENDTO}" | grep -E -v "${_EXCLUDE_LOG_PATTERN}" &

        unset _EXCLUDE_LOG_PATTERN
    else
        tail --pid=1 -f "${LIBLOGFAF_SENDTO}" &
    fi
fi

LD_PRELOAD="${LD_PRELOAD:-liblogfaf.so}" exec "$@"
