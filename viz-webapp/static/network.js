// Network Visualization using D3.js
// Simplified version with fixed layout (no force simulation)

const socket = io();
let topology = null;
let nodes = [];
let links = [];
let nodeElements = null;
let linkElements = null;
let svg, linkGroup, nodeGroup, width, height;

// Color mapping for node types
const nodeColors = {
    router: '#f59e0b',
    switch: '#fbbf24',
    dns: '#8b5cf6',
    web: '#10b981',
    client: '#3b82f6',
    dhcp: '#ec4899',
    external: '#64748b'
};

// Fixed positions for each node (arranged in a logical network layout)
const nodePositions = {
    // WAN at top
    'wan-host': { x: 0.25, y: 0.15 },
    'wan-service': { x: 0.75, y: 0.15 },
    
    // Router in center
    'router': { x: 0.5, y: 0.4 },
    
    // VLAN 10 (left side)
    'coredns': { x: 0.15, y: 0.55 },
    'nginx-app': { x: 0.15, y: 0.7 },
    'client10': { x: 0.15, y: 0.85 },
    
    // VLAN 20 (center-right)
    'dnsmasq': { x: 0.5, y: 0.65 },
    'client20': { x: 0.5, y: 0.85 },
    
    // VLAN 30 (right side)
    'switch': { x: 0.85, y: 0.55 },
    'client30a': { x: 0.85, y: 0.7 },
    'client30b': { x: 0.85, y: 0.85 }
};

// Initialize visualization
function initVisualization() {
    svg = d3.select('#network-viz');
    width = svg.node().getBoundingClientRect().width;
    height = svg.node().getBoundingClientRect().height;

    svg.attr('viewBox', [0, 0, width, height]);

    // Clear existing content
    svg.selectAll('*').remove();

    // Create groups for layers
    const g = svg.append('g').attr('class', 'main-group');
    linkGroup = g.append('g').attr('class', 'links');
    nodeGroup = g.append('g').attr('class', 'nodes');

    // Setup zoom
    const zoom = d3.zoom()
        .scaleExtent([0.5, 3])
        .on('zoom', (event) => {
            g.attr('transform', event.transform);
        });

    svg.call(zoom);
}

// Calculate actual pixel positions from relative positions
function getNodePosition(nodeId) {
    const pos = nodePositions[nodeId];
    if (pos) {
        return {
            x: pos.x * width,
            y: pos.y * height
        };
    }
    // Fallback to center if not defined
    return { x: width / 2, y: height / 2 };
}

// Update visualization with topology data
function updateVisualization(data) {
    topology = data;
    
    // Initialize visualization
    initVisualization();
    
    // Create nodes array with fixed positions
    nodes = data.nodes.map(n => {
        const pos = getNodePosition(n.id);
        return {
            ...n,
            x: pos.x,
            y: pos.y
        };
    });

    // Create links array from network memberships
    links = [];
    data.networks.forEach(network => {
        const members = network.members;
        for (let i = 0; i < members.length; i++) {
            for (let j = i + 1; j < members.length; j++) {
                // Find the actual node objects
                const source = nodes.find(n => n.id === members[i]);
                const target = nodes.find(n => n.id === members[j]);
                if (source && target) {
                    links.push({
                        source: source,
                        target: target,
                        network: network.id
                    });
                }
            }
        }
    });
    
    // Create links
    linkElements = linkGroup.selectAll('line')
        .data(links)
        .join('line')
        .attr('class', 'link')
        .attr('x1', d => d.source.x)
        .attr('y1', d => d.source.y)
        .attr('x2', d => d.target.x)
        .attr('y2', d => d.target.y)
        .attr('stroke-width', 2)
        .style('stroke', d => {
            if (d.network === 'vlan10') return 'rgba(59, 130, 246, 0.4)';
            if (d.network === 'vlan20') return 'rgba(236, 72, 153, 0.4)';
            if (d.network === 'vlan30') return 'rgba(251, 191, 36, 0.4)';
            if (d.network === 'wan') return 'rgba(100, 116, 139, 0.4)';
            return 'rgba(255, 255, 255, 0.3)';
        });

    // Create nodes
    nodeElements = nodeGroup.selectAll('.node')
        .data(nodes)
        .join('g')
        .attr('class', 'node')
        .attr('transform', d => `translate(${d.x},${d.y})`)
        .call(d3.drag()
            .on('start', dragstarted)
            .on('drag', dragged)
            .on('end', dragended));

    nodeElements.append('circle')
        .attr('r', 25)
        .attr('fill', d => nodeColors[d.type] || '#64748b')
        .attr('stroke', '#fff')
        .attr('stroke-width', 2);

    nodeElements.append('text')
        .attr('dy', 45)
        .attr('text-anchor', 'middle')
        .attr('fill', '#fff')
        .attr('font-size', '12px')
        .attr('font-weight', 'bold')
        .text(d => d.label);

    nodeElements.append('text')
        .attr('dy', -35)
        .attr('text-anchor', 'middle')
        .attr('font-size', '10px')
        .attr('fill', '#94a3b8')
        .text(d => d.ip);

    console.log(`Visualization created with ${nodes.length} nodes and ${links.length} links`);
}

