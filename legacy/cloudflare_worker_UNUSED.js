// job radar — Anthropic API proxy
// Deploy this on Cloudflare Workers. It holds your real API key as a secret and
// forwards requests from the GitHub Pages frontend, so the key never appears in
// client-side code.
//
// Setup (Worker → Settings → Variables and Secrets):
//   ANTHROPIC_API_KEY  (encrypt)      — your real key from console.anthropic.com
//   ALLOWED_ORIGIN     (plain text)   — your GitHub Pages URL, e.g. https://yourname.github.io
//   SHARED_SECRET      (encrypt)      — any random string you make up yourself
//
// Note on SHARED_SECRET: this is a lightweight deterrent, not real security — it
// still lives in the frontend JS, so anyone determined can extract it. It stops
// casual scraping/discovery, not a targeted attacker. Real protection means proper
// user auth (Supabase Auth + verifying a JWT here) — worth doing if this stops
// being a single-user personal tool.

export default {
  async fetch(request, env) {
    const ALLOWED_ORIGIN = env.ALLOWED_ORIGIN || '*';
    const corsHeaders = {
      'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, X-Client-Secret',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405, headers: corsHeaders });
    }

    const clientSecret = request.headers.get('X-Client-Secret');
    if (env.SHARED_SECRET && clientSecret !== env.SHARED_SECRET) {
      return new Response('Unauthorized', { status: 401, headers: corsHeaders });
    }

    let body;
    try {
      body = await request.json();
    } catch (e) {
      return new Response('Invalid JSON', { status: 400, headers: corsHeaders });
    }

    // hard cap regardless of what's requested — cheap insurance against runaway cost
    // even if the frontend code ever asks for more
    body.max_tokens = Math.min(body.max_tokens || 1000, 1000);

    const anthropicRes = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify(body),
    });

    const responseBody = await anthropicRes.text();
    return new Response(responseBody, {
      status: anthropicRes.status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  },
};
