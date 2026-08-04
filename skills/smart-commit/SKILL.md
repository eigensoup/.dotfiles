---
name: smart-commit
description: Analyzes git repository status and diffs, runs safety checks, generates conventional commit messages, and stages/commits code changes cleanly. Use when asked to commit changes, draft a commit message, or run a smart commit.
user-invocable: true
disable-model-invocation: false
allowed-tools:
  - Bash(git status *)
  - Bash(git diff *)
  - Bash(git add *)
  - Bash(git commit *)
  - Bash(git log *)
---

# Smart Commit Skill

Use this skill whenever asked to commit code, generate a commit message, or perform a smart git commit.

## Workflow

### Step 1: Inspect Working Tree & Diff
Run the following to understand current changes:
```bash
git status -s
git diff --cached --stat
git diff --stat
```
If no changes are staged, inspect unstaged changes with `git diff` to determine what files should be committed.

### Step 2: Safety & Quality Audit
Before drafting the commit message or staging:
1. **Secret & Key Check**: Ensure no API keys, private keys (`.pem`, `.key`), `.env` secrets, or tokens are staged.
2. **Artifact Check**: Ensure no temporary build artifacts, log files, or node_modules are included.
3. **Atomic Grouping**: If changes cover multiple unrelated features or fixes, break them into separate logical commits.

### Step 3: Conventional Commit Formatting
Structure the commit message according to Conventional Commits:

```
<type>(<scope>): <short description in imperative mood>

[optional body explaining 'why' and 'what', not 'how']

[optional footer(s), e.g., Closes #123]
```

#### Types:
- `feat`: A new feature
- `fix`: A bug fix
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `docs`: Documentation only changes
- `style`: Formatting, whitespace, or missing semicolons
- `test`: Adding or correcting tests
- `chore`: Build tasks, package dependencies, or tool configurations
- `perf`: Performance improvements
- `ci`: CI/CD workflow updates

### Step 4: Execute Commit
1. Stage the appropriate files using `git add <files>` (avoid `git add .` if untracked junk exists).
2. Commit with the generated message:
   ```bash
   git commit -m "<type>(<scope>): <description>"
   ```
3. Report the result clearly to the user, including the commit hash and summary of committed files.
