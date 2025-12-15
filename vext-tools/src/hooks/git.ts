#!/usr/bin/env -S deno run --allow-net --allow-env --allow-read
// SPDX-License-Identifier: MIT OR AGPL-3.0-or-later
/**
 * vext Git post-receive hook
 *
 * Reads pushed refs from stdin and sends notifications to vextd.
 * Install by copying to .git/hooks/post-receive or using the installer.
 */

import { parseArgs } from "@std/cli/parse-args";

interface CommitInfo {
  hash: string;
  shortHash: string;
  author: string;
  authorEmail: string;
  subject: string;
  body: string;
  timestamp: string;
}

interface RefUpdate {
  oldRef: string;
  newRef: string;
  refName: string;
}

interface Notification {
  to: string[];
  privmsg: string;
  project?: string;
  branch?: string;
  commit?: string;
  author?: string;
  url?: string;
}

// Configuration from environment
const config = {
  server: Deno.env.get("VEXT_SERVER") || "127.0.0.1:6659",
  targets: (Deno.env.get("VEXT_TARGETS") || "").split(",").filter(Boolean),
  project: Deno.env.get("VEXT_PROJECT") || Deno.env.get("GL_PROJECT_PATH"),
  baseUrl: Deno.env.get("VEXT_URL"),
  maxCommits: parseInt(Deno.env.get("VEXT_MAX_COMMITS") || "5"),
  colors: Deno.env.get("VEXT_COLORS") !== "false",
};

async function runGit(args: string[]): Promise<string> {
  const cmd = new Deno.Command("git", {
    args,
    stdout: "piped",
    stderr: "piped",
  });
  const output = await cmd.output();
  if (!output.success) {
    throw new Error(`git ${args.join(" ")} failed`);
  }
  return new TextDecoder().decode(output.stdout).trim();
}

async function getCommitInfo(hash: string): Promise<CommitInfo> {
  const format = "%H%n%h%n%an%n%ae%n%s%n%b%n%aI";
  const output = await runGit(["log", "-1", `--format=${format}`, hash]);
  const lines = output.split("\n");

  return {
    hash: lines[0],
    shortHash: lines[1],
    author: lines[2],
    authorEmail: lines[3],
    subject: lines[4],
    body: lines.slice(5, -1).join("\n"),
    timestamp: lines[lines.length - 1],
  };
}

async function getCommitsBetween(
  oldRef: string,
  newRef: string
): Promise<string[]> {
  // Handle new branch (oldRef is all zeros)
  if (oldRef === "0000000000000000000000000000000000000000") {
    // Get commits reachable from newRef that aren't in any other branch
    const output = await runGit([
      "rev-list",
      "--max-count=" + config.maxCommits,
      newRef,
    ]);
    return output.split("\n").filter(Boolean);
  }

  // Handle deleted branch (newRef is all zeros)
  if (newRef === "0000000000000000000000000000000000000000") {
    return [];
  }

  const output = await runGit([
    "rev-list",
    "--max-count=" + config.maxCommits,
    `${oldRef}..${newRef}`,
  ]);
  return output.split("\n").filter(Boolean);
}

function extractBranchName(refName: string): string {
  if (refName.startsWith("refs/heads/")) {
    return refName.slice("refs/heads/".length);
  }
  if (refName.startsWith("refs/tags/")) {
    return `tag/${refName.slice("refs/tags/".length)}`;
  }
  return refName;
}

function formatCommitMessage(
  commit: CommitInfo,
  branch: string,
  project?: string
): string {
  const parts: string[] = [];

  if (project) {
    parts.push(`[${project}]`);
  }

  parts.push(`${branch}`);
  parts.push(`${commit.shortHash}`);
  parts.push(`${commit.author}:`);
  parts.push(commit.subject);

  return parts.join(" ");
}

async function sendNotification(notification: Notification): Promise<void> {
  const payload = JSON.stringify(notification) + "\n";

  try {
    const conn = await Deno.connect({
      hostname: config.server.split(":")[0],
      port: parseInt(config.server.split(":")[1] || "6659"),
    });

    const encoder = new TextEncoder();
    await conn.write(encoder.encode(payload));
    conn.close();

    console.error(`[vext] Sent notification to ${config.server}`);
  } catch (err) {
    console.error(`[vext] Failed to send notification: ${err}`);
  }
}

