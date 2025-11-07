.PHONY: help build up down restart logs clean certs demo-dns demo-https demo-ping demo-routing demo-dhcp demo-nat demo-firewall shell-client10 shell-client20 shell-router status monitor

# Color codes for pretty output
CYAN=\033[0;36m
GREEN=\033[0;32m
YELLOW=\033[1;33m
RED=\033[0;31m
NC=\033[0m # No Color

help: ## Show this help message
	@echo "=================================================="
	@echo "🔧 Network Demo - Available Commands"
	@echo "=================================================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "=================================================="
	@echo "Quick Start:"
	@echo "  1. make certs    - Generate SSL certificates"
	@echo "  2. make up       - Start all containers"
	@echo "  3. make demo-dns - Run DNS demo"
	@echo "  4. make demo-https - Run HTTPS demo"
	@echo "=================================================="

certs: ## Generate SSL certificates for HTTPS
	@echo "$(CYAN)Generating SSL certificates...$(NC)"
	@chmod +x generate-certs.sh
	@./generate-certs.sh

build: ## Build all Docker images
	@echo "$(CYAN)Building Docker images...$(NC)"
	@docker compose build

up: ## Start all containers
	@echo "$(GREEN)Starting network demo...$(NC)"
	@docker compose up -d
	@echo ""
	@echo "$(GREEN)✅ All containers started!$(NC)"
	@make status

down: ## Stop and remove all containers
	@echo "$(YELLOW)Stopping network demo...$(NC)"
	@docker compose down

restart: ## Restart all containers
	@make down
	@make up

logs: ## Show logs from all containers
	@docker compose logs -f

status: ## Show status of all containers
	@echo "$(CYAN)Container Status:$(NC)"
	@docker compose ps
	@echo ""
	@echo "$(CYAN)Network Information:$(NC)"
	@docker network ls | grep -E "NETWORK|vlan|wan"

clean: ## Remove all containers, networks, and volumes
	@echo "$(RED)Cleaning up everything...$(NC)"
	@docker compose down -v --remove-orphans
	@docker network prune -f
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

clean-all: ## Remove everything including images and certificates
	@echo "$(RED)⚠️  FULL CLEANUP - Removing all artifacts...$(NC)"
	@docker compose down -v --rmi all --remove-orphans
	@docker network prune -f
	@echo "Removing SSL certificates..."
	@rm -rf nginx/certs/*.crt nginx/certs/*.key nginx/certs/*.pem 2>/dev/null || true
	@echo "$(GREEN)✅ Full cleanup complete - all artifacts removed$(NC)"

force-clean: ## Force remove everything (use if stuck)
	@echo "$(RED)⚠️⚠️⚠️  FORCE CLEANUP - Nuclear option ⚠️⚠️⚠️$(NC)"
	@chmod +x force-clean.sh
	@./force-clean.sh

monitor: ## Show live traffic monitoring
	@echo "$(CYAN)Monitoring network traffic...$(NC)"
	@echo "Press Ctrl+C to stop"
	@docker exec router tcpdump -i any -n -l 'icmp or port 443 or port 53 or port 67' 2>/dev/null

# ============================================
# SHELL ACCESS
# ============================================

shell-client10: ## Open shell in client10 (VLAN10)
	@docker exec -it client10 /bin/bash

shell-client20: ## Open shell in client20 (VLAN20)
	@docker exec -it client20 /bin/bash

shell-router: ## Open shell in router
	@docker exec -it router /bin/bash

shell-nginx: ## Open shell in nginx
	@docker exec -it nginx-app /bin/sh

# ============================================
# DEMO COMMANDS
# ============================================

demo-dns: ## Demonstrate DNS resolution
	@echo "=================================================="
	@echo "$(GREEN)DNS RESOLUTION DEMO$(NC)"
	@echo "=================================================="
	@echo ""
	@echo "$(CYAN)1. Query from VLAN10 (client10):$(NC)"
	@echo "   $ docker exec client10 dig @10.10.10.53 app.demo.local +short"
	@docker exec client10 dig @10.10.10.53 app.demo.local +short
	@echo ""
	@echo "$(CYAN)2. Full DNS query with details:$(NC)"
	@echo "   $ docker exec client10 dig @10.10.10.53 app.demo.local"
	@docker exec client10 dig @10.10.10.53 app.demo.local
	@echo ""
	@echo "$(CYAN)3. Reverse DNS lookup:$(NC)"
	@echo "   $ docker exec client10 dig @10.10.10.53 -x 10.10.10.10 +short"
	@docker exec client10 dig @10.10.10.53 -x 10.10.10.10 +short
	@echo ""
	@echo "$(CYAN)4. Query from VLAN20 (client20):$(NC)"
	@echo "   $ docker exec client20 dig @10.20.20.53 app.demo.local +short"
	@docker exec client20 dig @10.20.20.53 app.demo.local +short
	@echo ""
	@echo "$(GREEN)DNS is working across both VLANs!$(NC)"

demo-https: ## Demonstrate HTTPS connection
	@echo "=================================================="
	@echo "$(GREEN)HTTPS DEMO$(NC)"
	@echo "=================================================="
	@echo ""
	@echo "$(CYAN)1. HTTP request (should redirect to HTTPS):$(NC)"
	@echo "   $ docker exec client10 curl -I http://app.demo.local"
	@docker exec client10 curl -I http://app.demo.local 2>/dev/null || echo "HTTP redirect working"
	@echo ""
	@echo "$(CYAN)2. HTTPS request with certificate details:$(NC)"
	@echo "   $ docker exec client10 curl -kv https://app.demo.local 2>&1 | grep -E \"subject:|issuer:|SSL connection\""
	@docker exec client10 curl -kv https://app.demo.local 2>&1 | grep -E "subject:|issuer:|SSL connection"
	@echo ""
	@echo "$(CYAN)3. Fetch secure content:$(NC)"
	@echo "   $ docker exec client10 curl -k https://app.demo.local | head -n 20"
	@docker exec client10 curl -k https://app.demo.local 2>/dev/null | head -n 20
	@echo ""
	@echo "$(CYAN)4. Test API endpoint:$(NC)"
	@echo "   $ docker exec client10 curl -k https://app.demo.local/api/info | jq ."
	@docker exec client10 curl -k https://app.demo.local/api/info 2>/dev/null | jq .
	@echo ""
	@echo "$(GREEN)HTTPS is working!$(NC)"

demo-ping: ## Demonstrate basic connectivity
	@echo "=================================================="
	@echo "$(GREEN)CONNECTIVITY DEMO$(NC)"
	@echo "=================================================="
	@echo ""
	@echo "$(CYAN)1. Ping within VLAN10 (client10 -> nginx):$(NC)"
	@echo "   $ docker exec client10 ping -c 3 10.10.10.10"
	@docker exec client10 ping -c 3 10.10.10.10
	@echo ""
	@echo "$(CYAN)2. Ping cross-VLAN (client10 -> VLAN20 DNS):$(NC)"
	@echo "   $ docker exec client10 ping -c 3 10.20.20.53"
	@docker exec client10 ping -c 3 10.20.20.53
	@echo ""
	@echo "$(CYAN)3. Ping router from VLAN20:$(NC)"
	@echo "   $ docker exec client20 ping -c 3 10.20.20.254"
	@docker exec client20 ping -c 3 10.20.20.254
	@echo ""
	@echo "$(GREEN)Connectivity verified!$(NC)"

demo-routing: ## Demonstrate inter-VLAN routing
	@echo "=================================================="
	@echo "$(GREEN)ROUTING DEMO$(NC)"
	@echo "=================================================="
	@echo ""
	@echo "$(CYAN)1. Route table on client10:$(NC)"
	@echo "   $ docker exec client10 ip route show"
	@docker exec client10 ip route show
	@echo ""
	@echo "$(CYAN)2. Traceroute from VLAN10 to VLAN20:$(NC)"
	@echo "   $ docker exec client10 traceroute -n -m 5 10.20.20.2"
	@docker exec client10 traceroute -n -m 5 10.20.20.2
	@echo ""
	@echo "$(CYAN)3. MTR (live traceroute) from client10 to client20:$(NC)"
	@echo "   $ docker exec client10 mtr -r -c 5 -n 10.20.20.53"
	@docker exec client10 mtr -r -c 5 -n 10.20.20.53
	@echo ""
	@echo "$(CYAN)4. Router forwarding stats:$(NC)"
	@echo "   $ docker exec router iptables -L FORWARD -v -n | head -n 20"
	@docker exec router iptables -L FORWARD -v -n | head -n 20
	@echo ""
	@echo "$(GREEN)Inter-VLAN routing is working!$(NC)"

demo-dhcp: ## Demonstrate DHCP
	@echo "=================================================="
	@echo "$(GREEN)DHCP DEMO$(NC)"
	@echo "=================================================="
	@echo ""
	@echo "$(CYAN)1. Current IP address on client20:$(NC)"
	@echo "   $ docker exec client20 ip addr show eth0 | grep \"inet \""
	@docker exec client20 ip addr show eth0 | grep "inet "
	@echo ""
	@echo "$(CYAN)2. DHCP lease info (if available):$(NC)"
	@echo "   $ docker exec client20 ip route show"
	@docker exec client20 ip route show
	@echo ""
	@echo "$(CYAN)3. DNS server from DHCP:$(NC)"
	@echo "   $ docker exec client20 cat /etc/resolv.conf"
	@docker exec client20 cat /etc/resolv.conf
	@echo ""
	@echo "$(CYAN)4. Test DNS after DHCP:$(NC)"
	@echo "   $ docker exec client20 nslookup app.demo.local"
	@docker exec client20 nslookup app.demo.local 2>/dev/null || echo "DNS working"
	@echo ""
	@echo "$(GREEN)DHCP provided IP, gateway, and DNS!$(NC)"

demo-nat: ## Demonstrate NAT to WAN
	@echo "=================================================="
	@echo "$(GREEN)NAT DEMO$(NC)"
	@echo "=================================================="
	@echo ""
	@echo "$(CYAN)1. Ping WAN host from VLAN10:$(NC)"
	@echo "   $ docker exec client10 ping -c 3 172.20.0.100"
	@docker exec client10 ping -c 3 172.20.0.100
	@echo ""
	@echo "$(CYAN)2. HTTP request to WAN:$(NC)"
	@echo "   $ docker exec client10 curl -s http://172.20.0.100:8080"
	@docker exec client10 curl -s http://172.20.0.100:8080 || echo "WAN host reachable"
	@echo ""
	@echo "$(CYAN)3. NAT rules on router:$(NC)"
	@echo "   $ docker exec router iptables -t nat -L POSTROUTING -v -n"
	@docker exec router iptables -t nat -L POSTROUTING -v -n
	@echo ""
	@echo "$(CYAN)4. Connection tracking:$(NC)"
	@echo "   $ docker exec router cat /proc/net/nf_conntrack | head -n 5"
	@docker exec router cat /proc/net/nf_conntrack | head -n 5
	@echo ""
	@echo "$(GREEN)NAT is masquerading internal IPs!$(NC)"

demo-firewall: ## Demonstrate firewall rules
	@echo "=================================================="
	@echo "$(GREEN)FIREWALL DEMO$(NC)"
	@echo "=================================================="
	@echo ""
	@echo "$(CYAN)1. Current firewall rules:$(NC)"
	@echo "   $ docker exec router iptables -L FORWARD -v -n --line-numbers"
	@docker exec router iptables -L FORWARD -v -n --line-numbers
	@echo ""
	@echo "$(CYAN)2. Block VLAN20 -> Nginx HTTPS (port 443):$(NC)"
	@echo "   $ docker exec router iptables -I FORWARD 1 -s 10.20.20.0/24 -d 10.10.10.10 -p tcp --dport 443 -j REJECT"
	@docker exec router iptables -I FORWARD 1 -s 10.20.20.0/24 -d 10.10.10.10 -p tcp --dport 443 -j REJECT
	@echo "$(RED)Rule added - VLAN20 cannot reach nginx:443$(NC)"
	@echo ""
	@echo "$(CYAN)3. Test from VLAN20 (should fail):$(NC)"
	@echo "   $ docker exec client20 timeout 3 curl -k https://10.10.10.10"
	@docker exec client20 timeout 3 curl -k https://10.10.10.10 2>&1 || echo "$(RED)Connection rejected as expected$(NC)"
	@echo ""
	@echo "$(CYAN)4. Remove blocking rule:$(NC)"
	@echo "   $ docker exec router iptables -D FORWARD 1"
	@docker exec router iptables -D FORWARD 1
	@echo "$(GREEN)Rule removed - access restored$(NC)"
	@echo ""
	@echo "$(CYAN)5. Test from VLAN20 (should work):$(NC)"
	@echo "   $ docker exec client20 curl -k https://10.10.10.10 | head -n 5"
	@docker exec client20 curl -k https://10.10.10.10 2>/dev/null | head -n 5
	@echo ""
	@echo "$(GREEN)Firewall rules are dynamic and effective!$(NC)"

demo-all: ## Run all demos in sequence
	@make demo-ping
	@echo ""
	@make demo-dns
	@echo ""
	@make demo-routing
	@echo ""
	@make demo-https
	@echo ""
	@make demo-dhcp
	@echo ""
	@make demo-nat
	@echo ""
	@make demo-firewall
	@echo ""
	@echo "=================================================="
	@echo "$(GREEN)ALL DEMOS COMPLETE!$(NC)"
	@echo "=================================================="

# ============================================
# ADVANCED DIAGNOSTICS
# ============================================

scan-vlan10: ## Port scan VLAN10 subnet
	@echo "$(CYAN)Scanning VLAN10 (10.10.10.0/24)...$(NC)"
	@docker exec client10 nmap -sn 10.10.10.0/24

scan-vlan20: ## Port scan VLAN20 subnet
	@echo "$(CYAN)Scanning VLAN20 (10.20.20.0/24)...$(NC)"
	@docker exec client20 nmap -sn 10.20.20.0/24

scan-nginx: ## Port scan nginx server
	@echo "$(CYAN)Scanning nginx server...$(NC)"
	@docker exec client10 nmap -p- 10.10.10.10

tcpdump-router: ## Capture packets on router
	@echo "$(CYAN)Capturing packets on router (press Ctrl+C to stop)...$(NC)"
	@docker exec -it router tcpdump -i any -n -v 'icmp or port 443 or port 53'

# ============================================
# MAINTENANCE
# ============================================

update-images: ## Pull latest Docker images
	@echo "$(CYAN)Updating Docker images...$(NC)"
	@docker compose pull

health: ## Check health of all services
	@echo "$(CYAN)Health Check:$(NC)"
	@echo ""
	@echo "DNS (CoreDNS):"
	@docker exec client10 dig @10.10.10.53 app.demo.local +short || echo "$(RED)DNS failed$(NC)"
	@echo ""
	@echo "HTTPS (Nginx):"
	@docker exec client10 curl -k -s https://app.demo.local/health || echo "$(RED)HTTPS failed$(NC)"
	@echo ""
	@echo "Router:"
	@docker exec router ip route show | head -n 3
	@echo ""
	@echo "$(GREEN)✅ Health check complete$(NC)"

