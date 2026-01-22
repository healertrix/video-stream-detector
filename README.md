# 🎬 Video Stream Detector API

A Node.js API that uses Playwright headless browser to automatically detect m3u8/HLS stream URLs from video embed pages.

## Features

- 🔍 **Auto-detect m3u8 URLs** - Uses headless Chromium to load embed pages and intercept network requests
- 🔄 **HLS Proxy** - Proxy endpoint to bypass CORS restrictions when playing streams
- 🌐 **Web UI** - Built-in web interface to test detection and play videos
- 🚀 **Simple API** - RESTful JSON API for easy integration

---

## 🚀 One-Click Ubuntu Install

Run this single command on your Ubuntu server:

```bash
curl -fsSL https://raw.githubusercontent.com/healertrix/video-stream-detector/main/install.sh | bash
```

That's it! The script will:
- ✅ Install Node.js 20
- ✅ Install Playwright and Chromium
- ✅ Clone the repository
- ✅ Install all dependencies
- ✅ Start the server with PM2
- ✅ Configure auto-restart on boot

---

## Manual Installation

### Prerequisites

- Node.js 18+ 
- npm

### Steps

```bash
# Clone the repository
git clone https://github.com/healertrix/video-stream-detector.git
cd video-stream-detector

# Install dependencies and Playwright browser
npm run setup

# Start the server
npm start
```

Server will start at `http://localhost:3333`

## API Endpoints

### `GET /api/detect?url=<embed_url>`

Detect m3u8 URLs from an embed page.

**Parameters:**
- `url` (required) - The embed page URL to scan
- `timeout` (optional) - Page load timeout in ms (default: 15000)
- `wait` (optional) - Time to wait for network requests in ms (default: 5000)

**Example:**
```bash
curl "http://localhost:3333/api/detect?url=https://example.com/embed/video123"
```

**Response:**
```json
{
  "success": true,
  "count": 2,
  "urls": [
    { "url": "https://cdn.example.com/master.m3u8?token=xxx", "type": "request", "time": 1234 },
    { "url": "https://cdn.example.com/index.m3u8", "type": "response", "time": 1456 }
  ],
  "master": { "url": "https://cdn.example.com/master.m3u8?token=xxx", "type": "request", "time": 1234 },
  "elapsed": 5432
}
```

### `GET /api/proxy?url=<stream_url>`

Proxy HLS streams to bypass CORS restrictions.

**Example:**
```bash
curl "http://localhost:3333/api/proxy?url=https://cdn.example.com/master.m3u8"
```

### `GET /api/health`

Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "playwright": true,
  "uptime": 123.456
}
```

### `GET /`

Web UI for testing detection and playing videos.

## Ubuntu Server Deployment

### Option 1: Quick Install Script

```bash
# Download and run install script
curl -fsSL https://raw.githubusercontent.com/healertrix/video-stream-detector/main/install.sh | bash
```

### Option 2: Manual Installation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Playwright dependencies
sudo npx playwright install-deps chromium

# Clone and setup
git clone https://github.com/healertrix/video-stream-detector.git
cd video-stream-detector
npm run setup

# Run with PM2 (recommended for production)
sudo npm install -g pm2
pm2 start server.js --name video-detector
pm2 save
pm2 startup
```

### Running as a Service (systemd)

```bash
# Create service file
sudo nano /etc/systemd/system/video-detector.service
```

Add this content:
```ini
[Unit]
Description=Video Stream Detector API
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/video-stream-detector
ExecStart=/usr/bin/node server.js
Restart=on-failure
Environment=PORT=3333
Environment=HOST=0.0.0.0

[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl enable video-detector
sudo systemctl start video-detector
```

## Configuration

Environment variables:
- `PORT` - Server port (default: 3333)
- `HOST` - Server host (default: 0.0.0.0)

## Docker (Optional)

```dockerfile
FROM node:20-slim

RUN npx playwright install-deps chromium

WORKDIR /app
COPY package*.json ./
RUN npm install
RUN npx playwright install chromium

COPY . .

EXPOSE 3333
CMD ["node", "server.js"]
```

```bash
docker build -t video-detector .
docker run -p 3333:3333 video-detector
```

## License

MIT
