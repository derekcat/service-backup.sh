@@ -0,0 +1,95 @@
#!/bin/bash
# Script by Derek DeMoss
# This will create DB drops, every $LASTBACKUP+1 days, and delete ones older than $OLDBACKUPAGE+1 days ago.
# It is intended to be run automatically every day, so that you have a set of databases you could restore from.
# The 3/5/15 update is meant to support Netdisco and be configured totally via the below variables
# Also, with that update, we have help text and a --now option, for when you really, really can't wait.
# Last updated: 03/5/15

TARG="netdisco2" # The service we are backing up, used to name folders/backups
TODAY=`date +%Y%m%d`
GZEXT=".gz" # It wasn't working if just appended on the dump command line
LASTBACKUP=1 # Number of days ago plus 1
OLDBACKUPAGE=30 # Number of days ago plus 1
DBDROPCMD=`PGPASSWORD="thisisapassword" /usr/bin/pg_dump --create -U netdisco -h localhost netdisco` # This command is how you drop the DB
# Cacti's command `mysqldump -u cactiuser  --password=thisisapassword -l --add-drop-table cacti`
# Netdisco's command `PGPASSWORD="thisisapassword" /usr/bin/pg_dump --create -U netdisco -h localhost netdisco`
# Zabbix's command `mysqldump  --password=thisisapassword -l --add-drop-table zabbix`

if [ "$1" = "-h" ] || [ "$1" = "--help" ] ;
then
	echo "Usage: service-backup.sh [OPTION]"
	echo "Performs backups of this VM's main service's database"
	echo "  -h, --help		display this help text"
	echo "  -n, --now		forces an extra backup right now"
	echo "If you need to configure the script, please only edit the variables at the top,"
	echo "via: vi /usr/sbin/service-backup.sh"
	exit
fi

if [ "$1" = "-n" ] || [ "$1" = "--now" ] ;
then
	echo "Well someone is impatient... Backing up $TARG, NOW."
	$DROPDBCMD | gzip > /$TARG-backups/$TARG-db/db.$TARG.$TODAY`date +%H%M%S`$GZEXT
	ls -lh /$TARG-backups/$TARG-db/
	echo "Done!"
	exit
fi	

# Backup folder creation:
if [ -d "/$TARG-backups" ] ;
then
	echo "/$TARG-backups exists, continuing."
else
	mkdir /$TARG-backups
	echo "Created /$TARG-backups"
fi

if [ -d "/$TARG-backups/$TARG-db" ] ;
then
	echo "/$TARG-backups/$TARG-db exists, continuing."
else
	mkdir /$TARG-backups/$TARG-db
	echo "Created /$TARG-backups/$TARG-db"
fi

# Delete old backups section --------------------------------------------------
OLDBACKUPS=`find -H /$TARG-backups/$TARG-db -name db* -type f -mtime +$OLDBACKUPAGE` # Creates a variable of what's about to get killed
if [ "$OLDBACKUPS" != "" ] ; # if $OLDBACKUPS is not blank - aka, if it DID find something to delete
then
	echo "Deleting SQL backups older than $OLDBACKUPAGE days:"
	echo ""
	echo "$OLDBACKUPS"
	echo ""
	sleep 1
	echo "You have 5 seconds to abort:"
	for i in `seq 5`;
	do
		echo "$i"
		sleep 1
	done
	
	find -H /$TARG-backups/$TARG-db -name db* -type f -mtime +$OLDBACKUPAGE -exec rm {} \; # kills...
	echo "Deleted:"
	echo "$OLDBACKUPS"
else
	echo "Looks like we don't need to delete any backups"
	echo "$OLDBACKUPS"
fi


# Create new backups section ---------------------------------------------------
# If you don't find anything newer than $LASTBACKUP+1 days, create a DB backup
echo "Let's check for a current backup:"
CURRENTBACKUPS=`find -H /$TARG-backups/$TARG-db -name db* -type f -mtime -$LASTBACKUP | tail -n 1`
if [ "$CURRENTBACKUPS" == ""  ] ;# If nothing is found above, then... 
then
	echo "There have been no database backups for $LASTBACKUP days.  Creating backup..."
	$DROPDBCMD | gzip > /$TARG-backups/$TARG-db/db.$TARG.$TODAY$GZEXT
	ls -lh /$TARG-backups/$TARG-db/
	echo "Done!"
else
	ls -lh /$TARG-backups/$TARG-db/
	echo "Looks like we have a recent database backup, carry on!"	
fi

