#!/bin/bash
# Disable port mirroring (SPAN) on the switch

echo "============================================"
echo "Disabling Port Mirroring (SPAN)"
echo "============================================"
echo ""

# Clear mirrors from bridge
ovs-vsctl clear bridge br-switch30 mirrors

if [ $? -eq 0 ]; then
    echo "✓ Port mirroring disabled successfully"
    echo ""
    echo "Remaining mirrors:"
    ovs-vsctl list mirror 2>/dev/null || echo "  (none)"
else
    echo "✗ Failed to disable port mirror"
    exit 1
fi

