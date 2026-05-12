import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import * as z from "zod/v4";

const API_KEY = process.env.SILICONFLOW_API_KEY;
const BASE_URL = process.env.SILICONFLOW_BASE_URL || "https://api.siliconflow.com/v1";
const MODEL = process.env.SILICONFLOW_MODEL || "moonshotai/Kimi-K2.6";
const REQUEST_TIMEOUT_MS = 120_000;

if (!API_KEY) {
  console.error(
    "Missing SILICONFLOW_API_KEY. Set it as a Windows user environment variable. Do not hardcode it in repo files."
  );
  process.exit(1);
}

function redactPotentialSecrets(text) {
  if (!text || typeof text !== "string") return "";
  return text
    .replace(/sk-[A-Za-z0-9_\-]{12,}/g, "[REDACTED_SECRET]")
    .replace(/Bearer\s+[A-Za-z0-9_\.\-]{12,}/gi, "Bearer [REDACTED_SECRET]")
    .replace(/SILICONFLOW_API_KEY\s*=\s*[^\s]+/gi, "SILICONFLOW_API_KEY=[REDACTED_SECRET]");
}

const server = new McpServer({
  name: "siliconflow-kimi-mcp-server",
  version: "0.1.0",
});

server.registerTool(
  "ask_kimi_k2_6",
  {
    description:
      "Ask SiliconFlow-hosted Kimi K2.6 for an outside senior-reviewer perspective on coding, debugging, architecture, Godot implementation, refactoring, or playtest strategy. Advisory only.",
    inputSchema: z.object({
      task: z
        .string()
        .min(1)
        .describe("The specific question, bug, implementation plan, or review request for Kimi K2.6."),
      context: z
        .string()
        .optional()
        .describe("Relevant code snippets, file summaries, errors, runtime observations, constraints, or repo context. Do not include secrets."),
      mode: z
        .enum([
          "general",
          "debugging",
          "code_review",
          "architecture_review",
          "implementation_plan",
          "godot_playtest_plan",
          "regression_risk_review"
        ])
        .default("general")
        .describe("The type of advisory review requested."),
      max_tokens: z
        .number()
        .int()
        .min(256)
        .max(12000)
        .default(4000)
        .describe("Maximum output tokens to request from Kimi."),
      temperature: z
        .number()
        .min(0)
        .max(2)
        .default(0.2)
        .describe("Sampling temperature. Lower is better for code review and debugging.")
    }),
  },
  async ({ task, context = "", mode = "general", max_tokens = 4000, temperature = 0.2 }) => {
    const safeTask = redactPotentialSecrets(task);
    const safeContext = redactPotentialSecrets(context);

    const system = [
      "You are Kimi K2.6, acting as a senior software engineer, Godot 4.x reviewer, debugging partner, and architecture critic.",
      "You are being called from Cursor through a local MCP tool.",
      "You cannot edit files, run tests, inspect files directly, or verify runtime behavior unless explicit context is provided.",
      "Do not claim that you changed files, ran tests, inspected the repo, or verified runtime behavior.",
      "Focus on practical, implementation-ready advice.",
      "For Godot tasks, prefer Godot 4.x-compatible guidance.",
      "Identify likely root causes, safe minimal patches, regression risks, and test/playtest steps.",
      "Flag uncertainty, missing context, and assumptions.",
      "Do not request, reveal, or process secrets.",
      "Structure answers with concise headings where useful."
    ].join("\n");

    const user = [
      `Mode: ${mode}`,
      "",
      "Task:",
      safeTask,
      "",
      "Context:",
      safeContext || "(No additional context provided.)"
    ].join("\n");

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
            { role: "system", content: system },
            { role: "user", content: user }
          ],
          max_tokens,
          temperature,
          top_p: 0.7,
          stream: false
        })
      });
    } catch (error) {
      const message = error?.name === "AbortError"
        ? `SiliconFlow/Kimi request timed out after ${REQUEST_TIMEOUT_MS / 1000} seconds.`
        : `SiliconFlow/Kimi request failed: ${error?.message || String(error)}`;

      return {
        isError: true,
        content: [
          {
            type: "text",
            text: redactPotentialSecrets(message)
          }
        ]
      };
    } finally {
      clearTimeout(timeout);
    }

    const raw = await response.text();

    if (!response.ok) {
      return {
        isError: true,
        content: [
          {
            type: "text",
            text:
              `SiliconFlow/Kimi API error ${response.status}.\n\n` +
              "No API key was printed by this tool.\n\n" +
              redactPotentialSecrets(raw)
          }
        ]
      };
    }

    let data;
    try {
      data = JSON.parse(raw);
    } catch {
      return {
        isError: true,
        content: [
          {
            type: "text",
            text: `Could not parse SiliconFlow response as JSON. Raw response:\n\n${redactPotentialSecrets(raw)}`
          }
        ]
      };
    }

    const messageContent = data?.choices?.[0]?.message?.content;
    const finishReason = data?.choices?.[0]?.finish_reason;

    if (typeof messageContent !== "string" || !messageContent.trim()) {
      return {
        isError: true,
        content: [
          {
            type: "text",
            text:
              "SiliconFlow responded, but no visible final content was returned.\n\n" +
              "Likely causes: max_tokens was too small, or the model used its output budget for thinking/reasoning behavior instead of final answer content.\n\n" +
              `Retry with a larger max_tokens value.${finishReason ? `\n\nfinish_reason: ${redactPotentialSecrets(String(finishReason))}` : ""}`
          }
        ]
      };
    }

    return {
      content: [
        {
          type: "text",
          text: redactPotentialSecrets(messageContent)
        }
      ]
    };
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
