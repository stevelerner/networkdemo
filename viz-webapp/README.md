# Network Visualization Webapp

A real-time network visualization tool for the Docker network infrastructure demo.

## Quick Start

### Building the Image

```bash
# Option 1: Use the build script
./build.sh

# Option 2: Build manually
docker build -t networkdemo_viz:latest .

# Option 3: Build via docker compose (from parent directory)
cd ..
docker compose build viz
```

### Running Standalone

```bash
# Run the webapp container
docker run -d \
  --name viz-webapp \
  -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  networkdemo_viz:latest

# Access in browser
open http://localhost:8080
```

### Running with Full Demo

```bash
# From parent directory
cd ..
make up          # Starts all containers including viz
make viz         # Opens browser to visualization
```

## Features

- **Interactive D3.js topology visualization**
- **Real-time traffic monitoring** (updates every 500ms)
- **Container statistics** (network bytes, packets)
- **Live firewall rules** from router
- **Activity logging** with timestamps

## Architecture

### Backend (Flask + SocketIO)
- Python Flask web server
- Docker SDK for container monitoring
- WebSocket for real-time updates
- Polls container stats every 500ms

### Frontend (D3.js + Socket.IO)
- Force-directed graph visualization
- Real-time updates via WebSocket
- Interactive dragging and zooming
- Color-coded node types

## How It Works

1. **Docker Socket Access**: Container mounts `/var/run/docker.sock` to query Docker API
2. **Container Stats**: Polls `docker.stats()` for each container
3. **Traffic Detection**: Compares RX/TX bytes between polls to detect activity
4. **Firewall Rules**: Executes `iptables -L` in router container
5. **WebSocket Push**: Sends updates to all connected browsers

## Node Types

- **Router** (orange): Routes traffic between VLANs
- **DNS** (purple): CoreDNS service
- **Web** (green): Nginx HTTPS server
- **Client** (blue): Test clients
- **DHCP** (pink): DHCP server
- **External** (gray): WAN hosts

## Development

### Local Development

```bash
# Install dependencies
pip install flask flask-socketio docker python-socketio

# Run locally (requires Docker running)
python app.py

# Access at http://localhost:8080
```

### Building and Testing

```bash
# Build the image
./build.sh

# Run for testing
docker run --rm -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  networkdemo_viz:latest

# View logs
docker logs viz-webapp
```

### Troubleshooting

**Issue: Cannot connect to Docker daemon**
```bash
# Make sure Docker Desktop is running
docker info

# Check socket permissions
ls -la /var/run/docker.sock
```

**Issue: Port 8080 already in use**
```bash
# Find what's using the port
lsof -i :8080

# Use a different port
docker run -p 8081:8080 ... networkdemo_viz:latest
```

**Issue: Containers not showing up**
```bash
# Verify other containers are running
docker ps

# Check webapp logs
docker logs viz-webapp

# Restart the viz container
docker restart viz-webapp
```

## API Endpoints

- `GET /` - Main visualization page
- `GET /api/topology` - Static topology configuration
- `GET /api/stats` - Current container stats
- WebSocket `/` - Real-time updates

## Build Requirements

- Docker Desktop for Mac
- Bash shell (included on macOS)
- Internet connection (for pulling base images)

## Technologies

- Python 3.11
- Flask 3.0
- Flask-SocketIO 5.3
- Docker SDK 7.0
- D3.js v7
- Socket.IO 4.5

## File Structure

```
viz-webapp/
├── build.sh              # Build script
├── Dockerfile            # Container definition
├── app.py                # Flask backend + Docker monitoring
├── README.md             # This file
├── templates/
│   └── index.html        # Main visualization page
└── static/
    ├── styles.css        # UI styling
    └── network.js        # D3.js visualization + WebSocket client
```

