# Minecraft Java Server — custom image (no prefabricated Minecraft image).
# Base: Ubuntu 24.04. We install the JRE and all required packages ourselves.
FROM ubuntu:24.04

# Install the Java runtime and the tools needed to resolve/download the server jar.
# openjdk-21-jre-headless -> Java 21 (required by current Minecraft releases)
# curl + jq              -> query Mojang's version manifest and download the jar
# ca-certificates        -> HTTPS trust store
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    openjdk-21-jre-headless \
    curl \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Which Minecraft version to install.
#   latest  -> resolves the newest stable release from Mojang's manifest
#   1.21.4  -> pin a specific version for reproducible builds
ARG MINECRAFT_VERSION=latest

# Download the official server.jar from Mojang (URL is resolved, never hardcoded).
WORKDIR /opt/minecraft
RUN set -eux; \
    MANIFEST="https://launchermeta.mojang.com/mc/game/version_manifest_v2.json"; \
    if [ "${MINECRAFT_VERSION}" = "latest" ]; then \
        VERSION_ID="$(curl -fsSL "${MANIFEST}" | jq -r '.latest.release')"; \
    else \
        VERSION_ID="${MINECRAFT_VERSION}"; \
    fi; \
    VERSION_URL="$(curl -fsSL "${MANIFEST}" | jq -r --arg V "${VERSION_ID}" '.versions[] | select(.id==$V) | .url')"; \
    [ -n "${VERSION_URL}" ] || { echo "Version ${VERSION_ID} not found in manifest"; exit 1; }; \
    SERVER_URL="$(curl -fsSL "${VERSION_URL}" | jq -r '.downloads.server.url')"; \
    curl -fsSL -o server.jar "${SERVER_URL}"; \
    echo "Installed Minecraft server ${VERSION_ID}"

# Entrypoint generates config from env (with defaults) and starts the server.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV SERVER_JAR=/opt/minecraft/server.jar \
    DATA_DIR=/data

# Informational: the server listens on this port inside the container.
EXPOSE 25565

# All world data and generated config live here (persisted via a volume).
WORKDIR /data

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]