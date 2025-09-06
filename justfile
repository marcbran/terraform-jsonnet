
test-jsonnet:
  @just -d pkg/terraform -f pkg/terraform/justfile test

test: test-jsonnet

build-jsonnet:
  @just -d pkg/terraform -f pkg/terraform/justfile build

build-go:
	go build -v ./...

build: build-jsonnet build-go

push-jsonnet:
  @just -d pkg/terraform -f pkg/terraform/justfile push

push: push-jsonnet

install-go: build-go
	go install -v ./...

install: install-go
