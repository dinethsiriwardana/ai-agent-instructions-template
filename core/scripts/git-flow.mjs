import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";
import {
  validateBranchName,
  parseBranchesMarkdown,
  updateBranchesMarkdown,
  buildPrUrl,
} from "./git-flow-lib.mjs";

const rootDir = process.cwd();
const branchesFilePath = path.join(rootDir, "BRANCHES.md");

function run(cmd, { stdio = "pipe" } = {}) {
  return execSync(cmd, { cwd: rootDir, encoding: "utf8", stdio });
}

function runSafe(cmd) {
  try {
    return run(cmd).trim();
  } catch {
    return "";
  }
}

function getCurrentBranch() {
  return runSafe("git rev-parse --abbrev-ref HEAD");
}

function syncRegistry(entry) {
  if (!fs.existsSync(branchesFilePath)) return;
  const content = fs.readFileSync(branchesFilePath, "utf8");
  const updated = updateBranchesMarkdown(content, entry);
  fs.writeFileSync(branchesFilePath, updated, "utf8");
}

function handleStart(branchName, description) {
  const check = validateBranchName(branchName);
  if (!check.valid) {
    console.error(`❌ ${check.error}`);
    process.exit(1);
  }

  console.log(`🔄 Fetching latest origin/dev-test...`);
  runSafe("git fetch origin dev-test");

  const localBranch = runSafe(`git branch --list ${branchName}`);
  const remoteBranch = runSafe(`git ls-remote --heads origin ${branchName}`);

  if (localBranch) {
    console.log(`📌 Switching to existing local branch: ${branchName}`);
    run(`git checkout ${branchName}`);
    runSafe(`git merge origin/dev-test --no-edit`);
  } else if (remoteBranch) {
    console.log(`📌 Checking out remote tracking branch: ${branchName}`);
    run(`git checkout -b ${branchName} --track origin/${branchName}`);
    runSafe(`git merge origin/dev-test --no-edit`);
  } else {
    console.log(`🌱 Creating new branch off dev-test: ${branchName}`);
    const hasRemoteDevTest = runSafe("git branch -r --list origin/dev-test");
    if (hasRemoteDevTest) {
      run(`git checkout -b ${branchName} origin/dev-test`);
    } else {
      run(`git checkout -b ${branchName}`);
    }
  }

  syncRegistry({
    branch: branchName,
    status: "Active",
    target: "dev-test",
    description: description || "In progress",
  });
  console.log(`✅ Branch ${branchName} is ready and registered in BRANCHES.md.`);
}

function handleSync() {
  const branch = getCurrentBranch();
  if (["main", "dev", "dev-test"].includes(branch)) {
    console.error(`❌ Cannot sync base branch ${branch}. Switch to a feature/fix branch.`);
    process.exit(1);
  }
  console.log(`🔄 Fetching and merging latest origin/dev-test into ${branch}...`);
  run("git fetch origin dev-test");
  run("git merge origin/dev-test --no-edit");
  syncRegistry({ branch, status: "Active" });
  console.log(`✅ Branch ${branch} is up to date with origin/dev-test.`);
}

function handlePr(args) {
  const branch = getCurrentBranch();
  if (["main", "dev", "dev-test"].includes(branch)) {
    console.error(`❌ Current branch is ${branch}. PR must be created from a feature/fix branch.`);
    process.exit(1);
  }

  const noVerify = args.includes("--no-verify");
  if (!noVerify) {
    console.log(`🧪 Running typecheck, lint, and tests...`);
    run("npm run typecheck", { stdio: "inherit" });
    run("npm run lint", { stdio: "inherit" });
    run("npm test", { stdio: "inherit" });
  }

  console.log(`🚀 Pushing branch ${branch} to origin...`);
  run(`git push -u origin ${branch}`);

  const title = args.find((a) => !a.startsWith("-")) || `${branch.split("/")[0]}: updates for ${branch}`;
  let prUrl = "";

  try {
    const ghOutput = run(
      `gh pr create --base dev-test --head ${branch} --title "${title}" --body "Automated PR targeting dev-test for ${branch}."`
    ).trim();
    console.log(`✅ Pull Request created via GitHub CLI: ${ghOutput}`);
    prUrl = ghOutput;
  } catch {
    const remoteUrl = runSafe("git config --get remote.origin.url");
    prUrl = buildPrUrl({ repoUrl: remoteUrl, base: "dev-test", head: branch, title });
    console.log(`\n🔗 Create Pull Request via GitHub web interface:\n${prUrl}\n`);
  }

  syncRegistry({
    branch,
    status: "In Review",
    prLink: prUrl.startsWith("http") ? `[PR](${prUrl})` : prUrl,
  });
  console.log(`\n📢 Ready for user testing! Review the PR and verify before approving merge.`);
}

function handleFinish() {
  const branch = getCurrentBranch();
  if (["main", "dev", "dev-test"].includes(branch)) {
    console.error(`❌ You are currently on ${branch}. Switch to the branch you want to finish.`);
    process.exit(1);
  }

  console.log(`🔄 Switching back to dev-test and pulling latest changes...`);
  run("git checkout dev-test");
  runSafe("git pull origin dev-test");

  syncRegistry({
    branch,
    status: "Merged",
  });

  try {
    run(`git branch -d ${branch}`);
    console.log(`🗑️  Deleted local branch ${branch}.`);
  } catch {
    console.log(`ℹ️  Local branch ${branch} kept (unmerged locally or force delete needed).`);
  }

  console.log(`✨ Workflow completed! Workspace is clean on dev-test.`);
}

function handleList() {
  if (!fs.existsSync(branchesFilePath)) {
    console.log("No BRANCHES.md found.");
    return;
  }
  const content = fs.readFileSync(branchesFilePath, "utf8");
  const entries = parseBranchesMarkdown(content);
  console.log("\n📋 Active & Tracked Branches in BRANCHES.md:\n");
  for (const e of entries) {
    const badge = e.status === "Active" ? "🟢" : e.status === "In Review" ? "🟡" : "⚪";
    console.log(`${badge} ${e.branch.padEnd(30)} [${e.status}] (Target: ${e.target})`);
    console.log(`   Scope: ${e.description}`);
    if (e.prLink !== "-") console.log(`   PR:    ${e.prLink}`);
    console.log();
  }
}

const [action, ...rest] = process.argv.slice(2);
switch (action) {
  case "start":
    handleStart(rest[0], rest.slice(1).join(" "));
    break;
  case "sync":
    handleSync();
    break;
  case "pr":
    handlePr(rest);
    break;
  case "finish":
    handleFinish();
    break;
  case "list":
  case "status":
    handleList();
    break;
  default:
    console.log(`Usage: node scripts/git-flow.mjs <start|sync|pr|finish|list>`);
    process.exit(action ? 1 : 0);
}

