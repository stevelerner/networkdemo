#!/bin/bash
set -e

echo "Starting Open vSwitch database..."
ovsdb-server --remote=punix:/var/run/openvswitch/db.sock \
    --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
    --pidfile --detach

echo "Initializing OVS database..."
ovs-vsctl --no-wait init || true

echo "Starting Open vSwitch daemon..."
ovs-vswitchd --pidfile --detach

echo "Waiting for OVS to be ready..."
sleep 2

# Create main bridge for VLAN30
echo "Creating bridge br-switch30..."
ovs-vsctl --may-exist add-br br-switch30

# Configure bridge
ovs-vsctl set bridge br-switch30 other-config:disable-in-band=true

# Add internal interface for switch management
ip link add vlan30-mgmt type dummy 2>/dev/null || true
ip link set vlan30-mgmt up
ip addr add 10.30.30.1/24 dev vlan30-mgmt 2>/dev/null || true

# Enable MAC learning logging
ovs-appctl vlog/set ofproto_dpif:file:dbg 2>/dev/null || true

echo "============================================"
echo "Switch initialized successfully!"
echo "Bridge: br-switch30"
echo "Management IP: 10.30.30.1/24"
echo "============================================"

# Show initial status
ovs-vsctl show

# Keep container running and show logs
tail -f /var/log/openvswitch/ovs-vswitchd.log 2>/dev/null &
tail -f /dev/null

