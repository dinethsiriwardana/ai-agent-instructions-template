#!/usr/bin/env bash
# Generates a new project's docs/rules from this multi-stack template.
#
# Usage:
#   bash scripts/init-template.sh                      # fully interactive
#   bash scripts/init-template.sh --stack nestjs --target ../my-api \
#        --name "My API" --description "Orders service" --owner "Jane Doe"
#
# Stacks: nextjs | nestjs | flutter  (see templates/<stack>/)
# Copies core/ (shared) + templates/<stack>/ into the target folder, then replaces
# placeholders. Refuses to run if the target already contains files (except .git).
# Works on macOS and Linux (uses perl instead of sed -i, tar instead of rsync).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACKS=(nextjs nestjs flutter)

STACK=""
TARGET=""
PROJECT_NAME=""
ONE_LINE_DESCRIPTION=""
OWNER_NAME=""

usage() {
  sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stack) STACK="${2:-}"; shift 2 ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    --name) PROJECT_NAME="${2:-}"; shift 2 ;;
    --description) ONE_LINE_DESCRIPTION="${2:-}"; shift 2 ;;
    --owner) OWNER_NAME="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ -z "$STACK" ]]; then
  echo "Select a stack:"
  select choice in "${STACKS[@]}"; do
    STACK="${choice:-}"
    [[ -n "$STACK" ]] && break
  done
fi

if [[ ! -d "$ROOT/templates/$STACK" ]]; then
  echo "Unknown stack '$STACK'. Available: ${STACKS[*]}" >&2
  exit 1
fi

[[ -z "$PROJECT_NAME" ]] && read -r -p "Project name: " PROJECT_NAME
[[ -z "$ONE_LINE_DESCRIPTION" ]] && read -r -p "One-line description: " ONE_LINE_DESCRIPTION
[[ -z "$OWNER_NAME" ]] && read -r -p "Owner name: " OWNER_NAME
[[ -z "$TARGET" ]] && read -r -p "Target folder (created if missing): " TARGET

if [[ -z "$PROJECT_NAME" || -z "$TARGET" ]]; then
  echo "Project name and target folder are required." >&2
  exit 1
fi

mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

if [[ "$TARGET" == "$ROOT" ]]; then
  echo "Target must not be the template folder itself." >&2
  exit 1
fi

if [[ -n "$(find "$TARGET" -mindepth 1 -maxdepth 1 -not -name ".git" -print -quit)" ]]; then
  echo "Target folder is not empty: $TARGET" >&2
  echo "Choose an empty folder so no existing files are overwritten." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ROOT/templates/$STACK/stack.conf"

copy_tree() {
  # copy_tree <source> <dest> [tar exclude args...]
  local src="$1" dest="$2"
  shift 2
  (cd "$src" && tar "$@" -cf - .) | (cd "$dest" && tar -xf -)
}

copy_tree "$ROOT/core" "$TARGET"
copy_tree "$ROOT/templates/$STACK" "$TARGET" --exclude=./stack.conf

export PROJECT_NAME ONE_LINE_DESCRIPTION OWNER_NAME STACK_LABEL QUALITY_GATE

while IFS= read -r -d '' file; do
  perl -pi -e '
    s/\{\{PROJECT_NAME\}\}/$ENV{PROJECT_NAME}/g;
    s/\{\{ONE_LINE_DESCRIPTION\}\}/$ENV{ONE_LINE_DESCRIPTION}/g;
    s/\{\{OWNER_NAME\}\}/$ENV{OWNER_NAME}/g;
    s/\{\{STACK_LABEL\}\}/$ENV{STACK_LABEL}/g;
    s/\{\{QUALITY_GATE\}\}/$ENV{QUALITY_GATE}/g;
  ' "$file"
done < <(find "$TARGET" -type f \( -name "*.md" -o -name "*.yml" -o -name "*.yaml" \) -not -path "*/node_modules/*" -not -path "*/.git/*" -print0)

TODAY="$(date +%Y-%m-%d)"
for doc in "$TARGET/docs/PROJECT_PLAN.md" "$TARGET/docs/DECISIONS.md"; do
  [[ -f "$doc" ]] && perl -pi -e "s/YYYY-MM-DD/$TODAY/g" "$doc"
done

echo "Done. Generated $STACK_LABEL project docs for \"$PROJECT_NAME\" in: $TARGET"
echo "Next: open $TARGET/README.md and follow the First steps."
