import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Resend } from 'resend';

// Load .env from project root if present (RESEND_API_KEY=...)
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const envPath = resolve(root, '.env');
if (existsSync(envPath)) {
  for (const line of readFileSync(envPath, 'utf8').split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1).trim();
    if (key && !(key in process.env)) process.env[key] = value;
  }
}

// Replace re_xxxxxxxxx in .env with your real API key from https://resend.com/api-keys
const apiKey = process.env.RESEND_API_KEY || 're_xxxxxxxxx';
if (!apiKey || apiKey === 're_xxxxxxxxx') {
  console.error(
    'Set your Resend API key: export RESEND_API_KEY=re_your_real_key\n' +
      'Get one at https://resend.com/api-keys'
  );
  process.exit(1);
}

const resend = new Resend(apiKey);

const { data, error } = await resend.emails.send({
  from: 'onboarding@resend.dev',
  to: 'shilpi1958@gmail.com',
  subject: 'Hello World',
  html: '<p>Congrats on sending your <strong>first email</strong>!</p>',
});

if (error) {
  console.error('Failed to send email:', error);
  process.exit(1);
}

console.log('Email sent:', data);
