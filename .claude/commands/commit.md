---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git commit:*)
description: Stage and commit changes with a well-crafted commit message
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status`
- Staged changes: !`git diff --cached`
- Unstaged changes: !`git diff`
- Recent commits (for style reference): !`git log --oneline -5`

## Instructions

Based on the changes above, create a git commit following these guidelines:

1. **Analyze** all staged and unstaged changes
2. **Stage** relevant files (use `git add` for untracked/modified files that should be committed)
3. **Draft** a commit message that:
   - Summarizes the nature of changes (feature, fix, refactor, docs, test, chore)
   - Focuses on the "why" rather than the "what"
   - Is concise (1-2 sentences max)
   - Matches the style of recent commits in this repo
4. **Commit** using a HEREDOC format:
   ```bash
   git commit -m "$(cat <<'EOF'
   Your commit message here

   Co-Authored-By: Claude <noreply@anthropic.com>
   EOF
   )"
   ```

**Important:**
- Do NOT commit files that may contain secrets (.env, credentials, API keys)
- Do NOT push to remote unless explicitly asked
- If there are no changes to commit, inform the user
