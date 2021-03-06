[![](https://img.shields.io/docker/build/jkroepke/openshift-mta.svg)](https://hub.docker.com/r/jkroepke/openshift-mta/) [![](https://images.microbadger.com/badges/image/jkroepke/openshift-mta.svg)](https://hub.docker.com/r/jkroepke/openshift-mta/) [![Docker Pulls](https://img.shields.io/docker/pulls/jkroepke/openshift-mta.svg)](https://hub.docker.com/r/jkroepke/openshift-mta/) [![Docker Stars](https://img.shields.io/docker/stars/jkroepke/openshift-mta.svg)](https://hub.docker.com/r/jkroepke/openshift-mta/)

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
| `SENDMAIL_LISTEN_MODIFIER` | Configure daemon modifier. See: http://www.sendmail.org/~gshapiro/8.10.Training/DaemonPortOptions.html |
| `SENDMAIL_DISABLE_SENDER_RDNS` | Remove sender ip lookup. Required on container based environments |
| `SENDMAIL_ACCESS` | Additional sendmail access.db setting |
| `SENDMAIL_ROOT_ALIAS` | Define alias for local root (Mail or `/dev/null`) |
| `SENDMAIL_SMART_HOST_USER` | Relayhost authentification user |
| `SENDMAIL_SMART_HOST_PASSWORD` | Relayhost authentification password |
| `SENDMAIL_FORCE_TLS_VERIFY` | TLS verify must be valid.  |
| `SENDMAIL_FORCE_SENDER_ADDRESS` | Rewrite FROM header in all messages  |
| `SENDMAIL_FORCE_RECEIVER_ADDRESS` | Send all messages to this mailbox. Useful for qa environments |
| `SENDMAIL_RAW_PREPEND` | Raw configuration prepends to the `sendmail.mc` |
| `SENDMAIL_RAW_APPEND` | Raw configuration appends to the `sendmail.mc` |
| `SENDMAIL_LOCAL_CONFIG` | `LOCAL_CONFIG` configuration appends to the `sendmail.mc` |
| `SENDMAIL_QUEUE_INTERVAL` | sendmail's `-q` flag specifies how often a sub-daemon will run the queue.  |
| `SENDMAIL_EXCLUDE_LOG_PATTERN` | Exclude logs from console output.  |
| `SENDMAIL_AUTH_USER` | AUTH user to forward mails.  |
| `SENDMAIL_AUTH_PASSWORD` | AUTH password to forward mails. |
| `SENDMAIL_CLIENT_OPTIONS` | Sendmail CLIENT_OPTIONS. |

### Default settings
| Name | Value |
| ---- | ----- |
| `SENDMAIL_ACCESS` | `Connect:10 RELAY\nConnect:127 RELAY\nConnect:172 RELAY\nConnect:192.168 RELAY` |
| `SENDMAIL_ROOT_ALIAS` | `/dev/null` |
| `SENDMAIL_FEATURE_nouucp` | `nospecial` |
| `SENDMAIL_FEATURE_nocanonify` | `true` |
| `SENDMAIL_FEATURE_authinfo` | `true` |
| `SENDMAIL_DEFINE_STATUS_FILE` | `/dev/null` |
| `SENDMAIL_DEFINE_ALIAS_FILE` | `/etc/mail/aliases` |
| `SENDMAIL_DEFINE_QUEUE_DIR` | `/var/spool/mqueue` |
| `SENDMAIL_DEFINE_confLOG_LEVEL` | `9` |
| `SENDMAIL_DEFINE_confMIN_QUEUE_AGE` | `0` |
| `SENDMAIL_DEFINE_confREFUSE_LA` | `0` |
| `SENDMAIL_DEFINE_confQUEUE_LA` | `0` | 
| `SENDMAIL_DEFINE_confCACERT_PATH` | `/etc/pki/tls/certs/ca-bundle.trust.crt` |
| `SENDMAIL_DEFINE_confCACERT` | `/etc/pki/tls/certs` |
| `SENDMAIL_DEFINE_confPID_FILE` | `/tmp/sendmail.pid` |
| `SENDMAIL_DEFINE_confDONT_BLAME_SENDMAIL` | `` `GroupReadableSASLDBFile,GroupWritableAliasFile,GroupReadableKeyFile,GroupWritableDirPathSafe' `` |
| `SENDMAIL_DEFINE_confSERVER_SSL_OPTIONS` | `+SSL_OP_NO_SSLv2 +SSL_OP_NO_SSLv3 +SSL_OP_CIPHER_SERVER_PREFERENCE` |
| `SENDMAIL_DEFINE_confCLIENT_SSL_OPTIONS` | `+SSL_OP_NO_SSLv2 +SSL_OP_NO_SSLv3` |
| `SENDMAIL_DEFINE_confCIPHER_LIST` | `HIGH:MEDIUM:!aNULL:!eNULL@STRENGTH` |
| `SENDMAIL_DEFINE_confRUN_AS_USER` | `openshift:root` |
| `SENDMAIL_DEFINE_confAUTH_MECHANISMS` | `LOGIN PLAIN CRAM-MD5 DIGEST-MD5 NTLM` |
| `SENDMAIL_DEFINE_confPRIVACY_FLAGS` | `needmailhelo` |
| `SENDMAIL_FORCE_TLS_VERIFY` | `true` |
| `SENDMAIL_LISTEN_MODIFIER` | `CE` |
| `SENDMAIL_CLIENT_OPTIONS` | `Family=inet` |

### Advanced Variables

| Name | Results in ... |
| ---- | ----- |
| `SENDMAIL_DEBUG` | Enable debug in sendmail |
| `ENTRYPOINT_DEBUG` | Enable debug in entrypoint.sh |
| `LIBLOGFAF_SENDTO` | Pipe all log from syslog to `LIBLOGFAF_SENDTO` |

# liblogfaf
This is a smail library that should be preloaded with `LD_PRELOAD`. The wraps the functions `syslog` and `__syslog_chk` to
send messages to `stdout` or whatever you want.

Source: https://github.com/jkroepke/liblogfaf
