// Network Visualization using D3.js

const socket = io();
let topology = null;
let simulation = null;
let nodes = [];
let links = [];
let nodeElements = null;
let linkElements = null;

// Color mapping for node types
const nodeColors = {
    router: '#f59e0b',
    switch: '#fbbf24',  // Golden/amber for Layer 2 switch
    dns: '#8b5cf6',
    web: '#10b981',
    client: '#3b82f6',
    dhcp: '#ec4899',
    external: '#64748b'
};

// Initialize visualization
function initVisualization() {
    const svg = d3.select('#network-viz');
    const width = svg.node().getBoundingClientRect().width;
    const height = svg.node().getBoundingClientRect().height;

    svg.attr('viewBox', [0, 0, width, height]);

    // Create groups for layers
    const g = svg.append('g');
    const linkGroup = g.append('g').attr('class', 'links');
    const nodeGroup = g.append('g').attr('class', 'nodes');

    // Setup zoom
    const zoom = d3.zoom()
        .scaleExtent([0.5, 3])
        .on('zoom', (event) => {
            g.attr('transform', event.transform);
        });

    svg.call(zoom);

    return { svg, linkGroup, nodeGroup, width, height };
}

// Create force simulation
function createSimulation(nodes, links, width, height) {
    return d3.forceSimulation(nodes)
        .force('link', d3.forceLink(links).id(d => d.id).distance(200))
        .force('charge', d3.forceManyBody().strength(-800))
        .force('center', d3.forceCenter(width / 2, height / 2))
        .force('collision', d3.forceCollide().radius(60))
        .force('x', d3.forceX(width / 2).strength(0.05))
        .force('y', d3.forceY(height / 2).strength(0.05));
}

// Update visualization with topology data
function updateVisualization(data) {
    topology = data;
    
    // Initialize visualization first to get width and height
    const { svg, linkGroup, nodeGroup, width, height } = initVisualization();
    
    // Create nodes array with better initial positioning
    const nodeCount = data.nodes.length;
    const angleStep = (2 * Math.PI) / nodeCount;
    const radius = Math.min(width, height) * 0.3;
    
    nodes = data.nodes.map((n, i) => ({
        ...n,
        x: width / 2 + radius * Math.cos(i * angleStep),
        y: height / 2 + radius * Math.sin(i * angleStep)
    }));

    // Create links array from network memberships
    links = [];
    data.networks.forEach(network => {
        const members = network.members;
        // Connect all members in a network
        for (let i = 0; i < members.length; i++) {
            for (let j = i + 1; j < members.length; j++) {
                links.push({
                    source: members[i],
                    target: members[j],
                    network: network.id
                });
            }
        }
    });
    
    // Create links
    linkElements = linkGroup.selectAll('line')
        .data(links)
        .join('line')
        .attr('class', 'link')
        .style('stroke', d => {
            if (d.network === 'vlan10') return 'rgba(59, 130, 246, 0.3)';
            if (d.network === 'vlan20') return 'rgba(236, 72, 153, 0.3)';
            if (d.network === 'vlan30') return 'rgba(251, 191, 36, 0.3)';  // Golden for switched network
            if (d.network === 'wan') return 'rgba(100, 116, 139, 0.3)';
            return 'rgba(255, 255, 255, 0.3)';
        });

    // Create nodes
    const nodeGroup2 = nodeGroup.selectAll('.node')
        .data(nodes)
        .join('g')
        .attr('class', 'node')
        .call(d3.drag()
            .on('start', dragstarted)
            .on('drag', dragged)
            .on('end', dragended));

    nodeGroup2.append('circle')
        .attr('r', 25)
        .attr('fill', d => nodeColors[d.type] || '#64748b');

    nodeGroup2.append('text')
        .attr('dy', 45)
        .text(d => d.label);

    nodeGroup2.append('text')
        .attr('dy', -35)
        .attr('font-size', '10px')
        .attr('fill', '#94a3b8')
        .text(d => d.ip);

    nodeElements = nodeGroup2;

    // Create simulation
    simulation = createSimulation(nodes, links, width, height);
    
    simulation.on('tick', () => {
        linkElements
            .attr('x1', d => d.source.x)
            .attr('y1', d => d.source.y)
            .attr('x2', d => d.target.x)
            .attr('y2', d => d.target.y);

        nodeElements.attr('transform', d => `translate(${d.x},${d.y})`);
    });
}

// Drag functions
function dragstarted(event, d) {
    if (!event.active) simulation.alphaTarget(0.3).restart();
    d.fx = d.x;
    d.fy = d.y;
}

function dragged(event, d) {
    d.fx = event.x;
    d.fy = event.y;
}

function dragended(event, d) {
    if (!event.active) simulation.alphaTarget(0);
    d.fx = null;
    d.fy = null;
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
    console.log('Network update:', data);
    
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
        const svg = d3.select('#network-viz');
        const width = svg.node().getBoundingClientRect().width;
        const height = svg.node().getBoundingClientRect().height;
        svg.attr('viewBox', [0, 0, width, height]);
        
        if (simulation) {
            simulation.force('center', d3.forceCenter(width / 2, height / 2));
            simulation.alpha(0.3).restart();
        }
    }
});

