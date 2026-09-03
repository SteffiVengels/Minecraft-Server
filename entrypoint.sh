#!/usr/bin/env bash
# Generates the server config from environment variables (all with safe
# defaults so the server can ALWAYS start) and then launches the server.
set -euo pipefail

DATA_DIR="${DATA_DIR:-/data}"
SERVER_JAR="${SERVER_JAR:-/opt/minecraft/server.jar}"

# ---- Defaults (overridable via environment / .env) --------------------------
ACCEPT_EULA="${ACCEPT_EULA:-true}"
SERVER_PORT="${SERVER_PORT:-25565}"
MOTD="${MOTD:-A Minecraft Server (Docker)}"
DIFFICULTY="${DIFFICULTY:-easy}"
GAMEMODE="${GAMEMODE:-survival}"
MAX_PLAYERS="${MAX_PLAYERS:-20}"
ONLINE_MODE="${ONLINE_MODE:-true}"
VIEW_DISTANCE="${VIEW_DISTANCE:-10}"
LEVEL_NAME="${LEVEL_NAME:-world}"
LEVEL_SEED="${LEVEL_SEED:-}"
PVP="${PVP:-true}"
JAVA_MEM_OPTS="${JAVA_MEM_OPTS:--Xms512M -Xmx1024M}"

cd "${DATA_DIR}"

# ---- Minecraft EULA ---------------------------------------------------------
# Setting ACCEPT_EULA=true means you agree to Mojang's EULA
# (https://aka.ms/MinecraftEULA).
if [ "${ACCEPT_EULA}" = "true" ]; then
    echo "eula=true" > eula.txt
else
    echo "ERROR: You must set ACCEPT_EULA=true to run the server." >&2
    exit 1
fi

# ---- server.properties ------------------------------------------------------
# Regenerated from env on every start (env is the single source of truth).
# World data lives in the '${LEVEL_NAME}/' directory and is NOT touched here,
# so gameplay progress persists across restarts via the mounted volume.
cat > server.properties <<EOF
server-port=${SERVER_PORT}
motd=${MOTD}
difficulty=${DIFFICULTY}
gamemode=${GAMEMODE}
max-players=${MAX_PLAYERS}
online-mode=${ONLINE_MODE}
view-distance=${VIEW_DISTANCE}
level-name=${LEVEL_NAME}
level-seed=${LEVEL_SEED}
pvp=${PVP}
enable-command-block=false
spawn-protection=0
EOF

echo "Starting Minecraft server on port ${SERVER_PORT} ..."
exec java ${JAVA_MEM_OPTS} -jar "${SERVER_JAR}" nogui