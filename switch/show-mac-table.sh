#!/bin/bash
# Display MAC address learning table from Open vSwitch

echo "============================================"
echo "MAC Address Learning Table"
echo "============================================"
echo ""

# Show FDB (Forwarding Database)
echo "Bridge: br-switch30"
ovs-appctl fdb/show br-switch30

echo ""
echo "============================================"
echo "OpenFlow Flow Statistics"
echo "============================================"
ovs-ofctl dump-flows br-switch30

echo ""
echo "============================================"
echo "Bridge Status"
echo "============================================"
ovs-vsctl show

