#!/bin/bash
set -e

echo "=================================================="
echo "ROUTER INITIALIZATION"
echo "=================================================="

# Wait for network interfaces to be ready
sleep 2

# Enable IPv4 forwarding
echo "Enabling IPv4 forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward

# Show all interfaces for debugging
echo "Available interfaces:"
ip addr show

# Detect interfaces by IP address
echo ""
echo "Detecting network interfaces..."
VLAN10_IF=$(ip -o addr show | grep "10.10.10.254" | awk '{print $2}' | head -n1 || echo "")
VLAN20_IF=$(ip -o addr show | grep "10.20.20.254" | awk '{print $2}' | head -n1 || echo "")
WAN_IF=$(ip -o addr show | grep "172.20.0.254" | awk '{print $2}' | head -n1 || echo "")

if [ -z "$VLAN10_IF" ] || [ -z "$VLAN20_IF" ] || [ -z "$WAN_IF" ]; then
    echo "ERROR: Could not detect all interfaces!"
    echo "VLAN10_IF: $VLAN10_IF"
    echo "VLAN20_IF: $VLAN20_IF"
    echo "WAN_IF: $WAN_IF"
    exit 1
fi

echo "  VLAN10: $VLAN10_IF (10.10.10.254)"
echo "  VLAN20: $VLAN20_IF (10.20.20.254)"
echo "  WAN:    $WAN_IF (172.20.0.254)"

echo ""
echo "=================================================="
echo "CONFIGURING FIREWALL (iptables)"
echo "=================================================="

# Flush existing rules
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Set default policies
iptables -P INPUT ACCEPT
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

echo "Default FORWARD policy: DROP"

# Allow established/related connections (stateful firewall)
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
echo "Allow ESTABLISHED,RELATED connections"

# Allow inter-VLAN routing (VLAN10 <-> VLAN20)
iptables -A FORWARD -i "$VLAN10_IF" -o "$VLAN20_IF" -j ACCEPT
iptables -A FORWARD -i "$VLAN20_IF" -o "$VLAN10_IF" -j ACCEPT
echo "Allow inter-VLAN routing (VLAN10 <-> VLAN20)"

# Allow VLAN10 to WAN
iptables -A FORWARD -i "$VLAN10_IF" -o "$WAN_IF" -j ACCEPT
echo "Allow VLAN10 -> WAN"

# Allow VLAN20 to WAN
iptables -A FORWARD -i "$VLAN20_IF" -o "$WAN_IF" -j ACCEPT
echo "Allow VLAN20 -> WAN"

# NAT for outbound traffic to WAN
iptables -t nat -A POSTROUTING -o "$WAN_IF" -j MASQUERADE
echo "NAT (MASQUERADE) enabled on $WAN_IF"

# Optional: Log dropped packets for debugging
# iptables -A FORWARD -j LOG --log-prefix "[ROUTER-DROP] " --log-level 4

echo ""
echo "=================================================="
echo "FIREWALL RULES SUMMARY"
echo "=================================================="
iptables -L FORWARD -v -n --line-numbers

echo ""
echo "=================================================="
echo "NAT RULES"
echo "=================================================="
iptables -t nat -L POSTROUTING -v -n --line-numbers

echo ""
echo "=================================================="
echo "ROUTER READY"
echo "=================================================="
echo ""

# Keep container running and show live iptables stats every 30s
while true; do
    sleep 30
    echo "[$(date)] Router alive - Packet stats:"
    iptables -L FORWARD -v -n -x | grep -E "pkts|Chain" | head -n10
done

