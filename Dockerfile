# Start with the official Go image as a build stage
FROM golang:1.23.2 AS builder

# Set the current working directory inside the container
WORKDIR /app

# Copy the source code
COPY . .

WORKDIR /app

# Copy the go.mod and go.sum files and download dependencies
RUN go mod download

# Generate Swagger documentation
RUN go install github.com/swaggo/swag/cmd/swag@latest
RUN swag init -g cmd/main.go

# Build the application
RUN go build -o aks-secops-workload-identity-example cmd/main.go

# Use a minimal base image for the final build
FROM ubuntu:22.04

# Set the working directory inside the container
WORKDIR /app

# Install necessary dependencies
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy the built binary from the builder stage
COPY --from=builder /app/aks-secops-workload-identity-example .

# Expose the application port
EXPOSE 8080

# Command to run the application
CMD ["./aks-secops-workload-identity-example"]
