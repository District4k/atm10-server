# syntax=docker/dockerfile:1

# Runtime-only image: the ATM10 pack and world are bind-mounted at /data.
FROM eclipse-temurin:21.0.8_9-jre-jammy AS runtime

LABEL org.opencontainers.image.title="atm10-prod"
LABEL org.opencontainers.image.description="Java 21 runtime for All the Mods 10 (NeoForge) with a bind-mounted server directory"

WORKDIR /data

COPY docker/entrypoint.sh /usr/local/bin/atm10-entrypoint.sh
RUN chmod 0755 /usr/local/bin/atm10-entrypoint.sh

EXPOSE 25565

# Bind-mounted pack files on Docker Desktop for Mac keep host ownership when
# the process is root in the VM. Do not switch USER here.
ENTRYPOINT ["/usr/local/bin/atm10-entrypoint.sh"]
