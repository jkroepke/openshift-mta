#!/bin/bash

if ! pgrep -x "tail" > /dev/null
then
    echo "tail is not running anymore. Stopping."
    exit 1
fi

if ! timeout 2 cat <(echo MAIL) > /dev/tcp/localhost/25
then
    echo "Port 25 is not open."
    exit 1
fi

if ! timeout 2 ls ${SENDMAIL_DEFINE_QUEUE_DIR} > /dev/null
then
    echo "Can not read ${SENDMAIL_DEFINE_QUEUE_DIR}"
    exit 1
fi

exit 0