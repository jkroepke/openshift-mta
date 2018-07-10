primary_hostname =

domainlist local_domains = @ : localhost : localhost.localdomain
domainlist relay_to_domains = *
hostlist   relay_from_hosts = *

acl_smtp_mail = acl_check_mail
acl_smtp_rcpt = acl_check_rcpt

daemon_smtp_ports = 25
prdr_enable = true

log_selector = +smtp_protocol_error +smtp_syntax_error +tls_certificate_verified

ignore_bounce_errors_after = 2d
timeout_frozen_after = 7d

keep_environment = ^LDAP
add_environment = PATH=/usr/bin::/bin

split_spool_directory = true

begin acl
acl_check_mail:
  deny    condition     = ${if eq{$sender_helo_name}{} {1}}
          message       = Nice boys say HELO first
  accept
acl_check_rcpt:
  require verify        = sender
  require message       = nice hosts say HELO first
          condition     = ${if def:sender_helo_name}
  require verify        = recipient
  accept

begin routers
dnslookup:
  driver = dnslookup
  domains = *
  transport = remote_smtp
  no_more

relayhost:
  driver = manualroute
  domains = *
  transport = remote_smtp
  route_data = "${RELAYHOST}"

begin transports
remote_smtp:
  driver = smtp
  hosts_require_auth = relayhost

begin retry
*                      *           F,2h,15m; G,16h,1h,1.5; F,4d,6h
begin rewrite
begin authenticators
plain:
  river = plaintext
  public_name = PLAIN
  client_send = "${extract{auth_plain}{${lookup{$host}lsearch{/etc/exim/secrets/smtp_users}{$value}fail} }}"