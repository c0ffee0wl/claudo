set dotenv-load

image := "ghcr.io/gregmuellegger/claudo:latest"

build:
    docker build -t {{image}} .

push: build
    docker push {{image}}
