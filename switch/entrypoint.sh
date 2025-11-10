#!/bin/bash
set -e

echo "Initializing OVS database..."
# Create the database if it doesn't exist
if [ ! -f /etc/openvswitch/conf.db ]; then
    ovsdb-tool create /etc/openvswitch/conf.db /usr/share/openvswitch/vswitch.ovsschema
fi

echo "Starting Open vSwitch database..."
ovsdb-server --remote=punix:/var/run/openvswitch/db.sock \
    --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
    --pidfile --detach

sleep 1

echo "Initializing OVS..."
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

# Get container's IP address (assigned by Docker)
CONTAINER_IP=$(ip -4 addr show eth0 | grep inet | awk '{print $2}')

# Enable MAC learning logging
ovs-appctl vlog/set ofproto_dpif:file:dbg 2>/dev/null || true

echo "============================================"
echo "Switch initialized successfully!"
echo "Bridge: br-switch30"
echo "Management IP: $CONTAINER_IP"
echo "============================================"

# Show initial status
ovs-vsctl show

# Keep container running and show logs
tail -f /var/log/openvswitch/ovs-vswitchd.log 2>/dev/null &
tail -f /dev/null

