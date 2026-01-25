FROM eclipse-temurin:21-jre

# --- configure UID/GUID ---
ARG MC_UID=1000
ARG MC_GID=1000
ARG MC_VERSION=1.21.11

ENV MC_UID=${MC_UID}
ENV MC_GID=${MC_GID}
ENV MC_VERSION=${MC_VERSION}

# =======================================
# HARD VERSION CHECK (GEYSER REQUIREMENT)
# =======================================
RUN if [ "${MC_VERSION}" != "1.21.11" ]; then \
	echo "ERROR: Geyser requires Minecraft 1.21.11. You set MC_VERSION=${MC_VERSION}"; \
	exit 1; \
	fi

# dependencies
RUN apt-get update \
	&& apt-get install -y net-tools curl ca-certificates jq \
	&& rm -rf /var/lib/apt/lists/*

# create steve user
RUN groupadd -g ${MC_GID} steve \
	&& useradd -u ${MC_UID} -g ${MC_GID} -d /data -s /bin/bash steve

# move files
RUN mkdir -p /server /data

# download server jar
RUN curl -L \
	"https://api.purpurmc.org/v2/purpur/${MC_VERSION}/latest/download" \
	-o /server/purpur.jar

# verify download
RUN test -s /server/purpur.jar

# =======================================
# PLUGINS
# =======================================

# download plugins
RUN mkdir -p /server/plugins

# WorldEdit
RUN curl -s https://api.modrinth.com/v2/project/worldedit/version \
	| jq -r '.[] \
	| select(.game_versions[]=="'${MC_VERSION}'") \
	| select(.loaders[]=="paper") \
	| .files[0] \
	| select(.primary==true) \
	| .url' \
	| head -n 1 \
	| xargs curl -L -o /server/plugins/worldedit.jar

RUN test -s /server/plugins/worldedit.jar

# Chunky
RUN curl -s https://api.modrinth.com/v2/project/chunky/version \
	| jq -r '.[] \
	| select(.game_versions[]=="'${MC_VERSION}'") \
	| select(.loaders[]=="paper") \
	| .files[0] \
	| select(.primary==true) \
	| .url' \
	| head -n 1 \
	| xargs curl -L -o /server/plugins/chunky.jar

RUN test -s /server/plugins/chunky.jar

# Geyser
RUN curl -L \
	"https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot" \
	-o /server/plugins/geyser.jar \
	&& test -s /server/plugins/geyser.jar

RUN test -s /server/plugins/geyser.jar

# Floodgate
RUN curl -L \
	"https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot" \
	-o /server/plugins/floodgate.jar \
	&& test -s /server/plugins/floodgate.jar

RUN test -s /server/plugins/floodgate.jar

# =======================================
# ENTRYPOINT AND HEALTHCHECK
# =======================================

# entrypoint and healthcheck scripts
COPY entrypoint.sh /server/
COPY healthcheck.sh /server/

# root ownership and permissions
RUN chmod +x /server/*.sh \
	&& chown -R root:root /server

# =======================================
# RUNTIME
# =======================================

# data volume
VOLUME "/data"
WORKDIR /data

EXPOSE 25565/tcp

ENV RAM=2G
ENV TZ=America/Toronto
ENV JAVAFLAGS=""

USER steve

HEALTHCHECK --interval=1m --timeout=3s \
	CMD [ "/server/healthcheck.sh" ]

ENTRYPOINT [ "/server/entrypoint.sh" ]
