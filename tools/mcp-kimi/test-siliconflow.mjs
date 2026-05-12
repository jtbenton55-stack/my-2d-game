const API_KEY = process.env.SILICONFLOW_API_KEY;
const BASE_URL = process.env.SILICONFLOW_BASE_URL || "https://api.siliconflow.com/v1";
const MODEL = process.env.SILICONFLOW_MODEL || "moonshotai/Kimi-K2.6";
const REQUEST_TIMEOUT_MS = 120_000;

function redactPotentialSecrets(text) {
  if (!text || typeof text !== "string") return "";
  return text
    .replace(/sk-[A-Za-z0-9_\-]{12,}/g, "[REDACTED_SECRET]")
    .replace(/Bearer\s+[A-Za-z0-9_\.\-]{12,}/gi, "Bearer [REDACTED_SECRET]")
    .replace(/SILICONFLOW_API_KEY\s*=\s*[^\s]+/gi, "SILICONFLOW_API_KEY=[REDACTED_SECRET]");
}

if (!API_KEY) {
  console.error("Missing SILICONFLOW_API_KEY. Set it as a Windows user environment variable and restart Cursor before running this test.");
  process.exit(1);
}

const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

let response;
try {
  response = await fetch(`${BASE_URL}/chat/completions`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${API_KEY}`,
      "Content-Type": "application/json"
    },
    signal: controller.signal,
    body: JSON.stringify({
      model: MODEL,
      messages: [
        {
          role: "user",
          content: "Reply with exactly this final answer and no reasoning: Kimi bridge OK"
        }
      ],
      max_tokens: 512,
      temperature: 0,
      stream: false
    })
  });
} catch (error) {
  const message = error?.name === "AbortError"
    ? `SiliconFlow API test timed out after ${REQUEST_TIMEOUT_MS / 1000} seconds.`
    : `SiliconFlow API test request failed: ${error?.message || String(error)}`;
  console.error(redactPotentialSecrets(message));
  process.exit(1);
} finally {
  clearTimeout(timeout);
}

const raw = await response.text();

if (!response.ok) {
  console.error(`SiliconFlow API test failed with status ${response.status}.`);
  console.error(redactPotentialSecrets(raw));
  process.exit(1);
}

let data;
try {
  data = JSON.parse(raw);
} catch {
  console.error("Could not parse JSON response:");
  console.error(redactPotentialSecrets(raw));
  process.exit(1);
}

const text = data?.choices?.[0]?.message?.content;
const finishReason = data?.choices?.[0]?.finish_reason;

console.log("SiliconFlow API test response:");
if (typeof text === "string" && text.trim()) {
  console.log(redactPotentialSecrets(text));
} else {
  console.error("SiliconFlow responded, but no visible final content was returned. Increase max_tokens or check model thinking settings.");
  if (finishReason) {
    console.error(`finish_reason: ${redactPotentialSecrets(String(finishReason))}`);
  }
  process.exit(1);
}
