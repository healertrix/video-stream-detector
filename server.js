const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const url = require('url');

// Configuration
const PORT = process.env.PORT || 3333;
const HOST = process.env.HOST || '0.0.0.0';

let playwright;

// Initialize Playwright
async function initPlaywright() {
    try {
        playwright = require('playwright');
        console.log('✓ Playwright loaded');
        return true;
    } catch (e) {
        console.error('✗ Playwright not found. Run: npm run setup');
        return false;
    }
}

/**
 * Detect m3u8 URLs from an embed page using headless browser
 * @param {string} embedUrl - The URL of the embed page
 * @param {object} options - Detection options
 * @returns {Promise<object>} - Detection results
 */
async function detectM3U8(embedUrl, options = {}) {
    const {
        timeout = 15000,
        waitTime = 5000,
        clickPlay = true,
        headless = true
    } = options;

    if (!playwright) {
        throw new Error('Playwright not initialized');
    }

    const browser = await playwright.chromium.launch({ headless });
    const context = await browser.newContext({
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    });
    
    const page = await context.newPage();
    const foundUrls = [];
    const startTime = Date.now();

    // Intercept network requests
    page.on('request', request => {
        const reqUrl = request.url();
        if (reqUrl.includes('.m3u8')) {
            const entry = { url: reqUrl, type: 'request', time: Date.now() - startTime };
            if (!foundUrls.find(f => f.url === reqUrl)) {
                foundUrls.push(entry);
                console.log(`  [+] Found: ${reqUrl.substring(0, 80)}...`);
            }
        }
    });

    page.on('response', response => {
        const resUrl = response.url();
        if (resUrl.includes('.m3u8') && !foundUrls.find(f => f.url === resUrl)) {
            foundUrls.push({ url: resUrl, type: 'response', time: Date.now() - startTime });
        }
    });

    try {
        console.log(`[Detect] Loading: ${embedUrl}`);
        await page.goto(embedUrl, { waitUntil: 'domcontentloaded', timeout });

        // Try to trigger video playback
        if (clickPlay) {
            const playSelectors = [
                '.jw-icon-display',
                '.vjs-big-play-button', 
                '[class*="play-button"]',
                '[class*="playButton"]',
                '.play-btn',
                'button[aria-label*="play" i]',
                '[data-plyr="play"]'
            ];
            
            for (const selector of playSelectors) {
                try {
                    await page.click(selector, { timeout: 1000 });
                    console.log(`  [>] Clicked: ${selector}`);
                    break;
                } catch (e) {}
            }
        }

        // Wait for network activity
        await page.waitForTimeout(waitTime);

        // If no URLs found, try clicking video element
        if (foundUrls.length === 0) {
            try {
                await page.click('video', { timeout: 1000 });
                await page.waitForTimeout(2000);
            } catch (e) {}
        }

    } catch (e) {
        console.log(`  [!] Error: ${e.message}`);
    }

    await browser.close();

    // Sort by priority (master.m3u8 first)
    foundUrls.sort((a, b) => {
        const aIsMaster = a.url.includes('master') ? -1 : 0;
        const bIsMaster = b.url.includes('master') ? -1 : 0;
        return aIsMaster - bIsMaster;
    });

    return {
        success: foundUrls.length > 0,
        count: foundUrls.length,
        urls: foundUrls,
        master: foundUrls.find(u => u.url.includes('master')) || foundUrls[0] || null,
        elapsed: Date.now() - startTime
    };
}

/**
 * Proxy HLS stream to bypass CORS
 */
function proxyStream(targetUrl, res) {
    const parsedUrl = new URL(targetUrl);
    
    const options = {
        hostname: parsedUrl.hostname,
        port: 443,
        path: parsedUrl.pathname + parsedUrl.search,
        method: 'GET',
        headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': '*/*',
            'Referer': parsedUrl.origin + '/',
            'Origin': parsedUrl.origin
        }
    };

    const proxyReq = https.request(options, (proxyRes) => {
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', '*');
        
        if (proxyRes.headers['content-type']) {
            res.setHeader('Content-Type', proxyRes.headers['content-type']);
        }
        
        res.writeHead(proxyRes.statusCode);
        proxyRes.pipe(res);
    });

    proxyReq.on('error', (err) => {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
    });

    proxyReq.end();
}

/**
 * Send JSON response
 */
function jsonResponse(res, data, status = 200) {
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.writeHead(status);
    res.end(JSON.stringify(data, null, 2));
}

/**
 * HTTP Server
 */
const server = http.createServer(async (req, res) => {
    const parsedUrl = url.parse(req.url, true);
    const pathname = parsedUrl.pathname;

    // CORS preflight
    if (req.method === 'OPTIONS') {
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', '*');
        res.writeHead(204);
        res.end();
        return;
    }

    // ============ API ENDPOINTS ============

    // GET /api/detect?url=<embed_url>
    // Detect m3u8 URLs from an embed page
    if (pathname === '/api/detect') {
        const embedUrl = parsedUrl.query.url;
        
        if (!embedUrl) {
            return jsonResponse(res, { 
                success: false, 
                error: 'Missing required parameter: url' 
            }, 400);
        }

        if (!playwright) {
            return jsonResponse(res, { 
                success: false, 
                error: 'Playwright not available. Run: npm run setup' 
            }, 503);
        }

        try {
            const timeout = parseInt(parsedUrl.query.timeout) || 15000;
            const waitTime = parseInt(parsedUrl.query.wait) || 5000;
            
            const result = await detectM3U8(embedUrl, { timeout, waitTime });
            return jsonResponse(res, result);
        } catch (err) {
            return jsonResponse(res, { 
                success: false, 
                error: err.message 
            }, 500);
        }
    }

    // GET /api/proxy?url=<stream_url>
    // Proxy HLS stream to bypass CORS
    if (pathname === '/api/proxy' || pathname === '/proxy') {
        const targetUrl = parsedUrl.query.url;
        
        if (!targetUrl) {
            return jsonResponse(res, { error: 'Missing url parameter' }, 400);
        }

        return proxyStream(targetUrl, res);
    }

    // GET /api/health
    // Health check endpoint
    if (pathname === '/api/health') {
        return jsonResponse(res, {
            status: 'ok',
            playwright: !!playwright,
            uptime: process.uptime()
        });
    }

    // GET / - Serve web UI
    if (pathname === '/' || pathname === '/index.html') {
        const htmlPath = path.join(__dirname, 'player.html');
        if (fs.existsSync(htmlPath)) {
            fs.readFile(htmlPath, (err, data) => {
                if (err) {
                    res.writeHead(500);
                    res.end('Error loading page');
                    return;
                }
                res.setHeader('Content-Type', 'text/html');
                res.writeHead(200);
                res.end(data);
            });
            return;
        }
    }

    // 404
    jsonResponse(res, { error: 'Not found' }, 404);
});

// Start server
initPlaywright().then(() => {
    server.listen(PORT, HOST, () => {
        console.log(`
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🎬 Video Stream Detector API                            ║
║                                                           ║
║   Server: http://${HOST}:${PORT}                            ║
║                                                           ║
║   API Endpoints:                                          ║
║   • GET /api/detect?url=<embed_url>  - Detect m3u8 URLs   ║
║   • GET /api/proxy?url=<stream_url>  - Proxy HLS stream   ║
║   • GET /api/health                  - Health check       ║
║   • GET /                            - Web UI             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
        `);
    });
});

// Export for testing
module.exports = { detectM3U8, proxyStream };
