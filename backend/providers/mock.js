// Mock provider for local testing (no external API calls)
// Simulates an async video generation job and calls back the webhook with a local static MP4 file

const fetch = require('node-fetch');

async function createJob(prompt, webhookUrl){
  const providerId = `mock_${Date.now()}`;
  console.log(`[mock] createJob called with prompt: ${prompt}`);

  // Simulate async callback (webhook) after short delay
  setTimeout(async () => {
    try {
      await fetch(webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: providerId,
          status: 'completed',
          result_url: `http://localhost:4000/static/sample.mp4`
        })
      });
      console.log(`[mock] webhook sent for job ${providerId}`);
    } catch (err) {
      console.error('[mock] failed to send webhook', err);
    }
  }, 3000); // 3 seconds delay

  return { id: providerId, status: 'submitted' };
}

module.exports = { createJob };
