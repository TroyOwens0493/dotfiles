#!/usr/bin/env node
import { readdir, stat } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import {
  codexSessionsRoot,
  exportPiSessionFile,
  outputPathForSession,
  parsePiSessionJsonl,
} from "./src/codex-log.ts";
import { readFile } from "node:fs/promises";

interface Options {
  input: string;
  output: string;
  dryRun: boolean;
}

function parseArgs(args: string[]): Options {
  let input = join(homedir(), ".pi", "agent", "sessions");
  let output = codexSessionsRoot();
  let dryRun = false;

  for (let index = 0; index < args.length; index += 1) {
    const argument = args[index];
    if (argument === "--input") {
      const value = args[++index];
      if (!value) throw new Error("--input requires a path");
      input = resolve(value);
    } else if (argument === "--output") {
      const value = args[++index];
      if (!value) throw new Error("--output requires a path");
      output = resolve(value);
    } else if (argument === "--dry-run") {
      dryRun = true;
    } else if (argument === "--help" || argument === "-h") {
      console.log(`Usage: node --experimental-strip-types import.ts [options]

Options:
  --input <path>   Pi sessions root (default: ~/.pi/agent/sessions)
  --output <path>  Codex sessions root (default: ~/.codex/sessions)
  --dry-run        Show what would be written without changing files
  -h, --help       Show this help`);
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${argument}`);
    }
  }

  return { input, output, dryRun };
}

async function findJsonlFiles(root: string) {
  const files: string[] = [];

  async function visit(path: string) {
    for (const entry of await readdir(path, { withFileTypes: true })) {
      const child = join(path, entry.name);
      if (entry.isDirectory()) await visit(child);
      else if (entry.isFile() && entry.name.endsWith(".jsonl"))
        files.push(child);
    }
  }

  const info = await stat(root);
  if (info.isFile()) return root.endsWith(".jsonl") ? [root] : [];
  await visit(root);
  return files.sort();
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const files = await findJsonlFiles(options.input);
  let exported = 0;
  let failed = 0;
  let records = 0;

  for (const inputPath of files) {
    try {
      if (options.dryRun) {
        const contents = await readFile(inputPath, "utf8");
        const { header, entries } = parsePiSessionJsonl(contents);
        const outputPath = outputPathForSession(header, options.output);
        console.log(
          `${inputPath} -> ${outputPath} (${entries.length} Pi entries)`,
        );
      } else {
        const result = await exportPiSessionFile(inputPath, options.output);
        exported += 1;
        records += result.records.length;
        console.log(`${inputPath} -> ${result.outputPath}`);
      }
    } catch (error) {
      failed += 1;
      console.error(
        `Failed to export ${inputPath}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  if (options.dryRun) {
    console.log(
      `Dry run complete: ${files.length - failed} sessions ready, ${failed} failed.`,
    );
  } else {
    console.log(
      `Export complete: ${exported} sessions, ${records} Codex records, ${failed} failed.`,
    );
  }

  if (failed > 0) process.exitCode = 1;
}

await main();
