#!/usr/bin/env bash
# Sets up AI agent instructions, architecture rules, localization dictionaries,
# and stack dependencies for a new or existing Next.js, NestJS, or Flutter project.
#
# Usage:
#   # 1. Inside an existing app (e.g. after `flutter create myapp && cd myapp`):
#   bash <(curl -fsSL https://raw.githubusercontent.com/dinethsiriwardana/ai-agent-instructions-template/main/scripts/init-template.sh)
#
#   # 2. From a local clone (interactive):
#   bash scripts/init-template.sh
#
#   # 3. Headless / CLI mode:
#   bash scripts/init-template.sh --stack flutter --target ./myapp \
#        --name "My App" --description "Mobile client" --owner "Jane Doe" [--install | --no-install]
#
# Stacks: nextjs | nestjs | flutter  (see templates/<stack>/)

set -euo pipefail

TEMPLATE_REPO_URL="${TEMPLATE_REPO_URL:-https://github.com/dinethsiriwardana/ai-agent-instructions-template.git}"
TEMPLATE_ARCHIVE_URL="${TEMPLATE_ARCHIVE_URL:-https://github.com/dinethsiriwardana/ai-agent-instructions-template/archive/refs/heads}"
TEMPLATE_REPO_BRANCH="${TEMPLATE_REPO_BRANCH:-main}"

STACKS=(nextjs nestjs flutter)

STACK=""
TARGET=""
PROJECT_NAME=""
ONE_LINE_DESCRIPTION=""
OWNER_NAME=""
INSTALL_DEPS="auto"
HEADLESS_ARGS=0

usage() {
  sed -n '2,16p' "${BASH_SOURCE[0]:-$0}" 2>/dev/null | sed 's/^# \{0,1\}//' || true
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stack) STACK="${2:-}"; HEADLESS_ARGS=1; shift 2 ;;
    --target) TARGET="${2:-}"; HEADLESS_ARGS=1; shift 2 ;;
    --name) PROJECT_NAME="${2:-}"; HEADLESS_ARGS=1; shift 2 ;;
    --description) ONE_LINE_DESCRIPTION="${2:-}"; HEADLESS_ARGS=1; shift 2 ;;
    --owner) OWNER_NAME="${2:-}"; HEADLESS_ARGS=1; shift 2 ;;
    --branch) TEMPLATE_REPO_BRANCH="${2:-main}"; shift 2 ;;
    --install) INSTALL_DEPS="yes"; shift 1 ;;
    --no-install) INSTALL_DEPS="no"; shift 1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

# Locate template ROOT (local checkout vs remote execution via curl)
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
ROOT=""
TMP_TEMPLATE_DIR=""

cleanup() {
  if [[ -n "$TMP_TEMPLATE_DIR" && -d "$TMP_TEMPLATE_DIR" ]]; then
    rm -rf "$TMP_TEMPLATE_DIR"
  fi
}
trap cleanup EXIT

if [[ -n "$SCRIPT_SOURCE" && -f "$SCRIPT_SOURCE" ]]; then
  CANDIDATE_ROOT="$(cd "$(dirname "$SCRIPT_SOURCE")/.." 2>/dev/null && pwd || true)"
  if [[ -n "$CANDIDATE_ROOT" && -d "$CANDIDATE_ROOT/core" && -d "$CANDIDATE_ROOT/templates" ]]; then
    ROOT="$CANDIDATE_ROOT"
  fi
fi

if [[ -z "$ROOT" ]]; then
  TMP_TEMPLATE_DIR="$(mktemp -d)"
  echo "⬇️  Downloading ai-agent-instructions-template ($TEMPLATE_REPO_BRANCH)..."
  if command -v git >/dev/null 2>&1; then
    git clone --depth 1 --branch "$TEMPLATE_REPO_BRANCH" "$TEMPLATE_REPO_URL" "$TMP_TEMPLATE_DIR/repo" >/dev/null 2>&1 \
      || git clone --depth 1 "$TEMPLATE_REPO_URL" "$TMP_TEMPLATE_DIR/repo" >/dev/null 2>&1
    ROOT="$TMP_TEMPLATE_DIR/repo"
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$TEMPLATE_ARCHIVE_URL/$TEMPLATE_REPO_BRANCH.tar.gz" | tar -xz -C "$TMP_TEMPLATE_DIR"
    ROOT="$(find "$TMP_TEMPLATE_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  else
    echo "Error: Either 'git' or 'curl' is required to download the template." >&2
    exit 1
  fi
