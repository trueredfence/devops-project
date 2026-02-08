/**
 * BAS Disposable Relay - Pro Version
 * Handles secure communication between Agent and Next.js Backend
 */

export default {
    async fetch(request, env, ctx) {
        try {
            const url = new URL(request.url);
            const clientIP = request.headers.get('CF-Connecting-IP') || '0.0.0.0';

            // 1. Rate Limiting (Using in-memory Map for disposal speed)
            if (!this.checkRateLimit(clientIP)) {
                return new Response(JSON.stringify({ error: 'Rate Limit Exceeded' }), {
                    status: 429,
                    headers: { 'Content-Type': 'application/json' }
                });
            }

            // 2. Prepare Backend Request
            // We use the env variable for the backend so the worker is generic
            const BACKEND_URL = 'https://uat-redfence.bytesec.co.in';
            const backendUrl = new URL(url.pathname + url.search, BACKEND_URL);

            const headers = new Headers(request.headers);

            // 3. The "Pro" Shield: Inject Internal Secret
            // Your Next.js API will check this header to allow the request
            headers.set('X-Internal-Secret', env.BACKEND_SHARED_KEY);
            headers.set('X-BAS-Campaign', env.SIM_SUBDOMAIN);

            // Standard Proxy Headers
            headers.set('X-Forwarded-For', clientIP);
            headers.set('X-Real-IP', clientIP);
            headers.set('Host', new URL(BACKEND_URL).host);

            // Clean up sensitive/redundant headers
            headers.delete('CF-Ray');
            headers.delete('CF-Visitor');
            headers.delete('CF-Connecting-IP');

            // 4. Handle Body (Avoid Buffer issues on large payloads)
            const isMethodWithBody = !['GET', 'HEAD'].includes(request.method);
            const body = isMethodWithBody ? await request.arrayBuffer() : null;

            const proxiedRequest = new Request(backendUrl.toString(), {
                method: request.method,
                headers: headers,
                body: body,
                redirect: 'follow'
            });

            // 5. Execute & Return
            const response = await fetch(proxiedRequest);

            // Clone response to add BAS metadata
            const modifiedResponse = new Response(response.body, response);
            modifiedResponse.headers.set('X-BAS-Relay-Status', 'Authenticated');

            return modifiedResponse;

        } catch (error) {
            return new Response(JSON.stringify({
                error: 'Relay Failure',
                details: error.message
            }), {
                status: 500,
                headers: { 'Content-Type': 'application/json' }
            });
        }
    },

    // Simple in-memory rate limit
    rateLimitCache: new Map(),
    checkRateLimit(ip) {
        const limit = 100;
        const window = Math.floor(Date.now() / 60000);
        const key = `${ip}:${window}`;

        const count = this.rateLimitCache.get(key) || 0;
        if (count >= limit) return false;

        this.rateLimitCache.set(key, count + 1);

        // Auto-prune cache roughly
        if (this.rateLimitCache.size > 1000) {
            const firstKey = this.rateLimitCache.keys().next().value;
            this.rateLimitCache.delete(firstKey);
        }

        return true;
    }
};