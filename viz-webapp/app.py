#!/usr/bin/env python3
import json
import time
from flask import Flask, render_template, jsonify
from flask_socketio import SocketIO, emit
import docker
import threading

app = Flask(__name__)
app.config['SECRET_KEY'] = 'network-demo-viz'
socketio = SocketIO(app, cors_allowed_origins='*')

# Docker client
client = docker.from_env()

# Network topology configuration
TOPOLOGY = {
    'nodes': [
        {'id': 'router', 'label': 'Router', 'type': 'router', 'ip': '10.10.10.254'},
        {'id': 'coredns', 'label': 'CoreDNS', 'type': 'dns', 'ip': '10.10.10.53'},
        {'id': 'nginx-app', 'label': 'Nginx HTTPS', 'type': 'web', 'ip': '10.10.10.10'},
        {'id': 'client10', 'label': 'Client10', 'type': 'client', 'ip': '10.10.10.100'},
        {'id': 'dnsmasq', 'label': 'DHCP Server', 'type': 'dhcp', 'ip': '10.20.20.2'},
        {'id': 'client20', 'label': 'Client20', 'type': 'client', 'ip': '10.20.20.x'},
        {'id': 'wan-host', 'label': 'WAN Host', 'type': 'external', 'ip': '172.20.0.100'}
    ],
    'networks': [
        {'id': 'vlan10', 'label': 'VLAN 10 (10.10.10.0/24)', 'members': ['router', 'coredns', 'nginx-app', 'client10']},
        {'id': 'vlan20', 'label': 'VLAN 20 (10.20.20.0/24)', 'members': ['router', 'coredns', 'dnsmasq', 'client20']},
        {'id': 'wan', 'label': 'WAN (172.20.0.0/24)', 'members': ['router', 'wan-host']}
    ]
}

def get_container_stats(container_name):
    """Get network stats for a container"""
    try:
        container = client.containers.get(container_name)
        stats = container.stats(stream=False)
        
        # Extract network stats
        networks = stats.get('networks', {})
        total_rx = sum(net.get('rx_bytes', 0) for net in networks.values())
        total_tx = sum(net.get('tx_bytes', 0) for net in networks.values())
        total_rx_packets = sum(net.get('rx_packets', 0) for net in networks.values())
        total_tx_packets = sum(net.get('tx_packets', 0) for net in networks.values())
        
        return {
            'rx_bytes': total_rx,
            'tx_bytes': total_tx,
            'rx_packets': total_rx_packets,
            'tx_packets': total_tx_packets,
            'status': 'running'
        }
    except Exception as e:
        return {
            'rx_bytes': 0,
            'tx_bytes': 0,
            'rx_packets': 0,
            'tx_packets': 0,
            'status': 'error',
            'error': str(e)
        }

def get_router_iptables():
    """Get iptables stats from router"""
    try:
        container = client.containers.get('router')
        result = container.exec_run('iptables -L FORWARD -v -n -x')
        if result.exit_code == 0:
            return result.output.decode('utf-8')
        return None
    except:
        return None

def monitor_network():
    """Background thread to monitor network activity"""
    previous_stats = {}
    
    while True:
        try:
            current_stats = {}
            activity = []
            
            # Get stats for all containers
            for node in TOPOLOGY['nodes']:
                container_id = node['id']
                stats = get_container_stats(container_id)
                current_stats[container_id] = stats
                
                # Compare with previous to detect activity
                if container_id in previous_stats:
                    prev = previous_stats[container_id]
                    
                    # Detect significant changes (more than 100 bytes)
                    rx_diff = stats['rx_bytes'] - prev['rx_bytes']
                    tx_diff = stats['tx_bytes'] - prev['tx_bytes']
                    
                    if rx_diff > 100 or tx_diff > 100:
                        activity.append({
                            'node': container_id,
                            'rx': rx_diff,
                            'tx': tx_diff,
                            'rx_packets': stats['rx_packets'] - prev['rx_packets'],
                            'tx_packets': stats['tx_packets'] - prev['tx_packets']
                        })
            
            # Get router stats
            iptables_output = get_router_iptables()
            
            # Emit to all connected clients
            if activity or iptables_output:
                socketio.emit('network_update', {
                    'timestamp': time.time(),
                    'activity': activity,
                    'stats': current_stats,
                    'iptables': iptables_output
                })
            
            previous_stats = current_stats
            
        except Exception as e:
            print(f"Monitor error: {e}")
        
        time.sleep(0.5)  # Update every 500ms

@app.route('/')
def index():
    """Serve the main visualization page"""
    return render_template('index.html')

@app.route('/status')
def status_page():
    """Serve the container status dashboard"""
    return render_template('status.html')

@app.route('/api/topology')
def get_topology():
    """Return network topology"""
    return jsonify(TOPOLOGY)

@app.route('/api/stats')
def get_stats():
    """Return current stats for all containers"""
    stats = {}
    for node in TOPOLOGY['nodes']:
        stats[node['id']] = get_container_stats(node['id'])
    return jsonify(stats)

@socketio.on('connect')
def handle_connect():
    """Handle client connection"""
    print('Client connected')
    emit('topology', TOPOLOGY)

@socketio.on('disconnect')
def handle_disconnect():
    """Handle client disconnection"""
    print('Client disconnected')

if __name__ == '__main__':
    # Start monitoring thread
    monitor_thread = threading.Thread(target=monitor_network, daemon=True)
    monitor_thread.start()
    
    print("Starting Network Visualization Server on http://0.0.0.0:8080")
    socketio.run(app, host='0.0.0.0', port=8080, debug=False, allow_unsafe_werkzeug=True)

