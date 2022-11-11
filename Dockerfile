FROM golang:1.18-alpine AS builder

ENV CGO_ENABLED=0

RUN apk update \
    && apk add --no-cache git \
    && go install github.com/go-delve/delve/cmd/dlv@v1.8.3

WORKDIR /app

COPY . /app

RUN go build -o debuggable-pod -gcflags="all=-N -l" /app/main.go


EXPOSE 32345 32345

CMD [ "dlv", \
    "--listen=:32345", \
    "--headless=true", \
    "--api-version=2", \
    "--accept-multiclient", \
    "exec", "/app/debuggable-pod"]