fi

prompt_read() {
  local prompt_text="$1"
  local default_val="${2:-}"
  local reply_var=""
  if [[ -n "$default_val" ]]; then
    if [[ -t 0 ]]; then
      read -r -p "$prompt_text [$default_val]: " reply_var
    elif [[ -r /dev/tty ]]; then
      read -r -p "$prompt_text [$default_val]: " reply_var < /dev/tty
    fi
    printf "%s" "${reply_var:-$default_val}"
  else
    if [[ -t 0 ]]; then
      read -r -p "$prompt_text: " reply_var
    elif [[ -r /dev/tty ]]; then
      read -r -p "$prompt_text: " reply_var < /dev/tty
    fi
    printf "%s" "$reply_var"
  fi
}

# 1. Resolve Target Directory first so we can auto-detect stack & project details
if [[ -z "$TARGET" ]]; then
  DEFAULT_TARGET="."
  if [[ "$PWD" == "$ROOT" ]]; then
    DEFAULT_TARGET=""
  fi
  TARGET="$(prompt_read "Target project folder (created if missing)" "$DEFAULT_TARGET")"
fi

if [[ -z "$TARGET" ]]; then
  echo "Target folder is required." >&2
  exit 1
fi

mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

if [[ "$TARGET" == "$ROOT" ]]; then
  echo "Target must not be the template repository folder itself." >&2
  exit 1
fi

# 2. Auto-detect existing stack & project name inside $TARGET
DETECTED_STACK=""
DETECTED_NAME=""
HAS_EXISTING_PROJECT=0

if [[ -f "$TARGET/pubspec.yaml" ]]; then
  DETECTED_STACK="flutter"
  HAS_EXISTING_PROJECT=1
  DETECTED_NAME="$(awk -F': *' '/^name:/ {print $2; exit}' "$TARGET/pubspec.yaml" | tr -d "\"'[:space:]")"
elif [[ -f "$TARGET/package.json" ]]; then
  HAS_EXISTING_PROJECT=1
  if grep -q '"@nestjs/core"' "$TARGET/package.json" 2>/dev/null; then
    DETECTED_STACK="nestjs"
  elif grep -q '"next"' "$TARGET/package.json" 2>/dev/null; then
    DETECTED_STACK="nextjs"
  fi
  if command -v node >/dev/null 2>&1; then
    DETECTED_NAME="$(node -e 'try { console.log(require(process.argv[1]).name || ""); } catch(e) {}' "$TARGET/package.json")"
  fi
fi

[[ -z "$DETECTED_NAME" ]] && DETECTED_NAME="$(basename "$TARGET")"

if [[ -z "$STACK" ]]; then
  if [[ -n "$DETECTED_STACK" ]]; then
    echo "✨ Auto-detected stack in $TARGET: $DETECTED_STACK"
    STACK="$(prompt_read "Confirm stack (nextjs | nestjs | flutter)" "$DETECTED_STACK")"
  else
    echo "Select a stack:"
    if [[ -t 0 ]]; then
      select choice in "${STACKS[@]}"; do
        STACK="${choice:-}"
        [[ -n "$STACK" ]] && break
      done
    elif [[ -r /dev/tty ]]; then
      select choice in "${STACKS[@]}"; do
        STACK="${choice:-}"
        [[ -n "$STACK" ]] && break
      done < /dev/tty
    fi
  fi
fi

if [[ ! -d "$ROOT/templates/$STACK" ]]; then
  echo "Unknown stack '$STACK'. Available: ${STACKS[*]}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ROOT/templates/$STACK/stack.conf"

# 3. Resolve Project Metadata
if [[ -z "$PROJECT_NAME" ]]; then
  PROJECT_NAME="$(prompt_read "Project name" "$DETECTED_NAME")"
fi

if [[ -z "$ONE_LINE_DESCRIPTION" ]]; then
  ONE_LINE_DESCRIPTION="$(prompt_read "One-line description" "$PROJECT_NAME ($STACK_LABEL application)")"
fi

if [[ -z "$OWNER_NAME" ]]; then
  DEFAULT_OWNER="$(git config user.name 2>/dev/null || echo "Developer")"
  OWNER_NAME="$(prompt_read "Owner name" "$DEFAULT_OWNER")"
fi

if [[ -z "$PROJECT_NAME" || -z "$TARGET" ]]; then
  echo "Project name and target folder are required." >&2
  exit 1
fi

