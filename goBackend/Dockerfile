# Build stage
FROM golang:1.24 AS builder

WORKDIR /app

# Copy dependency files and download modules
COPY go.mod ./
RUN go mod download

# Copy source code and data
COPY . .

# Build the Go binary
RUN CGO_ENABLED=0 GOOS=linux go build -o server .

# Final lightweight image
FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

# Copy binary and data files from builder
COPY --from=builder /app/server .
COPY --from=builder /app/study_results.csv .
COPY --from=builder /app/sus_responses.csv .

EXPOSE 8080
CMD ["./server"]
