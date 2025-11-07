# 🎯 Interview Demo Script

This is your step-by-step guide for presenting the network demo in an interview setting.

---

## Pre-Interview Setup (5 minutes before)

```bash
cd /Volumes/external/code/networkingdemo
make certs
make up
make status
```

Verify everything is green before the interview starts.

---

## Demo Flow (15-20 minutes)

### 1. Introduction (2 minutes)

**What to say:**

> "I'd like to show you a network infrastructure demo I built to demonstrate my understanding of enterprise networking concepts. This is a fully functional environment running in Docker that simulates VLANs, routing, DNS, DHCP, NAT, firewall rules, and secure HTTPS—all from the command line."

**Show the architecture:**

Open `README.md` and scroll to the ASCII diagram:

> "Here's the logical topology. We have two VLANs isolated at layer 2, a router providing inter-VLAN connectivity and NAT to a simulated WAN, DNS services on both VLANs, DHCP on VLAN20, and a secure web application."

---

### 2. Connectivity Demo (2 minutes)

```bash
make demo-ping
```

**What to say:**

> "First, let me demonstrate basic connectivity. Client10 is on VLAN10 with a static IP. I can ping the nginx server in the same VLAN, and I can also reach services on VLAN20 because the router is forwarding traffic between VLANs."

**Key point:** Mention that without the router, these VLANs would be completely isolated.

---

### 3. DNS Demo (3 minutes)

```bash
make demo-dns
```

**What to say:**

> "I've set up CoreDNS as an authoritative name server for the `demo.local` zone. It's dual-homed on both VLANs so clients in either network can resolve internal hostnames without needing to cross VLANs for DNS queries."

**Show the zone file (optional):**

```bash
cat coredns/demo.local.zone
```

> "This is the zone file with A records for our services. In production, this might be integrated with dynamic DNS or service discovery like Consul."

---

### 4. HTTPS Demo (4 minutes)

```bash
make demo-https
```

**What to say:**

> "The nginx server is configured with TLS 1.2 and 1.3. I generated certificates using mkcert for local trust [or OpenSSL for self-signed]. Let me show you a secure connection."

**Bonus—show the certificate:**

```bash
docker exec client10 sh -c "echo | openssl s_client -connect 10.10.10.10:443 2>/dev/null | openssl x509 -noout -text | grep -A2 'Subject:'"
```

> "In a real environment, these would be certificates from Let's Encrypt, DigiCert, or an internal CA."

---

### 5. Routing Demo (3 minutes)

```bash
make demo-routing
```

**What to say:**

> "The router has IP forwarding enabled and uses iptables to control traffic flow. Let me show you a traceroute from VLAN10 to VLAN20—you'll see it hops through the router at 10.10.10.1."

**Show the firewall rules:**

```bash
docker exec router iptables -L FORWARD -v -n --line-numbers
```

> "I'm using a default-deny policy, then explicitly allowing inter-VLAN and WAN traffic. This is a security best practice—whitelist what you need, block everything else."

---

### 6. DHCP Demo (2 minutes)

```bash
make demo-dhcp
```

**What to say:**

> "VLAN20 uses DHCP with dnsmasq. Client20 automatically receives an IP from the 10.20.20.100-200 pool, plus the router as its gateway and CoreDNS as its DNS server."

**Show it in action:**

```bash
docker exec client20 ip addr show eth0 | grep "inet "
docker exec client20 ip route show
```

---

### 7. NAT Demo (2 minutes)

```bash
make demo-nat
```

**What to say:**

> "The router performs source NAT (masquerade) for traffic going to the WAN network. Internal clients appear as 172.20.0.1 when accessing external hosts. This is how corporate networks share a single public IP pool."

**Show NAT rules:**

```bash
docker exec router iptables -t nat -L POSTROUTING -v -n
```

---

### 8. Firewall Demo (3 minutes) - **This is your showstopper!**

```bash
make demo-firewall
```

**What to say:**

> "Now I'll demonstrate dynamic firewall control. I'm going to block VLAN20 from accessing the HTTPS service on VLAN10, test that it's blocked, then remove the rule and verify access is restored."

**Walk through each step as it happens:**

1. Show current rules
2. Add blocking rule
3. Test from client20 (fails)
4. Remove rule
5. Test again (succeeds)

> "This shows how firewall policies can be changed in real-time without service interruptions. In production, this would be automated via Ansible, Terraform, or a firewall management system."

---

### 9. Bonus: Live Monitoring (if time permits)

```bash
make monitor
```

**What to say:**

> "I've also got a monitoring container running tcpdump to capture traffic in real-time. This helps with troubleshooting and visibility."

Let it run for 5-10 seconds showing ICMP, DNS, or HTTPS packets, then Ctrl+C.

---

## Closing Statements

**Ask if they want to see anything specific:**

> "That's the core demo. We can dive deeper into any area—would you like to see the DNS zone file, the Nginx config, the iptables rules in detail, or anything else?"

**Be ready to troubleshoot live:**

If something breaks (it happens!), this is your moment to shine:

```bash
make status          # Check container health
make logs            # View logs
docker logs router   # Specific service logs
```

> "Let me check the logs... Ah, I see the issue..." 

This demonstrates debugging skills under pressure.

---

## Common Follow-Up Questions

### "How would you secure this further?"

- Add mutual TLS (client certificates)
- Implement DNSSEC
- Use VPN tunnels between VLANs
- Add IDS/IPS (Suricata)
- Implement zero-trust network access

### "How would you scale this?"

- Replace single router with HA pair (VRRP/HSRP)
- Add dynamic routing (OSPF/BGP)
- Use IPAM for address management
- Deploy load balancers for web tier
- Implement service mesh (Istio)

### "What's different in production?"

- Real switches with 802.1Q VLAN tagging
- Layer 3 switches or enterprise routers (Cisco, Juniper)
- Hardware load balancers (F5, Citrix)
- Cloud equivalents (AWS VPC, Azure VNet)
- Centralized management (Cisco DNA, Meraki)

### "Show me a failure scenario"

```bash
# Kill the router
docker stop router

# Try to reach VLAN20 from VLAN10
docker exec client10 ping -c2 10.20.20.53
# (Will fail—no route)

# Restart router
docker start router
sleep 3

# Try again
docker exec client10 ping -c2 10.20.20.53
# (Works!)
```

---

## Emergency Commands

If something goes wrong during the demo:

```bash
# Restart everything
make restart

# Check specific service
docker logs <service_name>

# Shell into a container to debug
make shell-client10

# Rebuild from scratch
make clean
make up
```

---

## Time Management

- **5-minute version:** Connectivity + DNS + HTTPS
- **10-minute version:** Add Routing + Firewall
- **15-minute version:** Add DHCP + NAT
- **20-minute version:** Full walkthrough + Q&A

Always prioritize the firewall demo—it's the most impressive visual proof of your skills.

---

## Post-Demo

Leave the terminal open with:

```bash
make monitor
```

This keeps traffic flowing and shows you're comfortable with continuous observation.

If they want the code:
> "I can send you the GitHub repo link [or zip file] after this call. Everything is documented in the README with instructions to run it themselves."

---

**You've got this! 🚀**

Remember: confidence, clarity, and the ability to explain *why* you made each choice is more important than perfect execution. If something breaks, your troubleshooting approach is what they're evaluating.

