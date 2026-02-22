# Git Workflow & Versioning Guide

**Project**: QR Attendance Management System  
**Repository**: [qr_attendance](https://github.com/sas-bergson/qr_attendance)  
**Last Updated**: February 22, 2026

---

## Table of Contents

1. [Branch Management Strategy](#branch-management-strategy)
2. [Semantic Versioning](#semantic-versioning)
3. [Commit Message Convention](#commit-message-convention)
4. [Development Workflow](#development-workflow)
5. [Release Process](#release-process)

---

## Branch Management Strategy

This project follows **Git Flow** branching model with the following structure:

### Main Branches

#### `main` (Production Branch)
- **Purpose**: Production-ready code only
- **Protection**: Should be protected; requires PR review
- **Merges From**: `develop` (for releases), `hotfix/*` (for critical fixes)
- **Tag Convention**: All releases tagged with semantic version (e.g., `v1.0.0`)

#### `develop` (Integration Branch)
- **Purpose**: Pre-release testing and integration
- **Status**: Should always be in a working state
- **Merges From**: `feature/*`, `bugfix/*`, `hotfix/*`
- **Deployment**: Integration/staging environment

### Supporting Branches

#### Feature Branches: `feature/DESCRIPTION`
```bash
# Create from develop
git checkout -b feature/add-jwt-revocation develop

# Example naming
feature/calendar-sync
feature/attendance-report
feature/qr-code-validation
```

**Lifetime**: Delete after merge to develop

#### Bugfix Branches: `bugfix/BUGFIX-XXX-description`
```bash
# Create from develop
git checkout -b bugfix/BUGFIX-007-jwt-revocation develop

# Examples
bugfix/BUGFIX-006-window-function
bugfix/BUGFIX-007-replay-attack-mitigation
```

**Lifetime**: Delete after merge to develop

#### Hotfix Branches: `hotfix/BUGFIX-XXX-description`
```bash
# Create from main (for critical production issues)
git checkout -b hotfix/BUGFIX-008-security-patch main

# IMPORTANT: Must merge back to BOTH main AND develop
git checkout main && git merge hotfix/BUGFIX-008-security-patch
git checkout develop && git merge hotfix/BUGFIX-008-security-patch
git tag -a vX.Y.Z
```

**Lifetime**: Delete after merging to main and develop

---

## Semantic Versioning

This project follows **Semantic Versioning (SemVer)**: `MAJOR.MINOR.PATCH[-PRERELEASE]`

### Version Components

| Component      | Increment When                     | Example                     |
| -------------- | ---------------------------------- | --------------------------- |
| **MAJOR**      | Breaking changes / major features  | `1.0.0` → `2.0.0`           |
| **MINOR**      | New features (backward compatible) | `1.0.0` → `1.1.0`           |
| **PATCH**      | Bug fixes                          | `1.0.0` → `1.0.1`           |
| **PRERELEASE** | Pre-release versions               | `1.0.0-RC1`, `1.0.0-beta.1` |

### Current Project Roadmap

```
v1.0.0-RC1      Release Candidate (current stage)
    ↓
v1.0.0          Full Release (after comprehensive testing)
    ↓
v1.0.1          Bug fixes (BUGFIX-006, other patches)
    ↓
v1.1.0          New features + BUGFIX-007 (JWT revocation)
    ↓
v2.0.0          Major refactoring or architecture changes
```

### Version Update Rules

- **Only bump versions on `main` branch** at release time
- **Tag every release** with Git tags: `git tag -a vX.Y.Z -m "Release notes"`
- **Update version** in all relevant files:
  - `backend/config.py` (or version constant)
  - `frontend/pubspec.yaml` (Flutter)
  - Release notes in repository

---

## Commit Message Convention

This project follows **Conventional Commits** specification for clear, machine-readable commit history.

### Format

```
type(scope): subject

body (optional detailed description)

footer (optional: issue references, breaking changes)
```

### Commit Types

| Type       | Purpose                               | Example                                                   |
| ---------- | ------------------------------------- | --------------------------------------------------------- |
| `feat`     | New feature                           | `feat(auth): add JWT token revocation`                    |
| `fix`      | Bug fix                               | `fix(calendar): resolve PostgreSQL window function error` |
| `refactor` | Code refactoring (no behavior change) | `refactor(routes): extract statistics logic`              |
| `docs`     | Documentation only                    | `docs(api): add endpoint authentication examples`         |
| `test`     | Test additions/improvements           | `test(auth): add token revocation tests`                  |
| `chore`    | Dependencies, config, tooling         | `chore(deps): update pytest to v7.4.4`                    |
| `perf`     | Performance improvements              | `perf(db): optimize event query with indexes`             |
| `ci`       | CI/CD pipeline changes                | `ci(github): add workflow for test suite`                 |

### Scope

Optional but recommended. Specifies what part of the code:
- `auth` - Authentication module
- `routes` - API routes/endpoints
- `database` - Database layer
- `calendar` - Calendar functionality
- `deps` - Dependencies
- `api` - General API changes

### Subject Line

- Use imperative mood: "add" not "added" or "adds"
- Don't capitalize first letter
- No period (.) at the end
- Max 50 characters

### Examples

```bash
# Good examples
git commit -m "feat(auth): add JWT token revocation mechanism"
git commit -m "fix(calendar): replace window functions for PostgreSQL 12 compatibility"
git commit -m "refactor(routes): extract authentication checks to middleware"
git commit -m "docs(README): add JWT security best practices section"

# Good with body
git commit -m "fix(calendar): resolve PostgreSQL 12 window function error

- Replace COUNT(DISTINCT ...) OVER syntax with subquery
- Improves compatibility with PostgreSQL 12
- Fixes 500 error on calendar events endpoint

Fixes: BUGFIX-006"

# Poor examples (avoid)
git commit -m "fixed stuff"
git commit -m "Update code"
git commit -m "WIP: many changes"
```

---

## Development Workflow

### Step 1: Create Feature Branch

```bash
# Update develop branch
git checkout develop
git pull origin develop

# Create feature/bugfix branch
git checkout -b feature/new-feature develop
# or
git checkout -b bugfix/BUGFIX-007-jwt-revocation develop
```

### Step 2: Make Changes & Commit

```bash
# Make your changes...
# Stage changes
git add backend/auth.py backend/routes.py

# Commit with conventional message
git commit -m "feat(auth): add JWT token revocation

- Implement token blacklist mechanism
- Add revocation endpoint to auth module
- Store revoked tokens in Redis cache

Implements: FEATURE-001"

# Multiple related commits are OK
git commit -m "test(auth): add revocation tests"
git commit -m "docs(auth): update authentication documentation"
```

### Step 3: Push to GitHub

```bash
# Push branch (creates if doesn't exist)
git push origin feature/new-feature
# or
git push origin bugfix/BUGFIX-007-jwt-revocation
```

### Step 4: Create Pull Request

1. Go to GitHub repository
2. Click "New Pull Request"
3. Set:
   - **Base**: `develop`
   - **Compare**: `feature/new-feature`
4. Fill PR title and description:
   - Reference issue: "Fixes #123"
   - Describe changes
   - List breaking changes (if any)

### Step 5: Code Review & Merge

```bash
# After PR approval, merge on GitHub (or CLI)
git checkout develop
git pull origin develop
git merge --no-ff feature/new-feature
git push origin develop

# Delete feature branch
git branch -d feature/new-feature
git push origin --delete feature/new-feature
```

---

## Release Process

### When to Release

- When `develop` has accumulated significant features/fixes
- After comprehensive testing
- When ready for production deployment

### Release Steps

#### 1. Create Release Branch (Optional but Recommended)

```bash
git checkout -b release/v1.0.1 develop
# Only version/documentation changes here
```

#### 2. Update Version Numbers

Update version in all relevant files:

```bash
# backend/config.py
VERSION = "1.0.1"

# backend/app.py (in Flasgger config)
"version": "1.0.1"

# frontend/pubspec.yaml
version: 1.0.1
```

#### 3. Update CHANGELOG

Add entry to [CHANGELOG.md](../backend/CHANGELOG.md):

```markdown
## [1.0.1] - 2026-02-22

### Fixed
- BUGFIX-006: PostgreSQL 12 window function compatibility
- BUGFIX-005: Test expectation corrections

### Changed
- Makefile: Use venv Python for test execution

### Security
- JWT token expiration: 1 hour (maintained)

[1.0.1]: https://github.com/sas-bergson/qr_attendance/releases/tag/v1.0.1
```

#### 4. Commit Version Changes

```bash
git commit -m "chore(release): bump version to v1.0.1

Release notes in CHANGELOG.md"
```

#### 5. Merge to Main & Tag

```bash
# Merge release branch to main
git checkout main
git pull origin main
git merge --no-ff release/v1.0.1 -m "Release v1.0.1"

# Create annotated tag
git tag -a v1.0.1 -m "Release v1.0.1: Bug fixes and improvements

- BUGFIX-006: PostgreSQL 12 compatibility
- BUGFIX-005: Test improvements
- Performance: Optimized calendar events endpoint"

# Push everything
git push origin main
git push origin v1.0.1

# Delete release branch
git branch -d release/v1.0.1
git push origin --delete release/v1.0.1
```

#### 6. Merge Back to Develop

```bash
# Ensure develop gets the version bumps
git checkout develop
git merge --no-ff main
git push origin develop
```

#### 7. Create Release on GitHub

1. Go to GitHub → Releases → "Create a release"
2. Choose tag: `v1.0.1`
3. Fill release notes (copy from CHANGELOG.md)
4. Publish release

---

## Hotfix Process (Critical Production Issues)

```bash
# Create hotfix from main (ONLY for critical bugs)
git checkout -b hotfix/BUGFIX-008-security-patch main

# Make fix, commit with conventional message
git commit -m "fix(security): patch JWT replay attack vulnerability

- Add token expiration validation
- Implement token revocation on logout

Security: Critical"

# Merge back to BOTH main and develop
git checkout main
git merge --no-ff hotfix/BUGFIX-008-security-patch
git tag -a v1.0.2 -m "Hotfix v1.0.2: Security patch"
git push origin main v1.0.2

git checkout develop
git merge --no-ff hotfix/BUGFIX-008-security-patch
git push origin develop

# Delete hotfix branch
git branch -d hotfix/BUGFIX-008-security-patch
git push origin --delete hotfix/BUGFIX-008-security-patch
```

---

## Branch Cleanup Strategy

After successfully merging a feature/bugfix branch to `develop` or `main`, branch cleanup is important for maintaining repository hygiene. We recommend a **hybrid approach**: delete local branches but keep remote branches.

### Recommended: Delete Local, Keep Remote

**Why This Approach?**

✅ **Advantages**:
- Keeps remote history intact for GitHub reference
- Prevents accidental re-branching from old local copies
- GitHub UI clearly shows branch as "merged" (gray background)
- Easy recovery if needed—branch still exists on GitHub
- Cleaner local environment (`git branch -a` shows fewer entries)
- Remote branches serve as audit trail
- Easier to search merged branches on GitHub web interface

⚠️ **Trade-offs**:
- Remote "merged" branches must be cleaned up eventually (usually by repo admin)
- `git branch -a` still shows remote merged branches
- Requires discipline to not re-branch from remote

### Implementation

**After Merging to develop** (feature/bugfix branches):

```bash
# Delete LOCAL copy of branch
git branch -d feature/new-feature
# or if merge conflicts happened
git branch -D feature/new-feature

# KEEP remote branch (don't run this)
# git push origin --delete feature/new-feature  ← DO NOT DO THIS

# Verify cleanup
git branch -a  # Local branch gone; remote still visible
```

**After Merging to main** (release/hotfix branches):

```bash
# Same pattern - delete local, keep remote
git branch -d release/v1.0.1
# Keep: git push origin --delete release/v1.0.1

git branch -a  # Verify
```

### Alternative: Complete Cleanup (Delete Both)

If your team prefers maximum cleanliness, delete both local and remote:

```bash
# Delete local
git branch -d feature/new-feature

# Delete remote
git push origin --delete feature/new-feature

# Verify
git branch -a  # Branch completely gone
```

**⚠️ Important**: Only use complete cleanup if your team:
- Has GitHub PR/merge request history to reference merged work
- Never needs to inspect old merged branches
- Prefers minimal branch clutter over historical reference

### GitHub UI Behavior

After merge, GitHub shows:

1. **Remote branch still exists**: Branch appears in GitHub → Branches with gray background
2. **"Merged" indicator**: GitHub clearly marks branches as "merged into develop"
3. **Deletion buttons available**: Can delete from GitHub web UI if needed
4. **PR linkage**: GitHub PR remains visible in PR history

### Recovery If Needed

If you accidentally need to revisit a deleted local branch:

```bash
# Fetch remote branch
git fetch origin feature/new-feature

# Recreate local branch from remote
git checkout -b feature/new-feature origin/feature/new-feature

# OR: Create new branch from commit hash
git checkout -b feature/new-feature abc1234def5678
```

### Best Practice for This Project

**We use: Delete local, keep remote**

```bash
# Standard cleanup after merge
git branch -d feature/new-feature  # ✅ Always do this

# DO NOT run this automatically
# git push origin --delete feature/new-feature  ← Skip this
```

This keeps:
- Local environment clean
- Remote history complete
- Easy recovery path available
- Audit trail on GitHub

---

## Quick Reference

### Common Commands

```bash
# View all branches
git branch -a

# View tags
git tag -l

# View commit history
git log --oneline --graph --all

# Show current branch status
git status

# Fetch latest from remote
git fetch origin

# Sync develop branch
git checkout develop && git pull origin develop

# Delete local branch
git branch -d branch-name

# Delete remote branch
git push origin --delete branch-name

# Undo last commit (keep changes)
git reset --soft HEAD~1

# View commit details
git show v1.0.1
```

### Emergency Rollback

```bash
# Rollback to previous release
git checkout main
git reset --hard v1.0.0
git push origin main --force  # Only if absolutely necessary!

# Alert: Force push is dangerous, use only in emergencies
```

---

## Best Practices Summary

✅ **DO**:
- Always create feature branches from `develop`
- Write descriptive commit messages
- Test code before pushing
- Use conventional commit format
- Tag releases with semantic versions
- Keep `main` branch in production-ready state
- Review PRs before merging
- Keep branch history clean

❌ **DON'T**:
- Commit directly to `main` or `develop`
- Use vague commit messages ("fixed stuff")
- Push untested code
- Mix multiple features in one commit
- Force push to shared branches
- Leave stale branches
- Bump versions on non-main branches

---

## References

- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Flow Cheatsheet](https://danielkummer.github.io/git-flow-cheatsheet/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)

---

**Questions?** Refer to this guide or check the project's DEVELOPMENT_LOG.md for recent decisions.
