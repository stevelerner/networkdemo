# Switch and PAT Features - Implementation Summary

This document summarizes the new Layer 2 switching and Port Address Translation (PAT) features added to the network demo.

## 🎯 What Was Added

### 1. **Layer 2 Switch (Open vSwitch)**
- **Container**: `switch`
- **Technology**: Open vSwitch 3.20
- **Network**: VLAN 30 (10.30.30.0/24)
- **Features**:
  - MAC address learning
  - OpenFlow flow tables
  - Port mirroring (SPAN)
  - Dynamic forwarding database

### 2. **PAT/NAPT Demonstrations**
- Enhanced NAT with explicit port translation demos
- Connection tracking visualization
- Ephemeral port range inspection
- Multiple client PAT examples

### 3. **Port Forwarding (DNAT)**
- Destination NAT demonstrations
- Port mapping examples
- Stateful connection tracking

### 4. **New Network Components**

| Component | IP Address | Purpose |
|-----------|------------|---------|
| `switch` | 10.30.30.2 | Open vSwitch for Layer 2 demos |
| `client30a` | 10.30.30.10 | Client connected through switch |
| `client30b` | 10.30.30.20 | Client connected through switch |
| `wan-service` | 172.20.0.200 | Nginx service for port forwarding demos |
| `router` (VLAN30) | 10.30.30.254 | Gateway for switched network |

**Note**: 10.30.30.1 is reserved as the Docker network gateway.

## 📁 Files Created

### Switch Container
```
networkdemo/switch/
├── Dockerfile                 # Open vSwitch container
├── entrypoint.sh             # Switch initialization script
├── show-mac-table.sh         # Helper: Display MAC learning table
├── enable-mirror.sh          # Helper: Enable port mirroring
├── disable-mirror.sh         # Helper: Disable port mirroring
└── show-flows.sh             # Helper: Display flow statistics
```

### Documentation
- Updated `README.md` with new demos and concepts
- Updated `docs/network-topology.svg` with VLAN 30 and switch
- Created `SWITCH-PAT-FEATURES.md` (this file)

### Configuration
- Updated `docker-compose.yml` with new services
- Updated `router/entrypoint.sh` for dynamic WAN interface detection
- Updated `Makefile` with new demo commands

## 🚀 Quick Start

### 1. Build and Start
```bash
cd /Volumes/external/code/networkdemo
make certs      # Generate certificates (if not done)
make up         # Start all containers including new switch
make status     # Verify all containers are running
```

### 2. Run New Demos

**Layer 2 Switching:**
```bash
make demo-switch
```
This demonstrates:
- MAC address learning
- Forwarding database population
- OpenFlow statistics
- ARP resolution

**Port Address Translation (PAT):**
```bash
make demo-pat
```
This demonstrates:
- Multiple internal IPs sharing one external IP
- Source port translation
- Connection tracking table
- Ephemeral port allocation

**Port Forwarding (DNAT):**
```bash
make demo-port-forward
```
This demonstrates:
- Destination NAT configuration
- External port to internal service mapping
- Stateful return path handling

**Port Mirroring (SPAN):**
```bash
make demo-switch-mirror
```
This demonstrates:
- Traffic mirroring configuration
- Passive monitoring setup
- IDS/IPS placement scenarios

### 3. Interactive Exploration

**Access switch shell:**
```bash
make shell-switch
```

**View MAC learning in real-time:**
```bash
docker exec switch ovs-appctl fdb/show br-switch30
```

**Monitor switch traffic:**
```bash
docker exec switch tcpdump -i any -n
```

**Check PAT connections:**
```bash
docker exec router cat /proc/net/nf_conntrack | grep ESTABLISHED
```

**Access new clients:**
```bash
make shell-client30a
make shell-client30b
```

## 📊 Demo Scenarios

### Scenario 1: MAC Learning
```bash
# View empty MAC table
docker exec switch ovs-appctl fdb/show br-switch30

# Generate traffic between clients
docker exec client30a ping -c 3 10.30.30.20

# View populated MAC table
docker exec switch ovs-appctl fdb/show br-switch30
```

### Scenario 2: PAT in Action
```bash
# Multiple clients accessing WAN
docker exec client10 curl -s http://172.20.0.100:8080 &
docker exec client20 curl -s http://172.20.0.100:8080 &
docker exec client30a curl -s http://172.20.0.100:8080 &

# View PAT translations (all share 172.20.0.254 with different ports)
docker exec router cat /proc/net/nf_conntrack | grep 172.20.0.100
```

### Scenario 3: Port Forwarding
```bash
# Add forwarding rule: Router:8888 -> WAN Service:80
docker exec router iptables -t nat -A PREROUTING -p tcp --dport 8888 \
  -j DNAT --to-destination 172.20.0.200:80

# Access from internal client
docker exec client10 curl http://172.20.0.254:8888

# View connection tracking
docker exec router cat /proc/net/nf_conntrack | grep 8888

# Remove rule
docker exec router iptables -t nat -D PREROUTING -p tcp --dport 8888 \
  -j DNAT --to-destination 172.20.0.200:80
```

