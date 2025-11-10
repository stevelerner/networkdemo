FROM alpine:3.20

# Install Open vSwitch and networking tools
RUN apk add --no-cache \
    openvswitch \
    bash \
    iproute2 \
    tcpdump \
    bridge-utils \
    iptables \
    curl \
    && mkdir -p /var/run/openvswitch \
    && mkdir -p /etc/openvswitch

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

