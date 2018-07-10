#!/bin/bash

echo openshift:x:$(id -u):$(id -g)::/var/spool/exim:/sbin/nologin >> /etc/passwd

exec "$@"