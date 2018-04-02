[![Docker Pulls](https://img.shields.io/docker/pulls/jkroepke/openshift-mta.svg)](https://hub.docker.com/r/jkroepke/openshift-mta/) [![Docker Stars](https://img.shields.io/docker/stars/jkroepke/openshift-mta.svg)](https://hub.docker.com/r/jkroepke/openshift-mta/)

# openshift-mta
MTA in a docker primary designed for Red Hat's secure Openshift environment.

This MTA based on the __*powerful, efficient, and scalable Mail Transport Agent*__ sendmail. 🎉

# Variants
I'm currently testing some other variants like postfix, exim and some other ugly MTAs.

You can find the current status here: https://github.com/jkroepke/openshift-mta/blob/master/VARIANTS.md

# Configuration

## Volumes
| Name | Path |
| ---- | ----- |
| persistent sendmail queue | `/var/spool/mqueue/`

## Environment Variables

### Generic Variables

| Name | Results in ... |
| ---- | ----- |
| `SENDMAIL_FEATURE_*` | ``FEATURE\(\`$name'\)dnl`` on sendmail.mc |
| `SENDMAIL_DEFINE_*` | ``define(\`$name', \`$value')dnl`` on sendmail.mc |
| `SENDMAIL_DROP_BOUNCE_MAILS` | Drop bounce mails |
| `SENDMAIL_LISTEN` | Force sendmail to listen on specific address |
| `SENDMAIL_DISABLE_SENDER_RDNS` | Remove sender ip lookup. Required on container based environments |
| `SENDMAIL_ACCESS` | Additional sendmail access.db setting |
| `SENDMAIL_RELAYHOST_USER` | Relayhost authentification user |
| `SENDMAIL_RELAYHOST_PASSWORD` | Relayhost authentification password |
| `SENDMAIL_RELAYHOST_AUTH` | Relayhost authentification method. Defaults to: `PLAIN` |

### Default settings
| Name | Value |
| ---- | ----- |
| `SENDMAIL_FEATURE_promiscuous_relay` | true |
| `SENDMAIL_DEFINE_confLOG_LEVEL` | 9 |
| `SENDMAIL_DEFINE_confCACERT_PATH` | /etc/pki/tls/certs |
| `SENDMAIL_DEFINE_confPID_FILE` | /tmp/sendmail.pid |
| `SENDMAIL_DEFINE_STATUS_FILE` | /var/spool/mqueue/statistics |
| `SENDMAIL_DEFINE_confDONT_BLAME_SENDMAIL` | `GroupReadableKeyFile,GroupWritableDirPathSafe' |


### Advanced Variables

| Name | Results in ... |
| ---- | ----- |
| `SENDMAIL_DEBUG` | Enable debug in sendmail |
| `LIBLOGFAF_SENDTO` | Pipe all log from syslog to `LIBLOGFAF_SENDTO` |

# liblogfaf
This is a smail library that should be preloaded with `LD_PRELOAD`. The wraps the functions `syslog` and `__syslog_chk` to
send messages to `stdout` or whatever you want.

Source: https://github.com/jkroepke/liblogfaf