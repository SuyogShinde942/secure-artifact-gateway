FROM golang:1.25-alpine AS builder
WORKDIR /build
COPY . .
RUN go build -o gateway .

FROM alpine:3.21
COPY --from=builder /build/gateway /usr/local/bin/gateway
