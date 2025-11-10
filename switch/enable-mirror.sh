#!/bin/bash
# Enable port mirroring (SPAN) on the switch

echo "============================================"
echo "Enabling Port Mirroring (SPAN)"
echo "============================================"
echo ""

# Create mirror that selects all traffic
MIRROR_UUID=$(ovs-vsctl -- --id=@m create mirror name=mirror0 select-all=true)

if [ $? -eq 0 ]; then
    # Attach mirror to bridge
    ovs-vsctl -- set bridge br-switch30 mirrors=$MIRROR_UUID
    echo "✓ Port mirroring enabled successfully"
    echo ""
    echo "All traffic on br-switch30 is now being mirrored."
    echo ""
    echo "Mirror configuration:"
    ovs-vsctl list mirror
else
    echo "✗ Failed to create port mirror"
    exit 1
fi

echo ""
echo "============================================"
echo "To capture mirrored traffic, run:"
echo "  docker exec switch tcpdump -i any -n"
echo "============================================"