// Drag functions
function dragstarted(event, d) {
    d3.select(this).raise();
}

function dragged(event, d) {
    d.x = event.x;
    d.y = event.y;
    
    // Update node position
    d3.select(this).attr('transform', `translate(${d.x},${d.y})`);
    
    // Update connected links
    linkElements
        .attr('x1', l => l.source.x)
        .attr('y1', l => l.source.y)
        .attr('x2', l => l.target.x)
        .attr('y2', l => l.target.y);
}

function dragended(event, d) {
    // Nothing special needed
}

// Format bytes for display
function formatBytes(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// Update activity log
function updateActivityLog(activity) {
    const log = d3.select('#activity-log');
    const maxItems = 10;

    activity.forEach(item => {
        const timestamp = new Date().toLocaleTimeString();
        const entry = `
            <div class="activity-item">
                [${timestamp}] ${item.node}: ↓${formatBytes(item.rx)} ↑${formatBytes(item.tx)}
            </div>
        `;
        
        log.insert('div', ':first-child')
            .html(entry);
    });

    // Remove old entries
    const items = log.selectAll('.activity-item');
    if (items.size() > maxItems) {
        items.filter((d, i) => i >= maxItems).remove();
    }

    // Highlight active nodes
    if (nodeElements) {
        nodeElements.classed('active', d => 
            activity.some(a => a.node === d.id)
        );

        // Remove highlight after 1 second
        setTimeout(() => {
            nodeElements.classed('active', false);
        }, 1000);
    }
}

// Update stats panel
function updateStats(stats) {
    const panel = d3.select('#stats-panel');
    
    let html = '';
    Object.entries(stats).forEach(([node, data]) => {
        if (data.status === 'running') {
            html += `
                <div class="stat-item">
                    <span class="stat-label">${node}:</span>
                    <span class="stat-value">${formatBytes(data.rx_bytes + data.tx_bytes)}</span>
                </div>
            `;
        }
    });
    
    panel.html(html);
}

// Update iptables display
function updateIptables(output) {
    if (output) {
        d3.select('#iptables-output').text(output);
    }
}

// Socket.IO event handlers
socket.on('connect', () => {
    console.log('Connected to server');
    d3.select('#connection-status').classed('offline', false).classed('online', true);
    d3.select('#connection-text').text('Connected');
});

socket.on('disconnect', () => {
    console.log('Disconnected from server');
    d3.select('#connection-status').classed('online', false).classed('offline', true);
    d3.select('#connection-text').text('Disconnected');
});

socket.on('topology', (data) => {
    console.log('Received topology:', data);
    updateVisualization(data);
});

socket.on('network_update', (data) => {
    if (data.activity && data.activity.length > 0) {
        updateActivityLog(data.activity);
    }
    
    if (data.stats) {
        updateStats(data.stats);
    }
    
    if (data.iptables) {
        updateIptables(data.iptables);
    }
});

// Handle window resize
window.addEventListener('resize', () => {
    if (topology) {
        updateVisualization(topology);
    }
});