# 4. Decide whether to install dependencies / run stack setup
SHOULD_INSTALL=0
if [[ "$INSTALL_DEPS" == "yes" ]]; then
  SHOULD_INSTALL=1
elif [[ "$INSTALL_DEPS" == "no" ]]; then
  SHOULD_INSTALL=0
else
  # Auto mode:
  # - If headless CLI args were passed on an empty directory without --install, skip install (keeps template tests fast).
  # - Otherwise (existing project or interactive wizard), ask the user (default Y).
  if [[ "$HEADLESS_ARGS" -eq 1 && "$HAS_EXISTING_PROJECT" -eq 0 ]]; then
    SHOULD_INSTALL=0
  else
    INSTALL_ANSWER="$(prompt_read "Install & configure $STACK_LABEL packages/dependencies in $TARGET? (Y/n)" "Y")"
    if [[ "$INSTALL_ANSWER" =~ ^[Yy] ]]; then
      SHOULD_INSTALL=1
    fi
  fi
fi

# 5. If installing into an empty directory, run setup_stack first so framework CLI can scaffold cleanly
if [[ "$SHOULD_INSTALL" -eq 1 && "$HAS_EXISTING_PROJECT" -eq 0 ]]; then
  if declare -f setup_stack >/dev/null 2>&1; then
    setup_stack "$TARGET"
  fi
fi

# Backup existing framework README.md if present so it isn't lost when overlaying template README.md
if [[ -f "$TARGET/README.md" ]] && ! grep -q "AGENTS.md" "$TARGET/README.md" 2>/dev/null; then
  cp "$TARGET/README.md" "$TARGET/README.framework.md"
  echo "ℹ️  Backed up existing README.md to README.framework.md"
fi

# 6. Copy core/ + templates/$STACK/ into $TARGET and track copied files for safe placeholder replacement
copy_tree() {
  local src="$1" dest="$2"
  shift 2
  (cd "$src" && tar "$@" -cf - .) | (cd "$dest" && tar -xf -)
}

COPIED_FILES=()
while IFS= read -r -d '' rel; do
  rel="${rel#./}"
  COPIED_FILES+=("$TARGET/$rel")
done < <(cd "$ROOT/core" && find . -type f -print0)

while IFS= read -r -d '' rel; do
  rel="${rel#./}"
  [[ "$rel" == "stack.conf" ]] && continue
  COPIED_FILES+=("$TARGET/$rel")
done < <(cd "$ROOT/templates/$STACK" && find . -type f -print0)

copy_tree "$ROOT/core" "$TARGET"
copy_tree "$ROOT/templates/$STACK" "$TARGET" --exclude=./stack.conf

export PROJECT_NAME ONE_LINE_DESCRIPTION OWNER_NAME STACK_LABEL QUALITY_GATE

for file in "${COPIED_FILES[@]}"; do
  [[ -f "$file" ]] || continue
  case "$file" in
    *.md|*.yml|*.yaml|*.json|*.arb)
      perl -pi -e '
        s/\{\{PROJECT_NAME\}\}/$ENV{PROJECT_NAME}/g;
        s/\{\{ONE_LINE_DESCRIPTION\}\}/$ENV{ONE_LINE_DESCRIPTION}/g;
        s/\{\{OWNER_NAME\}\}/$ENV{OWNER_NAME}/g;
        s/\{\{STACK_LABEL\}\}/$ENV{STACK_LABEL}/g;
        s/\{\{QUALITY_GATE\}\}/$ENV{QUALITY_GATE}/g;
      ' "$file"
      ;;
  esac
done

TODAY="$(date +%Y-%m-%d)"
for doc in "$TARGET/docs/PROJECT_PLAN.md" "$TARGET/docs/DECISIONS.md"; do
  [[ -f "$doc" ]] && perl -pi -e "s/YYYY-MM-DD/$TODAY/g" "$doc"
done

# 7. If installing into an existing project (e.g. after `flutter create myapp`), run setup_stack now
#    (after l10n.yaml / ARB / locale files have been copied so `flutter gen-l10n` succeeds immediately)
if [[ "$SHOULD_INSTALL" -eq 1 && "$HAS_EXISTING_PROJECT" -eq 1 ]]; then
  if declare -f setup_stack >/dev/null 2>&1; then
    setup_stack "$TARGET"
  fi
fi

echo ""
echo "✅ Done! Configured $STACK_LABEL AI agent instructions & project setup for \"$PROJECT_NAME\" in: $TARGET"
echo "👉 Next: open $TARGET/README.md and $TARGET/AGENTS.md to start building."

