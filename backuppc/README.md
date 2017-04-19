# Summary
* [BackupPC](http://backuppc.sourceforge.net/) based on Debian Jessie backports
* Support for sending status mail using msmtp

# How to use
## Configure Mail
* You can use environment variables MAILHOST and FROM to set the target
mail relay host and mail "from" address, respectively.

## Configure user credentials
* change backuppc htaccess password in Dockerfile line 19 (or you may
  change it in the mapped configuration volume)

## SSH Keys
If you use ```rsync``` based backup, an SSH key is generated for you.
You can configure any backup target to accept this key

## Build and run the container
* cd into the directory
* run ```docker build```
* run the image ```docker run -d -P -v /<your-backup-folder>:/var/lib/backuppc -v /conf-dir:/etc/backuppc <image-id>```

# Volume Use

This image declares /var/lib/backuppc and /etc/backuppc as volumes.
You SHOULD map /var/lib/backuppc to a host volume (this will contain
your backups).  You MAY map /etc/backuppc to a location to preserve
configuration if you re-create your docker container.

