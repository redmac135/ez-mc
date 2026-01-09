#!/bin/sh
set -e

exec java -Xms$RAM -Xmx$RAM \
	-XX:+UseContainerSupport \
	-XX:+UnlockExperimentalVMOptions \
	-XX:+UseG1GC \
	$JAVAFLAGS \
	-jar /server/purpur.jar nogui
