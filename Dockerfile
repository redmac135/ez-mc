FROM eclipse-temurin:21-jre

# --- configure UID/GUID ---
ARG MC_UID=1000
ARG MC_GID=1000
ARG MC_VERSION=1.21.11

ENV MC_UID=${MC_UID}
ENV MC_GID=${MC_GID}
ENV MC_VERSION=${MC_VERSION}

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

# download plugins
RUN mkdir -p /server/plugins

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

# entrypoint and healthcheck scripts
COPY entrypoint.sh /server/
COPY healthcheck.sh /server/

# root ownership and permissions
RUN chmod +x /server/*.sh \
	&& chown -R root:root /server

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
