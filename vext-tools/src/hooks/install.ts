#!/usr/bin/env -S deno run --allow-read --allow-write
// SPDX-License-Identifier: MIT OR AGPL-3.0-or-later
/**
 * vext hook installer
 *
 * Installs git hooks for vext notifications.
 */

import { parseArgs } from "@std/cli/parse-args";
import { ensureDir } from "@std/fs";
import { dirname, join } from "@std/path";

const HOOK_TEMPLATE = `#!/bin/sh
# vext post-receive hook
# Sends commit notifications to IRC via vextd
#
# Configuration (set in environment or uncomment below):
# export VEXT_SERVER="127.0.0.1:6659"
# export VEXT_TARGETS="irc://irc.libera.chat/your-channel"
# export VEXT_PROJECT="your-project"
# export VEXT_URL="https://github.com/you/repo"

# Run the hook
exec deno run --allow-net --allow-env --allow-read \\
  "HOOK_PATH" "$@"
`;

async function findGitDir(): Promise<string | null> {
  const cmd = new Deno.Command("git", {
    args: ["rev-parse", "--git-dir"],
    stdout: "piped",
    stderr: "null",
  });
  const output = await cmd.output();
  if (!output.success) {
    return null;
  }
  return new TextDecoder().decode(output.stdout).trim();
}

async function installHook(
  gitDir: string,
  hookPath: string,
  force: boolean
): Promise<boolean> {
  const hooksDir = join(gitDir, "hooks");
  const targetPath = join(hooksDir, "post-receive");

  // Check if hook already exists
  try {
    const stat = await Deno.stat(targetPath);
    if (stat.isFile && !force) {
      console.error(`Hook already exists: ${targetPath}`);
      console.error("Use --force to overwrite");
      return false;
    }
  } catch {
    // File doesn't exist, that's fine
  }

  await ensureDir(hooksDir);

  // Generate hook content
  const content = HOOK_TEMPLATE.replace("HOOK_PATH", hookPath);

  await Deno.writeTextFile(targetPath, content);
  await Deno.chmod(targetPath, 0o755);

  console.log(`Installed hook: ${targetPath}`);
  return true;
}

async function main() {
  const args = parseArgs(Deno.args, {
    string: ["git-dir", "hook-path"],
    boolean: ["help", "force", "symlink"],
    alias: {
      h: "help",
      f: "force",
    },
  });

  if (args.help) {
    console.log(`vext hook installer

Usage: install.ts [options]

Options:
  --git-dir     Path to .git directory (auto-detected if not specified)
  --hook-path   Path to the git.ts hook script
  --force, -f   Overwrite existing hook
  --symlink     Create symlink instead of wrapper script
  --help, -h    Show this help

Example:
  deno run --allow-read --allow-write install.ts --force
`);
    Deno.exit(0);
  }

  // Find git directory
  let gitDir = args["git-dir"];
  if (!gitDir) {
    gitDir = await findGitDir();
    if (!gitDir) {
      console.error("Not in a git repository. Use --git-dir to specify.");
      Deno.exit(1);
    }
  }

  // Find hook script path
  let hookPath = args["hook-path"];
  if (!hookPath) {
    // Default to the git.ts in the same directory as this script
    hookPath = new URL("./git.ts", import.meta.url).pathname;
  }

  // Install the hook
  const success = await installHook(gitDir, hookPath, args.force);

  if (success) {
    console.log(`
Hook installed successfully!

Configure by setting environment variables:
  VEXT_SERVER      vextd server (default: 127.0.0.1:6659)
  VEXT_TARGETS     IRC targets, comma-separated
  VEXT_PROJECT     Project name
  VEXT_URL         Base URL for commit links

Or edit the hook file directly:
  ${join(gitDir, "hooks", "post-receive")}
`);
  } else {
    Deno.exit(1);
  }
}

main().catch((err) => {
  console.error(`Error: ${err}`);
  Deno.exit(1);
});
