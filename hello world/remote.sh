#!/bin/bash

case "$1" in
start)
	mkdir -p ~/cloudstomp/plain
	if [ "${PASSWORD}" != '' ]; then
		mkdir -p ~/cloudstomp/crypt
		gocryptfs -init ~/cloudstomp/crypt << EOF
${PASSWORD}
EOF
		gocryptfs ~/cloudstomp/crypt ~/cloudstomp/plain << EOF
${PASSWORD}
EOF
	fi
	/home/ubuntu/.local/bin/aws s3 mb s3://cloudstomp-$SESSION/ > /dev/null
	screen -S helloworld -t helloworld -L -Logfile ~/cloudstomp/plain/output.txt -Adm ./remote.sh exec
	screen -S sync -t sync -L -Logfile ~/cloudstomp/plain/sync.txt -Adm ./remote.sh sync
	;;

status)
	tail -n 20 ~/cloudstomp/plain/output.txt
	;;

connect)
	screen -r helloworld
	;;

stop)
	screen -S helloworld -t helloworld -X stuff ^C
	screen -S sync -t sync -X stuff ^C
	screen -r helloworld
	screen -r sync
	if [ "${PASSWORD}" != '' ]; then
		/home/ubuntu/.local/bin/aws s3 sync ~/cloudstomp/crypt/ s3://cloudstomp-$SESSION/
	else
		/home/ubuntu/.local/bin/aws s3 sync ~/cloudstomp/plain/ s3://cloudstomp-$SESSION/
	fi
	if [ -n "$SPOTID" ]; then
		/home/ubuntu/.local/bin/aws ec2 cancel-spot-instance-requests --spot-instance-request-ids $SPOTID > /dev/null
	fi
	/home/ubuntu/.local/bin/aws ec2 terminate-instances --instance-ids $INSTANCEID > /dev/null
	;;

exec)
	echo "Starting hello world..."
	while true; do
		echo "Hello world!"
		echo "Sleeping ${WAITTIME} seconds..."
		sleep ${WAITTIME}
	done 
	;;

sync)
	echo "Syncing data directory..."
	while true; do
		if [ ${PASSWORD} != '' ]; then
			/home/ubuntu/.local/bin/aws s3 sync ~/cloudstomp/crypt/ s3://cloudstomp-$SESSION/
		else
			/home/ubuntu/.local/bin/aws s3 sync ~/cloudstomp/plain/ s3://cloudstomp-$SESSION/
		fi
		echo "Sleeping 15 seconds..."
		sleep 15
	done 
	;;

*)
	echo "Usage: remote.sh {start|stop|status|connect}"
        exit 2
        ;;

esac
exit 0
