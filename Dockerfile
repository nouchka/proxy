FROM golang:1.25-alpine AS builder

WORKDIR /src

# Install build dependencies
RUN apk add --no-cache git

# Copy go mod files first for caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /proxy ./cmd/proxy

FROM alpine:3.21

RUN apk add --no-cache ca-certificates curl

COPY --from=builder /proxy /usr/local/bin/proxy

# Create non-root user
RUN adduser -D -u 1000 proxy
USER proxy

# Default data directory
WORKDIR /data

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS --max-time 3 http://localhost:8080/health || exit 1

ENTRYPOINT ["proxy"]
CMD ["serve"]
