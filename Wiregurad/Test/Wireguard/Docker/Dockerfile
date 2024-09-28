# Use the Alpine base image
FROM alpine:latest

# Install WireGuard and dependencies
RUN apk update && \
    apk add --no-cache \
    wireguard-tools \
    iproute2 \
    bash

# Copy the custom entrypoint script into the container
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the custom entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
