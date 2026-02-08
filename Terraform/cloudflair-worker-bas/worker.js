/**
 * BAS Disposable Relay - Enhanced Pro Version
 * Handles secure communication between Agent and Next.js Backend
 * Features: Full reverse proxy, header forwarding, file downloads
 */

export default {
    async fetch(request, env, ctx) {
        try {
            const url = new URL(request.url);
            const clientIP = request.headers.get('CF-Connecting-IP') || '0.0.0.0';

            // Handle CORS Preflight (OPTIONS request)
            if (request.method === 'OPTIONS') {
                return this.handleOptions(request);
            }

            // 1. Rate Limiting
            if (!this.checkRateLimit(clientIP)) {
                return new Response(JSON.stringify({ error: 'Rate Limit Exceeded' }), {
                    status: 429,
                    headers: {
                        'Content-Type': 'application/json',
                        ...this.getCorsHeaders(request)
                    }
                });
            }

            // 2. Configuration
            const BACKEND_API_URL = env.BACKEND_API_URL || 'https://your-backend-api.com';

            // Headers to forward from client to backend (configurable)
            const FORWARD_HEADERS = [
                'authorization',
                'content-type',
                'accept',
                'accept-encoding',
                'accept-language',
                'user-agent',
                'x-api-key',
                'x-auth-token',
                'cookie',
                'referer',
                'origin'
            ];

            // 3. Prepare Backend Request URL
            // Remove leading slash if present to avoid double slashes
            const pathname = url.pathname.startsWith('/') ? url.pathname.substring(1) : url.pathname;
            const backendUrl = new URL(pathname + url.search, BACKEND_API_URL);

            const headers = new Headers();

            // Forward specific headers from original request
            FORWARD_HEADERS.forEach(headerName => {
                const value = request.headers.get(headerName);
                if (value) {
                    headers.set(headerName, value);
                }
            });

            // 4. Inject Internal Authentication Headers
            if (env.BACKEND_SHARED_KEY) {
                headers.set('X-Internal-Secret', env.BACKEND_SHARED_KEY);
            }
            if (env.SIM_SUBDOMAIN) {
                headers.set('X-BAS-Campaign', env.SIM_SUBDOMAIN);
            }

            // Standard Proxy Headers
            headers.set('X-Forwarded-For', clientIP);
            headers.set('X-Real-IP', clientIP);
            headers.set('X-Forwarded-Proto', url.protocol.replace(':', ''));
            headers.set('X-Forwarded-Host', url.host);

            // Set the correct Host header for the backend
            const backendHost = new URL(BACKEND_API_URL).host;
            headers.set('Host', backendHost);

            // 5. Handle Request Body - Clone request to preserve it
            let body = null;
            const method = request.method.toUpperCase();

            // Methods that can have a body
            if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(method)) {
                // Get the raw body as ArrayBuffer to preserve all data
                body = await request.arrayBuffer();

                // Ensure Content-Type is set if body exists
                if (body.byteLength > 0 && !headers.has('content-type')) {
                    headers.set('content-type', 'application/octet-stream');
                }
            }

            // 6. Create Proxied Request with exact same method
            const proxiedRequest = new Request(backendUrl.toString(), {
                method: method, // Use the exact method from original request
                headers: headers,
                body: body,
                redirect: 'follow'
            });

            // 7. Execute Backend Request
            const response = await fetch(proxiedRequest);

            // 8. Handle Response - Preserve all headers
            const responseHeaders = new Headers(response.headers);

            // Add CORS headers
            const corsHeaders = this.getCorsHeaders(request);
            Object.entries(corsHeaders).forEach(([key, value]) => {
                responseHeaders.set(key, value);
            });

            // Add BAS metadata
            responseHeaders.set('X-BAS-Relay-Status', 'Authenticated');
            responseHeaders.set('X-BAS-Proxy-Version', '2.0');
            responseHeaders.set('X-BAS-Backend-Status', response.status.toString());

            // 9. Return Response (works for both files and regular responses)
            return new Response(response.body, {
                status: response.status,
                statusText: response.statusText,
                headers: responseHeaders
            });

        } catch (error) {
            console.error('Relay Error:', error);

            return new Response(JSON.stringify({
                error: 'Relay Failure',
                details: error.message,
                timestamp: new Date().toISOString()
            }), {
                status: 500,
                headers: {
                    'Content-Type': 'application/json',
                    ...this.getCorsHeaders(request)
                }
            });
        }
    },

    // Handle OPTIONS preflight requests
    handleOptions(request) {
        return new Response(null, {
            status: 204,
            headers: {
                ...this.getCorsHeaders(request),
                'Access-Control-Max-Age': '86400', // 24 hours
            }
        });
    },

    // Get CORS headers
    getCorsHeaders(request) {
        const origin = request.headers.get('Origin');

        return {
            'Access-Control-Allow-Origin': origin || '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key, X-Auth-Token, Accept, Origin, User-Agent, X-Requested-With',
            'Access-Control-Allow-Credentials': 'true',
            'Access-Control-Expose-Headers': 'Content-Disposition, Content-Type, Content-Length',
        };
    },

    // Simple in-memory rate limit
    rateLimitCache: new Map(),
    checkRateLimit(ip) {
        const RATE_LIMIT = 100; // requests per minute
        const window = Math.floor(Date.now() / 60000);
        const key = `${ip}:${window}`;

        const count = this.rateLimitCache.get(key) || 0;
        if (count >= RATE_LIMIT) return false;

        this.rateLimitCache.set(key, count + 1);

        // Auto-prune cache
        if (this.rateLimitCache.size > 1000) {
            const firstKey = this.rateLimitCache.keys().next().value;
            this.rateLimitCache.delete(firstKey);
        }

        return true;
    }
};