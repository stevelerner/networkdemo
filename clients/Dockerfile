FROM alpine:3.20

# Install comprehensive networking and diagnostic tools
RUN apk add --no-cache \
    # Core networking
    iproute2 \
    iputils \
    net-tools \
    # DNS tools
    bind-tools \
    drill \
    # HTTP/HTTPS tools
    curl \
    wget \
    # Network scanning/testing
    nmap \
    nmap-scripts \
    tcpdump \
    netcat-openbsd \
    # Routing/tracing
    mtr \
    traceroute \
    # DHCP
    dhclient \
    # TLS/SSL tools
    openssl \
    # Process/system tools
    htop \
    procps \
    # Text processing
    vim \
    nano \
    bash \
    jq \
    # Additional utilities
    ca-certificates

# Create a helpful motd
RUN echo '#!/bin/sh' > /etc/profile.d/motd.sh && \
    echo 'echo "=================================================="' >> /etc/profile.d/motd.sh && \
    echo 'echo "Network Diagnostic Client"' >> /etc/profile.d/motd.sh && \
    echo 'echo "=================================================="' >> /etc/profile.d/motd.sh && \
    echo 'echo ""' >> /etc/profile.d/motd.sh && \
    echo 'echo "Hostname: $(hostname)"' >> /etc/profile.d/motd.sh && \
    echo 'echo "IP Address: $(hostname -i 2>/dev/null || echo Unknown)"' >> /etc/profile.d/motd.sh && \
    echo 'echo ""' >> /etc/profile.d/motd.sh && \
    echo 'echo "Available tools:"' >> /etc/profile.d/motd.sh && \
    echo 'echo "  ping, traceroute, mtr    - Network reachability"' >> /etc/profile.d/motd.sh && \
    echo 'echo "  dig, drill, nslookup     - DNS queries"' >> /etc/profile.d/motd.sh && \
    echo 'echo "  curl, wget               - HTTP/HTTPS requests"' >> /etc/profile.d/motd.sh && \
    echo 'echo "  nmap                     - Port scanning"' >> /etc/profile.d/motd.sh && \
    echo 'echo "  tcpdump                  - Packet capture"' >> /etc/profile.d/motd.sh && \
    echo 'echo "  netcat (nc)              - Network connections"' >> /etc/profile.d/motd.sh && \
    echo 'echo "  ip, route, ifconfig      - Interface management"' >> /etc/profile.d/motd.sh && \
    echo 'echo ""' >> /etc/profile.d/motd.sh && \
    echo 'echo "=================================================="' >> /etc/profile.d/motd.sh && \
    echo 'echo ""' >> /etc/profile.d/motd.sh && \
    chmod +x /etc/profile.d/motd.sh

# Set bash as default shell
ENV SHELL=/bin/bash
SHELL ["/bin/bash", "-c"]

# Default command: show motd and keep container alive
CMD ["/bin/bash", "-c", "source /etc/profile.d/motd.sh && tail -f /dev/null"]

