# postfix variant

## Problems
* Requires root (hardcoded)
  
  `Workaround: Use fakeroot or pseudo to create a fake root environment`
* Does log to /dev/log
  
  `Workaround: Use own liblogfaf to redirect messages to stdout`
  
* setgid fails, because EPEL's fakeroot doesn't support it.

* process spawned by master 'll failed (bad startup command)
