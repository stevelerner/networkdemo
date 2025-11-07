#!/bin/sh
set -e

echo "=========================================="
echo "ROUTER STARTING"
echo "=========================================="

# Wait for interfaces
sleep 3

# Check IP forwarding (set by Docker via sysctls)
echo "IP forwarding status:"
cat /proc/sys/net/ipv4/ip_forward

# Show interfaces
echo ""
echo "Network interfaces:"
ip addr show

# Basic iptables setup
echo "Configuring firewall..."

# Flush rules
iptables -F
iptables -t nat -F

# Set default policies
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Allow all forwarding for demo purposes
iptables -A FORWARD -j ACCEPT

# NAT for WAN
iptables -t nat -A POSTROUTING -o eth2 -j MASQUERADE

echo "Router configuration complete"
iptables -L -n -v
echo ""
iptables -t nat -L -n -v

echo "=========================================="
echo "ROUTER READY - Container will stay alive"
echo "=========================================="

# Keep container running
tail -f /dev/null
