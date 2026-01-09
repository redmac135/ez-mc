#!/bin/sh
set -e

echo "Minecraft UID: $(id -u)  GID: $(id -g)"

# Create required dirs
mkdir -p /data/plugins
mkdir -p /data/world

# First-run plugin install
if [ -z "$(ls -A /data/plugins 2>/dev/null)" ]; then
    echo "📦 Installing default plugins..."
    cp -v /server/plugins/*.jar /data/plugins/
else
    echo "📦 Plugins already present, skipping install"
fi

# First-run EULA
if [ ! -f /data/eula.txt ]; then
    echo "eula=true" > /data/eula.txt
fi

exec java -Xms$RAM -Xmx$RAM \
	-XX:+UseContainerSupport \
	-XX:+UnlockExperimentalVMOptions \
	-XX:+UseG1GC \
	$JAVAFLAGS \
	-jar /server/purpur.jar nogui