### Scenario 4: Port Mirroring for IDS
```bash
# Enable mirroring
docker exec switch /enable-mirror.sh

# Start packet capture in one terminal
docker exec switch tcpdump -i any -n -w /tmp/capture.pcap

# Generate traffic in another terminal
docker exec client30a ping -c 10 10.30.30.20

# Disable mirroring
docker exec switch /disable-mirror.sh
```

## 🎓 Educational Value

### Layer 2 Concepts Demonstrated
- **MAC Learning**: Dynamic population of forwarding database
- **Frame Forwarding**: Unicast vs broadcast behavior
- **Port Mirroring**: Traffic replication for monitoring
- **ARP**: Layer 2/3 address resolution

### Layer 3/4 Concepts Demonstrated
- **PAT vs NAT**: Port translation vs address-only translation
- **DNAT**: Destination NAT for port forwarding
- **Connection Tracking**: Stateful session management
- **Port Exhaustion**: Understanding ephemeral port limits

### Real-World Applications
- **Enterprise Networks**: Switch operation in corporate networks
- **Home Routers**: PAT enables multiple devices sharing one IP
- **Port Forwarding**: Hosting services behind NAT
- **Network Monitoring**: IDS/IPS deployment with SPAN ports

## 🔧 Makefile Commands

### New Demo Commands
```bash
make demo-switch          # Layer 2 switching demo
make demo-pat            # Port Address Translation demo
make demo-port-forward   # Port forwarding (DNAT) demo
make demo-switch-mirror  # Port mirroring (SPAN) demo
```

### New Shell Access
```bash
make shell-switch        # Access switch container
make shell-client30a     # Access VLAN30 client A
make shell-client30b     # Access VLAN30 client B
```

### Updated Commands
```bash
make demo-all           # Now includes PAT and switch demos
```

## 📈 Network Topology Updates

The updated topology includes:

```
                          WAN (172.20.0.0/24)
                    ┌──────────────────────────┐
                    │  wan-host   wan-service  │
                    │  .100:8080    .200:80    │
                    └──────────┬───────────────┘
                               │ .254
                        ┌──────┴──────┐
                        │   ROUTER    │
                        │  (L3 + NAT) │
                        └──┬─────┬────┴┐
             .254      .254│     │.254 │
        ┌────────┬─────────┼─────┼─────┴─────┐
        │        │         │     │           │
    VLAN10   VLAN20    VLAN30   │           │
  .0/24      .0/24     .0/24     │           │
  ┌──────┐ ┌──────┐  ┌─────┐    │           │
  │ DNS  │ │ DNS  │  │SWITCH│◄───┘           │
  │Nginx │ │DHCP  │  │(OVS) │                │
  │Client│ │Client│  │  L2  │                │
  └──────┘ └──────┘  └──┬───┴─┐              │
                        │     │              │
                   Client30a Client30b       │
                   .10       .20             │
                                             │
                        Legend:              │
                        ━━━ Layer 3 (IP)     │
                        ─── Layer 2 (Ethernet)
```

## 🐛 Troubleshooting

### Switch Not Starting
```bash
docker logs switch
docker exec switch ovs-vsctl show
```

### MAC Table Empty
```bash
# Generate traffic to trigger learning
docker exec client30a ping -c 3 10.30.30.20
docker exec switch ovs-appctl fdb/show br-switch30
```

### PAT Not Working
```bash
# Check NAT rules
docker exec router iptables -t nat -L -n -v

# Check WAN interface detection
docker exec router ip -4 addr show | grep "inet 172.20.0"

# Verify forwarding enabled
docker exec router cat /proc/sys/net/ipv4/ip_forward  # Should be 1
```

### Port Forwarding Issues
```bash
# Check PREROUTING rules
docker exec router iptables -t nat -L PREROUTING -n -v

# Test from internal client
docker exec client10 curl -v http://172.20.0.254:8888
```

## 📚 Further Reading

### Open vSwitch
- Official Docs: http://www.openvswitch.org/
- OpenFlow Tutorial: http://www.openvswitch.org/support/dist-docs/

### NAT/PAT/DNAT
- RFC 3022 (Traditional NAT): https://tools.ietf.org/html/rfc3022
- RFC 4787 (NAT Behavioral Requirements): https://tools.ietf.org/html/rfc4787
- iptables NAT Tutorial: https://www.karlrupp.net/en/computer/nat_tutorial

### Layer 2 Switching
- IEEE 802.1D (Ethernet Bridge Operation)
- Understanding MAC Learning and Aging

## 🎉 Summary

This implementation adds comprehensive Layer 2 switching and advanced NAT capabilities to the network demo, completing the OSI model coverage from Layer 2 through Layer 7. The demo now includes:

- ✅ Layer 2: Switching, MAC learning, port mirroring
- ✅ Layer 3: Routing, NAT, PAT, DNAT
- ✅ Layer 4: Connection tracking, port translation
- ✅ Layer 7: DNS, DHCP, HTTPS, HTTP

Perfect for teaching, learning, and demonstrating enterprise networking concepts!

