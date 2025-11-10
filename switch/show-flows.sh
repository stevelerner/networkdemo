#!/bin/bash
# Display OpenFlow flows and statistics

echo "============================================"
echo "OpenFlow Flow Table"
echo "============================================"
echo ""

echo "Flow entries with statistics:"
ovs-ofctl dump-flows br-switch30

echo ""
echo "============================================"
echo "Port Statistics"
echo "============================================"
ovs-ofctl dump-ports br-switch30

echo ""
echo "============================================"
echo "Port Descriptions"
echo "============================================"
ovs-ofctl show br-switch30