async function processRefUpdate(update: RefUpdate): Promise<void> {
  if (config.targets.length === 0) {
    console.error("[vext] No targets configured (set VEXT_TARGETS)");
    return;
  }

  const branch = extractBranchName(update.refName);

  // Handle branch deletion
  if (update.newRef === "0000000000000000000000000000000000000000") {
    await sendNotification({
      to: config.targets,
      privmsg: `Branch ${branch} deleted`,
      project: config.project,
      branch,
    });
    return;
  }

  // Handle new branch
  if (update.oldRef === "0000000000000000000000000000000000000000") {
    await sendNotification({
      to: config.targets,
      privmsg: `New branch ${branch} created`,
      project: config.project,
      branch,
    });
  }

  // Get commits
  const commits = await getCommitsBetween(update.oldRef, update.newRef);

  if (commits.length === 0) {
    return;
  }

  // Process each commit (most recent first)
  for (const hash of commits.reverse()) {
    try {
      const commit = await getCommitInfo(hash);
      const message = formatCommitMessage(commit, branch, config.project);

      let url: string | undefined;
      if (config.baseUrl) {
        url = `${config.baseUrl}/commit/${commit.hash}`;
      }

      await sendNotification({
        to: config.targets,
        privmsg: message,
        project: config.project,
        branch,
        commit: commit.shortHash,
        author: commit.author,
        url,
      });
    } catch (err) {
      console.error(`[vext] Failed to process commit ${hash}: ${err}`);
    }
  }

  // If there were more commits, note that
  if (commits.length >= config.maxCommits) {
    await sendNotification({
      to: config.targets,
      privmsg: `... and more commits (showing last ${config.maxCommits})`,
      project: config.project,
      branch,
    });
  }
}

async function readStdin(): Promise<RefUpdate[]> {
  const updates: RefUpdate[] = [];
  const decoder = new TextDecoder();
  const buffer = new Uint8Array(1024);

  let input = "";

  // Read all available stdin
  try {
    while (true) {
      const n = await Deno.stdin.read(buffer);
      if (n === null) break;
      input += decoder.decode(buffer.subarray(0, n));
    }
  } catch {
    // stdin might not be available in some contexts
  }

  // Parse ref updates
  for (const line of input.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed) continue;

    const parts = trimmed.split(" ");
    if (parts.length >= 3) {
      updates.push({
        oldRef: parts[0],
        newRef: parts[1],
        refName: parts[2],
      });
    }
  }

  return updates;
}

async function main() {
  const args = parseArgs(Deno.args, {
    string: ["server", "to", "project", "url"],
    boolean: ["help", "version"],
  });

  if (args.help) {
    console.log(`vext git hook - Send commit notifications to IRC

Usage: git.ts [options]

When run as a git post-receive hook, reads ref updates from stdin.

Options:
  --server    vextd server address (default: 127.0.0.1:6659)
  --to        IRC target URL (can specify multiple)
  --project   Project name
  --url       Base URL for commit links
  --help      Show this help
  --version   Show version

Environment variables:
  VEXT_SERVER      vextd server address
  VEXT_TARGETS     Comma-separated IRC target URLs
  VEXT_PROJECT     Project name
  VEXT_URL         Base URL for commit links
  VEXT_MAX_COMMITS Maximum commits to report (default: 5)
`);
    Deno.exit(0);
  }

  if (args.version) {
    console.log("vext-hook 1.0.0");
    Deno.exit(0);
  }

  // Override config from CLI args
  if (args.server) config.server = args.server;
  if (args.to) config.targets = [args.to];
  if (args.project) config.project = args.project;
  if (args.url) config.baseUrl = args.url;

  // Read ref updates from stdin
  const updates = await readStdin();

  if (updates.length === 0) {
    console.error("[vext] No ref updates received from stdin");
    Deno.exit(0);
  }

  // Process each ref update
  for (const update of updates) {
    await processRefUpdate(update);
  }
}

main().catch((err) => {
  console.error(`[vext] Fatal error: ${err}`);
  Deno.exit(1);
});
