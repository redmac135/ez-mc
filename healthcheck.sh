#!/bin/sh

if netstat -tln | grp -q ":25565"; then
	echo "Server not listening for connections"
	exit 1
else
	echo "No problems found"
	exit 0
fi
