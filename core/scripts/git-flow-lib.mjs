export const VALID_PREFIXES = ["feat", "fix", "chore", "docs", "refactor", "hotfix"];

export function validateBranchName(name) {
  if (!name || typeof name !== "string") {
    return { valid: false, error: "Branch name is required and must be a string." };
  }
  const trimmed = name.trim();
  const pattern = /^(feat|fix|chore|docs|refactor|hotfix)\/[a-z0-9._-]+$/;
  if (!pattern.test(trimmed)) {
    return {
      valid: false,
      error: `Invalid branch name "${trimmed}". Must start with ${VALID_PREFIXES.join("/")} followed by slash and kebab-case name (e.g. feat/client-export).`,
    };
  }
  return { valid: true };
}

export function parseBranchesMarkdown(content) {
  if (!content || typeof content !== "string") return [];
  const lines = content.split(/\r?\n/);
  const tableStartIndex = lines.findIndex((l) => l.trim().startsWith("| Branch | Status |"));
  if (tableStartIndex === -1) return [];

  const entries = [];
  for (let i = tableStartIndex + 2; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line.startsWith("|")) break;
    const cols = line
      .split("|")
      .map((c) => c.trim())
      .filter((_, idx, arr) => idx > 0 && idx < arr.length - 1);
    if (cols.length >= 7) {
      entries.push({
        branch: cols[0].replace(/`/g, ""),
        status: cols[1].replace(/`/g, ""),
        target: cols[2].replace(/`/g, ""),
        updated: cols[3],
        description: cols[4],
        prLink: cols[5],
        historyRef: cols[6],
      });
    }
  }
  return entries;
}

export function updateBranchesMarkdown(content, entry) {
  const today = entry.updated || new Date().toISOString().slice(0, 10);
  const target = entry.target || "dev-test";
  const desc = entry.description || "In progress";
  const pr = entry.prLink || "-";
  const ref = entry.historyRef || "Current Work";

  const lines = content.split(/\r?\n/);
  const headerIdx = lines.findIndex((l) => l.trim().startsWith("| Branch | Status |"));
  if (headerIdx === -1) return content;

  const rowPrefix = `| \`${entry.branch}\` |`;
  const existingIdx = lines.findIndex((l) => l.trim().startsWith(rowPrefix));

  if (existingIdx !== -1) {
    const currentCols = lines[existingIdx]
      .split("|")
      .map((c) => c.trim())
      .filter((_, idx, arr) => idx > 0 && idx < arr.length - 1);

    const updatedDesc = entry.description || currentCols[4];
    const updatedPr = entry.prLink || currentCols[5];
    const updatedRef = entry.historyRef || currentCols[6];

    lines[existingIdx] = `| \`${entry.branch}\` | \`${entry.status}\` | \`${target}\` | ${today} | ${updatedDesc} | ${updatedPr} | ${updatedRef} |`;
    return lines.join("\n");
  }

  const separatorIdx = headerIdx + 1;
  const newRow = `| \`${entry.branch}\` | \`${entry.status}\` | \`${target}\` | ${today} | ${desc} | ${pr} | ${ref} |`;
  lines.splice(separatorIdx + 1, 0, newRow);
  return lines.join("\n");
}

export function buildPrUrl({ repoUrl = "", base = "dev-test", head = "", title = "", body = "" } = {}) {
  const cleanRepo = (repoUrl || "https://github.com/owner/repo")
    .replace(/\.git$/, "")
    .replace(/^git@github.com:/, "https://github.com/");
  const params = new URLSearchParams();
  params.set("expand", "1");
  if (title) params.set("title", title);
  if (body) params.set("body", body);
  return `${cleanRepo}/compare/${base}...${head}?${params.toString()}`;
}

