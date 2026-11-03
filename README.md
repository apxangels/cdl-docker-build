# Unofficial CyberDropDownloader Docker Image (v10)

> **Disclaimer:** This is ENTIRELY unofficial. Do NOT ask for support from the dev(s) of `cyberdrop-dl-patched`.

Multi-platform Docker image for [cyberdrop-dl-patched](https://github.com/Cyberdrop-DL/cyberdrop-dl) **v10.x**.

## What's inside

- Python 3.13 slim base
- `cyberdrop-dl-patched` (version pinned at build time)
- `ffmpeg` / `ffprobe`
- `gotty` for optional Web TTY
- Runtime user `abc` with proper XDG paths redirected to `/cyberdrop-dl/AppData`

## Build

```bash
docker build \
  --build-arg CYBERDROP_DL_VERSION=10.0.0 \
  -t apxangels/cdl-docker:10.0 .
```

## Docker Compose

```yaml
services:
  cdl-docker:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        CYBERDROP_DL_VERSION: "10.0.0"
    container_name: cdl-docker
    image: apxangels/cdl-docker:10.0
    network_mode: host
    volumes:
      - ./AppData:/cyberdrop-dl/AppData   # config, DB, cache, logs
      - ./downloads:/cyberdrop-dl/downloads # downloaded files
      - ./URLs.txt:/cyberdrop-dl/URLs.txt:ro
    restart: "no"
    stdin_open: true
    tty: true
    command: ["cyberdrop-dl"]
```

## Volumes explained

| Host path | Container path | Purpose |
|-----------|----------------|---------|
| `./AppData` | `/cyberdrop-dl/AppData` | Persistent XDG data: `config.yaml`, `cyberdrop.db`, `cache.json`, logs |
| `./downloads` | `/cyberdrop-dl/downloads` | Download destination (can be any host folder) |
| `./URLs.txt` | `/cyberdrop-dl/URLs.txt` | URL list (read-only mount) |

The entrypoint automatically:
- Creates missing XDG subdirectories inside `AppData`
- Generates a default `config.yaml` if none exists
- Patches `download_folder` to `/cyberdrop-dl/downloads` so it matches the volume
- Appends `--input-file /cyberdrop-dl/URLs.txt` when running `cyberdrop-dl download` if no other input file is provided

## Docker run

```bash
docker run -it --rm \
  --name cdl-docker \
  -v "$(pwd)/AppData:/cyberdrop-dl/AppData" \
  -v "$(pwd)/downloads:/cyberdrop-dl/downloads" \
  -v "$(pwd)/URLs.txt:/cyberdrop-dl/URLs.txt:ro" \
  apxangels/cdl-docker:10.0 \
  cyberdrop-dl
```

## Running as a different user

The image uses `gosu` in the entrypoint to drop privileges. If you need a different UID/GID, set them in `docker run` or `docker-compose.yml`:

```yaml
user: "1000:1000"
```

The entrypoint will `chown` the `AppData` volume to that user before starting.

## Web TTY (headless UI)

Enable via environment variables:

```yaml
environment:
  - GOTTY=true
  - GOTTY_PORT=6969
  - GOTTY_CREDENTIAL=user:pass
```

See [gotty docs](https://github.com/sorenisanerd/gotty/#options) for more options.

## Upgrading to a newer v10 release

Change the `CYBERDROP_DL_VERSION` build arg and rebuild:

```bash
docker compose build --no-cache
docker compose run --rm cdl-docker
```
