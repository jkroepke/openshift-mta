#!/bin/bash

if [[ "${LIBLOGFAF_SENDTO}" == '/tmp/'* ]] && ! pgrep -x "tail" > /dev/null
then
    echo "tail is not running anymore. Stopping."
    exit 1
fi

if ! mailq > /dev/null
then
    echo "mailq not working anymore. Stopping."
    exit 1
fi

if ! timeout 2 ls ${SENDMAIL_DEFINE_QUEUE_DIR} > /dev/null
then
    echo "Can not read ${SENDMAIL_DEFINE_QUEUE_DIR}"
    exit 1
fi

exit 0