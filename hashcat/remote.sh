#!/bin/bash

HASHCAT=5.1.0

function init() {
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
}

case "$1" in
start)
	init
	/home/ubuntu/.local/bin/aws s3 mb s3://cloudstomp-$SESSION/ > /dev/null
	screen -S hashcat -t hashcat -L -Logfile ~/cloudstomp/plain/output.txt -Adm ./remote.sh exec
	screen -S sync -t sync -L -Logfile ~/cloudstomp/plain/sync.txt -Adm ./remote.sh sync
	;;

restore)
	init
	if [ "${PASSWORD}" != '' ]; then
		/home/ubuntu/.local/bin/aws s3 sync s3://cloudstomp-$SESSION/ ~/cloudstomp/crypt/
	else
		/home/ubuntu/.local/bin/aws s3 sync s3://cloudstomp-$SESSION/ ~/cloudstomp/plain/
	fi
	screen -S hashcat -t hashcat -L -Logfile ~/cloudstomp/plain/output.txt -Adm ./remote.sh execrestore
	screen -S sync -t sync -L -Logfile ~/cloudstomp/plain/sync.txt -Adm ./remote.sh sync
	;;

status)
	screen -S hashcat -t hashcat -X stuff "s"
	tail -n 20 ~/cloudstomp/plain/output.txt
	;;

connect)
	screen -r hashcat
	;;

checkpoint)
	screen -S hashcat -t hashcat -X stuff "sc"
	screen -S sync -t sync -X stuff ^C
	screen -r hashcat
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

stop)
	sleep 1
	screen -S hashcat -t hashcat -X stuff "sq"
	screen -S hashcat -t hashcat -X stuff Q
	screen -S sync -t sync -X stuff ^C
	screen -r hashcat
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
	echo "Starting hashcat..."
	cd hashcat-$HASHCAT
	if [ "$CRACKTYPE" == "w" ]; then
		if [ ! -f realuniq.lst ]; then
			echo "Extracting realuniq.lst..."
			gunzip crackstation.txt.gz
		fi
		if [ "$USERULES" == "y" ]; then
			./hashcat64.bin --session ../cloudstomp/plain/mysession -m $HASHTYPE "../$HASHFILE" ../realuniq.lst -o ../cloudstomp/plain/mysession_cracked -r "../$RULEFILE" --debug-mode=1 --debug-file=../cloudstomp/plain/mysession_rule -O -w 4
		else
			./hashcat64.bin --session ../cloudstomp/plain/mysession -m $HASHTYPE "../$HASHFILE" ../realuniq.lst -o ../cloudstomp/plain/mysession_cracked -O -w 4
		fi
	elif [ "$CRACKTYPE" == "b" ]; then
		if [ "$INCREMENT" == "y" ]; then
			./hashcat64.bin --session ../cloudstomp/plain/mysession -m $HASHTYPE "../$HASHFILE" -a 3 $PATTERN --increment -o ../cloudstomp/plain/mysession_cracked -O -w 4
		else
			./hashcat64.bin --session ../cloudstomp/plain/mysession -m $HASHTYPE "../$HASHFILE" -a 3 $PATTERN -o ../cloudstomp/plain/mysession_cracked -O -w 4
		fi
	fi
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

execrestore)
	echo "Restoring hashcat..."
	cd ~/hashcat
	./hashcat64.bin --session ../cloudstomp/plain/mysession --restore
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

sync)
	echo "Syncing data directory..."
	while true; do
		if [ "${PASSWORD}" != '' ]; then
			/home/ubuntu/.local/bin/aws s3 sync ~/cloudstomp/crypt/ s3://cloudstomp-$SESSION/
		else
			/home/ubuntu/.local/bin/aws s3 sync ~/cloudstomp/plain/ s3://cloudstomp-$SESSION/
		fi
		echo "Sleeping 300 seconds..."
		sleep 300
	done 
	;;

*)
	echo "Usage: remote.sh {start|stop|status|connect|checkpoint|restore}"
        exit 2
        ;;

esac
exit 0
