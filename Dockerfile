FROM eclipse-temurin:21-jre

# --- configure UID/GUID ---
ARG MC_UID=1000
ARG MC_GID=1000

ENV MC_UID=${MC_UID}
ENV MC_GID=${MC_GID}

# dependencies
RUN apt-get update \
	&& apt-get install -y net-tools \
	&& rm -rf /var/lib/apt/lists/*

# create steve user
RUN groupadd -g ${MC_GID} steve \
	&& useradd -u ${MC_UID} -g ${MC_GID} -d /data -s /bin/bash steve

# move files
RUN mkdir -p /server /data

# server jar
COPY purpur.jar /server/
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
