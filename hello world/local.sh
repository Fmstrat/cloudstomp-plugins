#!/bin/bash

case "$1" in
output)
	EXISTS=$(aws s3 ls s3://cloudstomp-$SESSION/ 2>&1 |grep "does not exist")
	if [ -z "$EXISTS" ]; then
		mkdir -p /tmp/cloudstomp-$SESSION/plain
		if [ "${PASSWORD}" != '' ]; then
			mkdir -p /tmp/cloudstomp-$SESSION/crypt
			aws s3 sync s3://cloudstomp-$SESSION/ /tmp/cloudstomp-$SESSION/crypt
			gocryptfs /tmp/cloudstomp-$SESSION/crypt /tmp/cloudstomp-$SESSION/plain << EOF
${PASSWORD}
EOF
		else
			aws s3 sync s3://cloudstomp-$SESSION/ /tmp/cloudstomp-$SESSION/plain
		fi
		cat /tmp/cloudstomp-$SESSION/plain/output.txt
		if [ "${PASSWORD}" != '' ]; then
			umount /tmp/cloudstomp-$SESSION/plain
		fi
		rm -rf /tmp/cloudstomp-$SESSION
	else
		echo "The plugin must be started at least once to view output."
	fi
	;;

*)
	echo "Usage: local.sh {output}"
        exit 2
        ;;

esac
exit 0
