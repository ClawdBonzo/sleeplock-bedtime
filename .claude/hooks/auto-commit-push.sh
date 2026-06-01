#!/usr/bin/env bash
# Stop hook: auto-commit + push after each Claude turn.
# No-ops cleanly when there's nothing to do; never blocks the turn; tolerates offline.
set +e
DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$DIR" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
gitdir="$(git rev-parse --git-dir 2>/dev/null)"
# Don't touch the tree mid-merge/rebase/cherry-pick
[ -d "$gitdir/rebase-merge" ] && exit 0
[ -d "$gitdir/rebase-apply" ] && exit 0
[ -f "$gitdir/MERGE_HEAD" ] && exit 0
[ -f "$gitdir/CHERRY_PICK_HEAD" ] && exit 0
# Nothing changed?
[ -z "$(git status --porcelain)" ] && exit 0
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
[ "$branch" = "HEAD" ] && exit 0   # detached HEAD — skip
git add -A >/dev/null 2>&1
git commit -q -m "Auto-commit (Claude Code)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>" >/dev/null 2>&1
git push -q origin "$branch" >/dev/null 2>&1   # best-effort; ignore offline/push failures
exit 0
