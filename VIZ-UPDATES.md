# Visualization Updates

## What Was Fixed

The network visualization webapp has been updated to support the new switch and PAT features.

### Changes Made

#### 1. **Backend (`viz-webapp/app.py`)**
- ✅ Added `switch` node (10.30.30.2) with type 'switch'
- ✅ Added `client30a` node (10.30.30.10)
- ✅ Added `client30b` node (10.30.30.20)
- ✅ Added `wan-service` node (172.20.0.200)
- ✅ Added VLAN30 network definition with members
- ✅ Updated VLAN10 to include viz-webapp

#### 2. **Frontend (`viz-webapp/static/network.js`)**
- ✅ Added golden color (#fbbf24) for switch node type
- ✅ Added golden link color for vlan30 connections
- ✅ Improved force simulation:
  - Increased distance from 150 to 200
  - Increased repulsion from -400 to -800
  - Increased collision radius from 50 to 60
  - Added centering forces
- ✅ Changed initial positioning from random to circular layout
- ✅ Fixed scope issue by moving initVisualization() before node creation

### Total Network Components

The visualization now displays **11 containers** across **4 networks**:

**Nodes:**
1. router (10.10.10.254) - Orange
2. coredns (10.10.10.53) - Purple
3. nginx-app (10.10.10.10) - Green
4. client10 (10.10.10.100) - Blue
5. dnsmasq (10.20.20.2) - Pink
6. client20 (10.20.20.x) - Blue
7. **switch (10.30.30.2) - Golden** ← NEW
8. **client30a (10.30.30.10) - Blue** ← NEW
9. **client30b (10.30.30.20) - Blue** ← NEW
10. wan-host (172.20.0.100) - Gray
11. **wan-service (172.20.0.200) - Green** ← NEW

**Networks:**
1. VLAN 10 (10.10.10.0/24) - Blue links
2. VLAN 20 (10.20.20.0/24) - Pink links
3. **VLAN 30 (10.30.30.0/24) - Golden links** ← NEW
4. WAN (172.20.0.0/24) - Gray links

### How to Rebuild

If the visualization isn't showing the new components:

```bash
# Force rebuild without cache
cd /Volumes/external/code/networkdemo
docker compose build --no-cache viz
docker compose up -d viz

# Wait a moment then refresh browser
open http://localhost:8080
```

### Troubleshooting

**Issue**: Visualization shows "Connecting..." forever
- **Solution**: Rebuild the viz container without cache (see above)

**Issue**: Nodes are overlapping
- **Solution**: The circular layout should prevent this. Try dragging nodes to separate them, or refresh the browser to reset positions.

**Issue**: Some containers missing
- **Solution**: Check all containers are running with `docker compose ps`

### Features

The live visualization shows:
- ✅ Container nodes colored by type
- ✅ Network connections colored by VLAN
- ✅ Real-time traffic activity (nodes pulse when active)
- ✅ Draggable nodes (rearrange to your preference)
- ✅ Zoom and pan support
- ✅ Activity log showing traffic flows
- ✅ Container statistics (bytes/packets sent/received)
- ✅ Router firewall rules display

### Testing

To generate traffic and see the visualization in action:

```bash
# Layer 2 switch demo
make demo-switch

# Watch traffic in browser - you should see:
# - client30a and client30b nodes pulse
# - Activity log shows traffic between them
# - Switch node pulses as it forwards frames
```

### Network View

The topology now shows the complete 4-network architecture:
- **Top**: WAN with wan-host and wan-service
- **Center**: Router (hub connecting all VLANs)
- **Left**: VLAN 10 (static IPs) - DNS, Nginx, Client
- **Right Center**: VLAN 20 (DHCP) - DNS, DHCP, Client
- **Right**: VLAN 30 (Switched) - Switch, Client30A, Client30B

This matches the updated network topology diagram in `docs/network-topology.svg`!

