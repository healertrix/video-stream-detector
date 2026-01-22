# 🎬 Video Stream Detector

Auto-detect m3u8/HLS video stream URLs from embed pages using Playwright headless browser.

## Features

- 🔍 **Auto-detection** - Automatically finds m3u8 URLs from any embed page
- 🚀 **Headless browser** - Uses Playwright Chromium to intercept network requests
- 🔌 **REST API** - Simple API endpoints for integration
- 🎮 **Web UI** - Built-in player with full controls
- 🌐 **CORS Proxy** - Proxies HLS streams to bypass CORS restrictions

## Quick Start

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/video-stream-detector.git
cd video-stream-detector

# Install dependencies and browser
npm run setup

# Start the server
npm start
```

Open http://localhost:3333 in your browser.

## API Endpoints

### Detect m3u8 URL

```
GET /api/detect?url=<embed_url>
```

**Parameters:**
- `url` (required) - The embed page URL to scan
- `timeout` (optional) - Page load timeout in ms (default: 15000)
- `wait` (optional) - Time to wait for network requests in ms (default: 5000)

**Response:**
```json
{
  "success": true,
  "count": 2,
  "urls": [
    { "url": "https://example.com/master.m3u8?token=...", "type": "request", "time": 1234 }
  ],
  "master": { "url": "https://example.com/master.m3u8?token=...", "type": "request", "time": 1234 },
  "elapsed": 5432
}
```

### Proxy HLS Stream

```
GET /api/proxy?url=<stream_url>
```

Proxies the HLS stream to bypass CORS restrictions.

### Health Check

```
GET /api/health
```

Returns server status and Playwright availability.

## Ubuntu/Linux Installation

### Prerequisites

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install dependencies for Playwright
sudo apt install -y libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
  libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 \
  libasound2 libpango-1.0-0 libcairo2
```

### Installation

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/video-stream-detector.git
cd video-stream-detector

# Install dependencies
npm run setup

# Start server
npm start
```

### Run as a Service (systemd)

```bash
# Create service file
sudo nano /etc/systemd/system/video-detector.service
```

Paste:
```ini
[Unit]
Description=Video Stream Detector
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/path/to/video-stream-detector
ExecStart=/usr/bin/node server.js
Restart=on-failure
Environment=PORT=3333

[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl enable video-detector
sudo systemctl start video-detector
sudo systemctl status video-detector
```

### Nginx Reverse Proxy (Optional)

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:3333;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 3333 | Server port |
| `HOST` | 0.0.0.0 | Server host |

## Usage Examples

### cURL

```bash
# Detect m3u8 URL
curl "http://localhost:3333/api/detect?url=https://example.com/embed/video123"

# With custom timeout
curl "http://localhost:3333/api/detect?url=https://example.com/embed/video123&timeout=20000&wait=8000"
```

### JavaScript

```javascript
const response = await fetch('http://localhost:3333/api/detect?url=' + encodeURIComponent(embedUrl));
const data = await response.json();

if (data.success) {
  console.log('Found:', data.master.url);
}
```

### Python

```python
import requests

response = requests.get('http://localhost:3333/api/detect', params={
    'url': 'https://example.com/embed/video123'
})
data = response.json()

if data['success']:
    print('Found:', data['master']['url'])
```

## License

MIT
