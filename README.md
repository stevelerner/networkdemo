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
│  │ 172.20.0.1   │◄──────NAT──────────│ 172.20.0.100 │       │
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

- Docker Desktop for Mac (or Docker + Docker Compose on Linux)
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
> The router container has interfaces in all three networks. Kernel IP forwarding (`net.ipv4.ip_forward=1`) is enabled and iptables rules are configured to allow inter-VLAN traffic. Traceroute shows the hop through the router at `10.10.10.1` when reaching VLAN20 from VLAN10.

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
- Gateway option: `10.20.20.1` (router)
- DNS option: `10.20.20.53` (CoreDNS)
- 12-hour lease time

### 5. NAT Demo

```bash
make demo-nat
```

**Talking points:**
> The router performs source NAT (MASQUERADE) for any traffic leaving to the WAN network. Internal clients appear as `172.20.0.1` when accessing external hosts. This is how enterprise networks share a single public IP among many private hosts.

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

### Common Interview Questions & Answers

**Q: How does the router know which interface leads to which VLAN?**
> Interfaces are detected dynamically by IP address using `ip -o addr show | grep` rather than hardcoding eth0/eth1. In production, interface names or VLAN tags would be used.

**Q: What happens if the router fails?**
> In this demo, it's a single point of failure. In production, VRRP (Virtual Router Redundancy Protocol) can be deployed with two routers sharing a virtual IP. If the primary fails, the secondary takes over within seconds.

**Q: How do you secure DNS?**
> This demo uses plain DNS. For security, DNSSEC can be implemented for zone signing, DNS-over-TLS/HTTPS for query encryption, and rate limiting to prevent amplification attacks.

**Q: Can you show me the firewall blocking something?**
> Yes, VLAN20 can be blocked from reaching the HTTPS server on port 443.
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
make clean
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
make clean
make build
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

## Tips for Your Interview

1. **Practice the demos** before the interview—know exactly what each command will output
2. **Be ready to explain** why you made specific choices (e.g., CoreDNS vs BIND)
3. **Show depth** by discussing how you'd scale this in production
4. **Troubleshoot live** if something breaks—that's impressive too
5. **Connect to real systems** by mentioning Cisco, AWS, or other tools they might use

---

**Good luck!**

If you have questions or want to discuss networking concepts, feel free to reach out.

