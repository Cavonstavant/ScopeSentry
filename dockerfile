# ScopeSentry server: self-contained multi-stage build.
# Builds the frontend and the Go binary from source, so it works from a plain
# checkout or a git-URL build context (no goreleaser dist/ folder needed):
#   docker build -f dockerfile -t scopesentry .
#   docker build -f dockerfile https://github.com/Cavonstavant/ScopeSentry.git#main

ARG NODE_VERSION=20
ARG GO_VERSION=1.24

# ---- frontend: frontend/dist-pro, same steps as .github/workflows/release.yml
FROM --platform=$BUILDPLATFORM node:${NODE_VERSION}-bookworm-slim AS frontend
WORKDIR /src/frontend
# HUSKY=0: package.json runs "husky install" on prepare; git hooks are not needed.
# NPM_CONFIG_UPDATE_NOTIFIER=false: skip npm's "new version available" registry check.
ENV HUSKY=0 NPM_CONFIG_UPDATE_NOTIFIER=false
COPY frontend/package.json frontend/package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --no-audit --no-fund
COPY frontend/ ./
RUN npx vite build --mode pro && test -f dist-pro/index.html

# ---- build: Go binary with the fresh frontend embedded
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-bookworm AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download
COPY . .
# Merge dist-pro into the embedded static dir, like CI's
# `rsync -a frontend/dist-pro/ cmd/main/static/`: COPY overwrites matching files
# and keeps the rest (map.html, js/, lib/, plugins/, draco/, css/, png/).
COPY --from=frontend /src/frontend/dist-pro/ ./cmd/main/static/
ARG TARGETOS
ARG TARGETARCH
# Must be valid semver: internal/update compares it with the version stored in
# MongoDB to decide which migrations to run. Keep in sync with version.json.
ARG VERSION=1.9.4
# Build main.go only: cmd/main/basic_usage.go declares a second main().
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    echo "${VERSION}" | grep -Eq '^v?[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$' \
      || { echo "VERSION '${VERSION}' is not a valid semantic version" >&2; exit 1; } \
 && test -f cmd/main/static/map.html && test -d cmd/main/static/lib \
 && CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath \
      -ldflags "-s -w -X github.com/Autumn-27/ScopeSentry/internal/constants.Version=${VERSION}" \
      -o /out/ScopeSentry ./cmd/main/main.go

# ---- runtime
FROM debian:trixie-slim
ENV TZ=Asia/Shanghai
# curl: compose healthcheck. tzdata-legacy: alias zone names (e.g. PRC) that
# Debian 13 split out of tzdata, so any TIMEZONE value that worked before still loads.
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates curl tzdata tzdata-legacy \
 && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
 && rm -rf /var/lib/apt/lists/*
# The server writes config.yaml, PLUGINKEY, PASSWORD, files/, images/ and
# uploads/ next to its binary and in the working directory.
WORKDIR /opt/ScopeSentry
COPY --from=build /out/ScopeSentry /opt/ScopeSentry/ScopeSentry
ENTRYPOINT ["/opt/ScopeSentry/ScopeSentry"]
