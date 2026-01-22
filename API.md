# 🎬 Video Stream Detector API

**Base URL:** `https://app1.tail5584d5.ts.net`

---

## Endpoints

### 1. Detect m3u8 Stream URL

Extracts HLS stream URLs from video embed pages using headless browser.

```
GET /api/detect?url={embed_url}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `url` | string | ✅ | The video embed page URL |
| `timeout` | number | ❌ | Page load timeout in ms (default: 15000) |
| `wait` | number | ❌ | Wait time for requests in ms (default: 5000) |

**Example:**
```bash
curl "https://app1.tail5584d5.ts.net/api/detect?url=https://example.com/embed/video123"
```

**Response:**
```json
{
  "success": true,
  "count": 1,
  "urls": [
    {
      "url": "https://cdn.example.com/hls/master.m3u8?token=abc123",
      "type": "request",
      "time": 2341
    }
  ],
  "master": {
    "url": "https://cdn.example.com/hls/master.m3u8?token=abc123",
    "type": "request",
    "time": 2341
  },
  "elapsed": 5432
}
```

---

### 2. Proxy HLS Stream

Proxies HLS streams to bypass CORS restrictions.

```
GET /api/proxy?url={stream_url}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `url` | string | ✅ | The m3u8 or .ts segment URL |

**Example:**
```bash
curl "https://app1.tail5584d5.ts.net/api/proxy?url=https://cdn.example.com/master.m3u8"
```

---

### 3. Health Check

```
GET /api/health
```

**Response:**
```json
{
  "status": "ok",
  "playwright": true,
  "uptime": 3600.5
}
```

---

## Quick Examples

**JavaScript:**
```javascript
const response = await fetch('https://app1.tail5584d5.ts.net/api/detect?url=' + encodeURIComponent(embedUrl));
const data = await response.json();

if (data.success) {
  console.log('Stream URL:', data.master.url);
}
```

**Python:**
```python
import requests

response = requests.get('https://app1.tail5584d5.ts.net/api/detect', params={
    'url': 'https://example.com/embed/video123'
})
data = response.json()

if data['success']:
    print('Stream URL:', data['master']['url'])
```

**cURL:**
```bash
curl -s "https://app1.tail5584d5.ts.net/api/detect?url=https://example.com/embed/video" | jq .master.url
```

---

## Web UI

Open in browser: **https://app1.tail5584d5.ts.net**

---

## Error Responses

```json
{
  "success": false,
  "error": "Error message here"
}
```

| Status | Meaning |
|--------|---------|
| 400 | Missing required parameter |
| 500 | Detection/server error |
| 503 | Playwright not available |
