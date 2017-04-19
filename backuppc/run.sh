#!/bin/bash

echo "backuppc: Checking folders"
if [ ! -d /var/lib/backuppc/cpool	]; then mkdir /var/lib/backuppc/cpool	; fi
if [ ! -d /var/lib/backuppc/pc		]; then mkdir /var/lib/backuppc/pc	; fi
# test 3 levels only as this can take very long on big storages.
# if all is correct, everything else should be ok
if [ $(/usr/bin/find /var/lib/backuppc  -maxdepth 3 -not -user backuppc -o -not \( -group backuppc  -o -group www-data \) | wc -l) -gt 1 ]; then
	/usr/bin/find /var/lib/backuppc  -not -user backuppc -o -not \( -group backuppc  -o -group www-data \) -exec chown  backuppc:backuppc  "{}"  +
fi

echo "backuppc: Checking ssh key"
# Ensure that an SSH key exists
if [ ! -e /var/lib/backuppc/.ssh/id_rsa ] ; then
    mkdir /var/lib/backuppc/.ssh
    ssh-keygen -f /var/lib/backuppc/.ssh/id_rsa -C "BackupPC Backup Key"
cat <<EOF >/var/lib/backuppc/.ssh/config
host *
	StrictHostKeyChecking no
EOF
    chown -R backuppc:backuppc /var/lib/backuppc/.ssh
    echo
    echo ======================================================================
    echo
    echo "Use this SSH Key for backup:"
    echo
    cat /var/lib/backuppc/.ssh/id_rsa.pub
    echo
    echo ======================================================================
    echo
fi

# Ensure that the mail host is configured properly from the
# environment variables.  Do this each time to allow mail
# configuration to change by simply recreating the container.

sed -e "s/MAILHOST/$MAILHOST/g" -e "s/FROM/$FROM/g" /var/lib/backuppc/.msmtprc.dist > /var/lib/backuppc/.msmtprc

echo "backuppc: Starting supervisor"
exec /usr/bin/supervisord -c /etc/supervisord.conf

