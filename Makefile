# -------------------------
# Configuration
# -------------------------
APP := $(shell basename $(shell git remote get-url origin) .git)
REGISTRY := ghcr.io/vlad1slav1k
VERSION := $(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)

# Default build targets
TARGETOS ?= linux
TARGETARCH ?= amd64
CGO_ENABLED ?= 0

# Validate environment variables
ifeq ($(TARGETOS),)
$(error TARGETOS is not set)
endif
ifeq ($(TARGETARCH),)
$(error TARGETARCH is not set)
endif

# -------------------------
# Go commands
# -------------------------
format:
	gofmt -s -w ./ 

get:
	go get ./...

lint:
	golint ./...

test:
	go test -v ./...

# -------------------------
# Build binary
# -------------------------
build: format get
	@echo "Building ${APP} for ${TARGETOS}-${TARGETARCH}..."
	CGO_ENABLED=${CGO_ENABLED} GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -v -o bin/${APP}-${TARGETOS}-${TARGETARCH} -ldflags "-X github.com/Vlad1slav1k/kbot/cmd.appVersion=${VERSION}"

# -------------------------
# Docker image
# -------------------------
image: build
	@echo "Building Docker image ${REGISTRY}/${APP}:${VERSION}-${TARGETOS}-${TARGETARCH}..."
	docker build --build-arg TARGETOS=${TARGETOS} --build-arg TARGETARCH=${TARGETARCH} -t ${REGISTRY}/${APP}:${VERSION}-${TARGETOS}-${TARGETARCH} .

push: image
	@echo "Pushing Docker image ${REGISTRY}/${APP}:${VERSION}-${TARGETOS}-${TARGETARCH}..."
	docker push ${REGISTRY}/${APP}:${VERSION}-${TARGETOS}-${TARGETARCH}

# -------------------------
# Clean
# -------------------------
clean:
	@echo "Cleaning binaries and Docker images..."
	rm -rf bin/*
	docker rmi ${REGISTRY}/${APP}:${VERSION}-${TARGETOS}-${TARGETARCH} || true
