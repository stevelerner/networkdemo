# Network Infrastructure Demo

A comprehensive, self-contained Docker-based demonstration of enterprise networking concepts including VLAN segmentation, inter-VLAN routing, DNS, DHCP, HTTPS/TLS, NAT, and dynamic firewall rules.

**Perfect for technical interviews, learning, or showcasing networking knowledge.**

---

## Table of Contents

- [What This Demonstrates](#what-this-demonstrates)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Demo Scripts](#demo-scripts)
- [Talking Points for Interviews](#talking-points-for-interviews)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)

---

## What This Demonstrates

| Concept | Implementation | Real-World Equivalent |
|---------|---------------|----------------------|
| **VLAN Segmentation** | Docker user-defined bridges | 802.1Q VLAN tagging on switches |
| **Inter-VLAN Routing** | Router container with IP forwarding | Layer 3 switch or router |
| **DNS Resolution** | CoreDNS authoritative server | Internal DNS infrastructure |
| **DHCP** | dnsmasq DHCP server | DHCP server in enterprise network |
| **HTTPS/TLS** | Nginx with SSL certificates | Secure web services |
| **NAT** | iptables MASQUERADE | Corporate gateway NAT |
| **Firewall** | iptables with stateful rules | Enterprise firewall/ACLs |
| **Monitoring** | Live tcpdump traffic capture | Network monitoring tools |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        WAN Network                           │
│                     172.20.0.0/24                            │
│                                                              │
│  ┌──────────────┐                    ┌──────────────┐       │
│  │  Router      │                    │  WAN Host    │       │
│  │ 172.20.0.254 │◄──────NAT──────────│ 172.20.0.100 │       │
│  └──────┬───────┘                    └──────────────┘       │
└─────────┼────────────────────────────────────────────────────┘
          │
    ┌─────┴─────┐
    │           │
    │  ROUTER   │  (Inter-VLAN Routing + Firewall + NAT)
    │           │
    └─────┬─────┘
          │
    ┏━━━━━┻━━━━━┓
    ┃           ┃
┌───▼───────────▼──────────────────────┐  ┌──────────────────────────────────┐
│        VLAN 10                       │  │        VLAN 20                   │
│     10.10.10.0/24                    │  │     10.20.20.0/24                │
│                                      │  │                                  │
│  ┌────────────┐  ┌────────────┐     │  │  ┌────────────┐  ┌────────────┐  │
│  │  CoreDNS   │  │   Nginx    │     │  │  │  CoreDNS   │  │  dnsmasq   │  │
│  │10.10.10.53 │  │10.10.10.10 │     │  │  │10.20.20.53 │  │10.20.20.2  │  │
│  │ (DNS)      │  │ (HTTPS)    │     │  │  │ (DNS)      │  │  (DHCP)    │  │
│  └────────────┘  └────────────┘     │  │  └────────────┘  └────────────┘  │
│                                      │  │                                  │
│  ┌────────────┐                      │  │  ┌────────────┐                 │
│  │  client10  │                      │  │  │  client20  │                 │
│  │10.10.10.100│                      │  │  │ (DHCP IP)  │                 │
│  │  (Static)  │                      │  │  └────────────┘                 │
│  └────────────┘                      │  │                                  │
└──────────────────────────────────────┘  └──────────────────────────────────┘
```

### Network Details

- **VLAN 10 (10.10.10.0/24)**: Static IP assignments, hosts DNS and HTTPS services
- **VLAN 20 (10.20.20.0/24)**: DHCP-based assignments, separate L2 domain
- **WAN (172.20.0.0/24)**: Simulates external network access via NAT

---

## Quick Start

### Prerequisites

- Docker Desktop for Mac
- `make` (included on macOS)
- Optional: `mkcert` for trusted local certificates

### Installation

```bash
# 1. Clone or navigate to the project
cd /Volumes/external/code/networkingdemo

# 2. Generate SSL certificates
make certs

# 3. Start the environment
make up

# 4. Verify everything is running
make status
```

### Your First Demo

```bash
# Test DNS resolution
make demo-dns

# Test HTTPS connectivity
make demo-https

# Test inter-VLAN routing
make demo-routing

# Run all demos
make demo-all
```

---

## Demo Guide

### Running Demos

Each demo can be run individually using the Makefile commands. The demos are designed to showcase specific networking concepts and can be customized based on your needs.

**Quick demo sequence (5-10 minutes):**
```bash
make demo-ping      # Basic connectivity
make demo-dns       # DNS resolution
make demo-https     # Secure web access
make demo-firewall  # Dynamic firewall rules
```

**Full demo sequence (15-20 minutes):**
```bash
make demo-all       # Runs all demos in order
```

### Failure Scenario Testing

To demonstrate resilience and troubleshooting:

```bash
# Stop the router
docker stop router

# Test connectivity (will fail)
docker exec client10 ping -c2 10.20.20.53

# Restart router
docker start router
sleep 3

# Test again (should work)
docker exec client10 ping -c2 10.20.20.53
```

### Emergency Commands

If something goes wrong:

```bash
make restart        # Restart all containers
make status         # Check container health
make logs           # View all logs
docker logs router  # View specific service logs
make shell-client10 # Debug interactively
make clean && make up  # Full restart
```

---

## Demo Scripts

### 1. DNS Resolution Demo

```bash
make demo-dns
```

**Talking points:**
> CoreDNS is configured as an authoritative DNS server for the `demo.local` zone. It's dual-homed on both VLANs so clients in either network can resolve internal hostnames. This simulates split-horizon DNS in an enterprise environment.

**Technical details:**
- CoreDNS listens on `10.10.10.53` and `10.20.20.53`
- Zone file defines A records for services
- Clients use `dns` and `dns_search` Docker compose options

### 2. HTTPS Demo

```bash
make demo-https
```

**Talking points:**
> The Nginx server is configured with TLS 1.2/1.3 and serves HTTPS on port 443. Certificates are generated using mkcert for local trust (or OpenSSL for self-signed). This demonstrates proper SSL/TLS configuration and certificate chain validation.

**Technical details:**
- Nginx serves on `10.10.10.10:443`
- HTTP redirects to HTTPS (301)
- SNI, security headers, HTTP/2 enabled
- Clients can validate cert chain (with mkcert CA) or use `-k` for self-signed

### 3. Routing Demo

```bash
make demo-routing
```

**Talking points:**
> The router container has interfaces in all three networks. Kernel IP forwarding (`net.ipv4.ip_forward=1`) is enabled and iptables rules are configured to allow inter-VLAN traffic. Traceroute shows the hop through the router at `10.10.10.254` when reaching VLAN20 from VLAN10.

**Technical details:**
- Router uses dynamic interface detection (not hardcoded)
- `iptables -A FORWARD` rules control inter-VLAN flows
- Default policy is DROP (whitelist approach)
- Stateful connection tracking with `ESTABLISHED,RELATED`

### 4. DHCP Demo

```bash
make demo-dhcp
```

**Talking points:**
> dnsmasq is configured to serve DHCP on VLAN20 with a pool of 10.20.20.100-200. Client20 uses `udhcpc` (BusyBox DHCP client) to obtain an IP, gateway (router), and DNS server. This is how most enterprise networks distribute configuration.

**Technical details:**
- DHCP scope: `10.20.20.100-200`
- Gateway option: `10.20.20.254` (router)
- DNS option: `10.20.20.53` (CoreDNS)
- 12-hour lease time

### 5. NAT Demo

```bash
make demo-nat
```

**Talking points:**
> The router performs source NAT (MASQUERADE) for any traffic leaving to the WAN network. Internal clients appear as `172.20.0.254` when accessing external hosts. This is how enterprise networks share a single public IP among many private hosts.

**Technical details:**
- `iptables -t nat -A POSTROUTING -o wan_if -j MASQUERADE`
- Connection tracking in `/proc/net/nf_conntrack`
- Return traffic automatically translated (stateful NAT)

### 6. Firewall Demo

```bash
make demo-firewall
```

**Talking points:**
> A default-deny policy is used on the FORWARD chain. Rules can be dynamically added to allow or block specific flows. For example, blocking VLAN20 from reaching the HTTPS service, testing it, then removing the rule demonstrates real-time firewall policy changes.

**Technical details:**
- Default policy: `iptables -P FORWARD DROP`
- Specific allow rules for inter-VLAN and WAN access
- Can add logging with `-j LOG` for visibility
- Rules are applied immediately (no restart needed)

---

## Talking Points for Interviews

### Opening Statement

> This is a portable network infrastructure demo using Docker that showcases enterprise networking concepts. It simulates VLAN segmentation, routing, DNS, DHCP, NAT, and firewall rules—all from the command line.

### Key Concepts to Highlight

#### 1. **Separation of Concerns**
- VLANs provide L2 isolation
- Router acts as L3 gateway
- Services are single-purpose (DNS, DHCP, web)

#### 2. **Security Layers**
- Network segmentation (defense in depth)
- Firewall with default-deny policy
- TLS encryption for data in transit
- NAT hides internal addressing

#### 3. **Scalability Considerations**
- Static DNS can be replaced with DDNS
- DHCP can scale to multiple subnets
- Router can be HA pair (VRRP/HSRP)
- Could add OSPF/BGP for dynamic routing

#### 4. **Real-World Equivalents**

| Demo Component | Production Tech |
|----------------|-----------------|
| Docker bridges | Cisco VLANs with 802.1Q tagging |
| iptables router | Cisco ASA, Palo Alto, pfSense |
| CoreDNS | BIND9, Windows DNS, Route53 |
| dnsmasq DHCP | ISC DHCP, Windows DHCP, Infoblox |
| Nginx HTTPS | Load balancers (F5, HAProxy, ALB) |

### Common Questions & Answers

**Q: How does the router know which interface leads to which VLAN?**
> Docker assigns interfaces predictably (eth0, eth1, eth2) based on the order networks are attached in docker-compose.yml. The router uses simple interface detection. In production, VLAN tags (802.1Q) or interface names would be used.

**Q: What happens if the router fails?**
> In this demo, it's a single point of failure. In production, VRRP (Virtual Router Redundancy Protocol) can be deployed with two routers sharing a virtual IP. If the primary fails, the secondary takes over within seconds.

**Q: How would you secure this further?**
> - Add mutual TLS (client certificates)
> - Implement DNSSEC for zone signing
> - Use DNS-over-TLS/HTTPS for query encryption
> - Add IDS/IPS (Suricata)
> - Implement VPN tunnels between VLANs
> - Deploy zero-trust network access

**Q: How would you scale this?**
> - Replace single router with HA pair (VRRP/HSRP)
> - Add dynamic routing (OSPF/BGP)
> - Use IPAM for address management
> - Deploy load balancers for web tier
> - Implement service mesh (Istio)
> - Add centralized logging and monitoring

**Q: What's different in production?**
> - Real switches with 802.1Q VLAN tagging
> - Layer 3 switches or enterprise routers (Cisco, Juniper)
> - Hardware load balancers (F5, Citrix, Palo Alto)
> - Cloud equivalents (AWS VPC, Azure VNet, GCP VPC)
> - Centralized management (Cisco DNA, Meraki, Ansible)

**Q: Can you demonstrate firewall blocking?**
```bash
make demo-firewall
```

---

## Advanced Usage

### Access Container Shells

```bash
make shell-client10    # VLAN10 client
make shell-client20    # VLAN20 client
make shell-router      # Router
make shell-nginx       # Nginx web server
```

### Live Monitoring

```bash
# Watch traffic in real-time
make monitor

# Manual tcpdump on router
make tcpdump-router

# Check firewall stats
docker exec router iptables -L FORWARD -v -n
```

### Network Scanning

```bash
# Scan all hosts in VLAN10
make scan-vlan10

# Port scan the nginx server
make scan-nginx

# Scan from a client
docker exec client10 nmap -sV 10.10.10.10
```

### Manual Testing

```bash
# Test DNS
docker exec client10 dig @10.10.10.53 app.demo.local

# Test HTTPS
docker exec client10 curl -kv https://app.demo.local

# Test connectivity
docker exec client10 ping -c3 10.20.20.53

# Traceroute
docker exec client10 traceroute 10.20.20.2

# Check routes
docker exec client10 ip route show

# View ARP table
docker exec client10 arp -n
```

### Firewall Manipulation

```bash
# Block all ICMP (ping)
docker exec router iptables -A FORWARD -p icmp -j DROP

# Allow only specific port
docker exec router iptables -I FORWARD -p tcp --dport 80 -j ACCEPT

# Log all forwarded packets
docker exec router iptables -I FORWARD -j LOG --log-prefix "[FW] "

# View logs
docker logs router

# Flush all rules (reset)
docker exec router iptables -F FORWARD
```

---

## Troubleshooting

### Issue: Certificates not trusted

**Solution 1 (mkcert):**
```bash
brew install mkcert
mkcert -install
make clean-all
make certs
make up
```

**Solution 2 (accept self-signed):**
```bash
# Use -k flag with curl
docker exec client10 curl -k https://app.demo.local
```

### Issue: DHCP not working on client20

Check logs:
```bash
docker logs client20
docker logs dnsmasq
```

Manually request DHCP:
```bash
docker exec client20 udhcpc -i eth0 -f -v
```

### Issue: DNS not resolving

Test DNS directly:
```bash
# Query CoreDNS
docker exec client10 dig @10.10.10.53 app.demo.local

# Check CoreDNS logs
docker logs coredns

# Verify zone file
docker exec coredns cat /zones/demo.local
```

### Issue: No connectivity between VLANs

Check router:
```bash
# Verify IP forwarding
docker exec router cat /proc/sys/net/ipv4/ip_forward  # Should be 1

# Check firewall rules
docker exec router iptables -L FORWARD -v -n

# Test manually
docker exec client10 ping 10.20.20.53
```

### Issue: Containers not starting

```bash
# Check status
docker compose ps

# View logs for specific service
docker compose logs coredns
docker compose logs router

# Rebuild from scratch
make clean-all
make certs
make up
```

---

## Additional Resources

### Learn More

- **Docker Networking**: https://docs.docker.com/network/
- **iptables Tutorial**: https://www.frozentux.net/iptables-tutorial/iptables-tutorial.html
- **CoreDNS Docs**: https://coredns.io/manual/toc/
- **Nginx SSL Config**: https://ssl-config.mozilla.org/

### Extend This Demo

Ideas for enhancement:
1. **Add OSPF routing** using FRRouting
2. **Implement VPN** with OpenVPN or WireGuard
3. **Add IDS/IPS** with Suricata
4. **Load balancing** with HAProxy
5. **Monitoring** with Prometheus + Grafana
6. **Log aggregation** with ELK stack
7. **Service mesh** with Istio

---

## Makefile Commands Reference

```bash
make help           # Show all available commands
make certs          # Generate SSL certificates
make up             # Start all containers
make down           # Stop all containers
make status         # Show container status
make logs           # View all logs
make monitor        # Watch live traffic
make clean          # Remove containers, networks, volumes
make clean-all      # Remove everything including images and certs

# Demos
make demo-dns       # DNS resolution demo
make demo-https     # HTTPS demo
make demo-ping      # Connectivity demo
make demo-routing   # Inter-VLAN routing demo
make demo-dhcp      # DHCP demo
make demo-nat       # NAT demo
make demo-firewall  # Firewall demo
make demo-all       # Run all demos

# Shell access
make shell-client10 # Access VLAN10 client
make shell-client20 # Access VLAN20 client
make shell-router   # Access router

# Diagnostics
make scan-vlan10    # Network scan VLAN10
make scan-nginx     # Port scan nginx
make health         # Health check all services
```

---

## License

This is a demonstration project for educational purposes. Feel free to use, modify, and share.

---

## Contributing

Found a bug or have an improvement? Feel free to:
1. Test the change locally
2. Update documentation
3. Share your enhancements

---

## Additional Demo Commands

### Inspect Zone Files
```bash
cat coredns/demo.local.zone      # View DNS records
cat dnsmasq/dnsmasq.conf         # View DHCP configuration
cat nginx/default.conf           # View Nginx configuration
```

### Show Certificate Details
```bash
docker exec client10 sh -c "echo | openssl s_client -connect 10.10.10.10:443 2>/dev/null | openssl x509 -noout -text | grep -A2 'Subject:'"
```

### Monitor Live Traffic
```bash
make monitor                     # Watch packets in real-time
make tcpdump-router              # Detailed packet capture
```

---

## Notes

This demo is designed for educational purposes and technical presentations. It showcases core networking concepts in a portable, reproducible environment using Docker.

