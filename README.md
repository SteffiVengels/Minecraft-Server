# Dockerized Minecraft Java Server

A self-contained Docker setup that builds a **custom image** for a Minecraft
Java Edition server (no prefabricated Minecraft image), runs it via Docker
Compose, exposes it on host port **8888**, and persists all world data across
restarts.

## Table of Contents

- [Description](#description)
- [Repository Contents](#repository-contents)
- [Quickstart](#quickstart)
- [Usage & Configuration](#usage--configuration)
  - [Configuration Variables](#configuration-variables)
  - [Choosing the Minecraft Version](#choosing-the-minecraft-version)
  - [Data Persistence](#data-persistence)
  - [Testing the Connection](#testing-the-connection)
- [Notes](#notes)

## Description

This repository contains everything needed to build and run a Minecraft Java
server inside a container. The image is assembled from an Ubuntu base: it
installs the Java runtime and the required tools itself, then downloads the
official server binary from Mojang's version manifest at build time. An
entrypoint script generates the server configuration from environment variables
(all with sensible defaults, so the server always starts) and launches the
server. Compose wires up the port binding, a named volume for persistence, and
an automatic restart policy.

## Repository Contents

| File                  | Purpose                                                                 |
| --------------------- | ----------------------------------------------------------------------- |
| `Dockerfile`          | Builds the custom server image (installs Java, downloads `server.jar`).  |
| `entrypoint.sh`       | Accepts the EULA, generates `server.properties` from env, starts server. |
| `docker-compose.yaml` | Defines the `mc-server` service: env, port `8888`, volume, restart.      |
| `.env.example`        | Template for local configuration overrides (copy to `.env`).             |
| `.gitignore`          | Excludes secrets, world data, and the downloaded binary.                 |
| `README.md`           | This documentation.                                                      |
| `.gitattributes`      | Enforces LF line endings (keeps `entrypoint.sh` runnable on Linux). |

## Quickstart

**Requirements:** Docker and the Docker Compose plugin installed.

```bash
# 1. (optional) create a local config from the template
cp .env.example .env

# 2. build the image and start the server in the background
docker compose up -d --build

# 3. follow the logs until you see "Done (...)! For help, type help"
docker compose logs -f mc-server
```

The server is now reachable at `HOST_IP:8888`. Stop it with
`docker compose down` (the world data remains in the volume).

## Usage & Configuration

### Configuration Variables

All gameplay settings are passed as environment variables. Set them in `.env`
(or the shell) to override the defaults; leave them unset to use the defaults.

| Variable         | Default                     | Description                                   |
| ---------------- | --------------------------- | --------------------------------------------- |
| `MINECRAFT_VERSION` | `latest`                 | Server version to install (build arg).        |
| `MOTD`           | `A Minecraft Server (Docker)` | Message shown in the server list.           |
| `DIFFICULTY`     | `easy`                      | `peaceful` / `easy` / `normal` / `hard`.      |
| `GAMEMODE`       | `survival`                  | `survival` / `creative` / `adventure` / `spectator`. |
| `MAX_PLAYERS`    | `20`                        | Maximum concurrent players.                   |
| `ONLINE_MODE`    | `true`                      | `true` requires genuine Minecraft accounts.   |
| `VIEW_DISTANCE`  | `10`                        | Render distance in chunks.                    |
| `LEVEL_NAME`     | `world`                     | World folder name.                            |
| `LEVEL_SEED`     | *(empty)*                   | World generation seed.                        |
| `PVP`            | `true`                      | Enable player-vs-player combat.               |
| `JAVA_MEM_OPTS`  | `-Xms512M -Xmx1024M`        | JVM heap options. Raise `-Xmx` for more RAM.  |

To change a setting, edit the value in `.env` and recreate the container:

```bash
docker compose up -d
```

Because `server.properties` is regenerated from the environment on every start,
your `.env` is the single source of truth — editing `server.properties` inside
the container will not persist.

### Choosing the Minecraft Version

By default the build installs the newest stable release. For a reproducible
build, pin a version:

```bash
MINECRAFT_VERSION=1.25 docker compose up -d --build
```

or set `MINECRAFT_VERSION` in `.env`.

### Data Persistence

The world, logs, and generated config live in `/data` inside the container,
backed by the named volume `mc-data`. This survives `docker compose down`,
container crashes, and host reboots. To wipe the world and start fresh:

```bash
docker compose down -v   # -v also removes the volume
```

### Testing the Connection

Using the `mcstatus` Python tool
([py-mine/mcstatus](https://github.com/py-mine/mcstatus)):

```bash
pip install mcstatus
mcstatus HOST_IP:8888 status
```

A successful response confirms the server is reachable. Alternatively, connect
with a Java Minecraft client to `HOST_IP:8888`.

## Notes

- The `.env` file is gitignored and must never be committed. No passwords,
  tokens, usernames, or IP addresses are stored in this repository.
- On the server host, make sure port `8888/tcp` is open in both the host
  firewall and any provider-side cloud firewall.