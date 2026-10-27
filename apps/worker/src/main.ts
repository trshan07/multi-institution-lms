import { Worker } from 'bullmq';
import Redis from 'ioredis';

// Infrastructure smoke jobs only. Tenant workloads need validated context and an outbox.
const connection = new Redis(process.env.REDIS_URL ?? 'redis://localhost:6379', { maxRetriesPerRequest: null });
const worker = new Worker('platform-health', async job => {
  if (job.name !== 'ping') throw new Error('Unsupported job');
  return { status: 'ok' };
}, { connection, concurrency: 2 });
worker.on('error', error => console.error('Worker error:', error.message));
async function shutdown() { await worker.close(); await connection.quit(); }
process.once('SIGINT', () => { void shutdown(); });
process.once('SIGTERM', () => { void shutdown(); });
