# openshift-mta
MTA in a Docker primary designed for secure Openshift environment

# Variants

| Program | RHEL7 Support | Status | Notes |
| ------- | ------ | ------ | ------ |
| Postfix | YES | __FAILED__ | master process can be run without root but childs failed. Many hacks like fakeroot required |
| exim | EPEL | __FAILED__ | Exim documentation says, exim can be run in rootless, but can't detect to unpriviliged mode and want to call `setgroup` |
| sendmail | YES | __SUCCESS__ | Configuration syntax from last century |
| nullmailer | N/A | __UNKNOWN__ | - |
| haraka | N/A | __UNKNOWN__ | nodejs MTA |
| zone-mta | N/A | __UNKNOWN__ | nodejs MTA |