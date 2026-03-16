APP=$(shell basename $(shell git remote get-url origin))
REGISTRY=ghcr.io/vlad1slav1k
VERSION=$(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)

TARGETOS ?= linux
TARGETARCH ?= amd64
CGO_ENABLED ?= 0

build:
	CGO_ENABLED=$(CGO_ENABLED) GOOS=$(TARGETOS) GOARCH=$(TARGETARCH) go build -v -o kbot -ldflags "-X github.com/Vlad1slav1k/kbot/cmd.appVersion=$(VERSION)"

test:
	go test -v ./...

image:
	docker build . -t $(REGISTRY)/$(APP):$(VERSION)-$(TARGETOS)-$(TARGETARCH)

push:
	docker push $(REGISTRY)/$(APP):$(VERSION)-$(TARGETOS)-$(TARGETARCH)
