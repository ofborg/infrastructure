#!/usr/bin/env bash

LOGHOST=10.172.170.1
echo "apply started at $(date)" | nc -w0 -u $LOGHOST 1514

printf "\n*.*\t@%s:1514\n" "$LOGHOST" | tee -a /etc/syslog.conf
pkill syslog
pkill asl

logtohost() (
  logger -t apply.sh -p install.emerg
)

for i in $(seq 1 5); do
  echo "Apply.$i started at $(date)" | logtohost
  sleep 1
done

(
    PS4='${BASH_SOURCE}::${FUNCNAME[0]}::$LINENO '
    set -o pipefail
    set -ex
    date

    function finish {
        set +e
        cd /
        sleep 1
        umount -f /Volumes/CONFIG
        sleep 1
        umount -f /Volumes/CONFIG
    }
    trap finish EXIT

    /Volumes/CONFIG/setup.sh 2>&1 | logtohost
) 2>&1 | logtohost
