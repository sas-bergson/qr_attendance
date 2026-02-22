# Versioning Strategy & Release Plan

**Document**: Versioning & Release Planning  
**Date Created**: February 22, 2026  
**Decision Owner**: Team  
**Status**: Active

---

## Executive Summary

This document records the versioning strategy decision made on **February 22, 2026** and the planned path to v1.0.0 release.

**Current Version**: `v1.0.0-dev`  
**Target Release**: `v1.0.0` (To be scheduled)  
**Strategy**: Continued development → Release procedures → RC testing → v1.0.0

---

## Decision Context

### Question Asked
"Should we tag v1.0.0-RC1 (Release Candidate) now?"

### Analysis Performed
**Advantages of Immediate RC1 Tagging:**
- Marks a stable baseline for focused testing
- Enables parallel development from known point
- Demonstrates versioning discipline
- Clarifies issue tracking

**Disadvantages of Immediate RC1 Tagging:**
- RC implies "release-ready" — misleading signal without deployment readiness
- No formal testing phase or UAT plan in place
- No deployment procedures documented
- No rollback strategy defined
- RC phase most valuable in team environments, less so for solo development
- Unclear graduation criteria (RC1 → RC2 → 1.0.0)

### Best Practice Assessment

**Industry Standard for RC Tagging:**
- Code complete (features frozen) ✅
- Tests passing (56/56) ✅
- **Formal testing plan** ❌
- **Deployment procedure documented** ❌
- **Rollback procedure documented** ❌
- **Monitoring/alerting strategy** ❌
- **Release communication plan** ❌

**Current Status**: 2/7 prerequisites met (29%)

---

## Decision: Better Path Forward

### Chosen Strategy

**Continue development on `develop` branch** without immediate RC1 tagging.

### Implementation Plan

#### Phase 1: Active Development (Current)
- **Version in config**: `v1.0.0-dev`
- **Branch**: `develop` with `feature/*` branches
- **Activities**:
  - Add JWT revocation feature
  - Implement rate limiting
  - Add user roles & permissions enhancements
  - Continue bug fixes as needed
- **Duration**: Until release DATE is determined

#### Phase 2: Release Planning (When Release Date Identified)
- **Activities**:
  - Create `DEPLOYMENT_PROCEDURES.md`
  - Create `TESTING_CHECKLIST.md`
  - Create `MONITORING_STRATEGY.md`
  - Create `ROLLBACK_PROCEDURE.md`
  - Define staging environment
  - Plan release communication

#### Phase 3: Release Branch
- **Create**: `release/v1.0.0` branch from `develop`
- **Version bump**: Update all version references
- **Update**: CHANGELOG.md with release notes
- **Only changes**: Documentation and version bumps (no features)

#### Phase 4: Release Candidate Testing
- **Tag**: `v1.0.0-RC1` on `release/v1.0.0`
- **Activities**:
  - Execute formal testing checklist
  - Deploy to staging environment
  - Monitor logs and metrics
  - Document findings
  - Create issues for bugs found
- **Exit criteria**:
  - If < 5 critical bugs: Proceed to RC2 or v1.0.0
  - If >= 5 critical bugs: Return to develop, fix, create new release branch

#### Phase 5: Release v1.0.0
- **Merge**: `release/v1.0.0` → `main`
- **Tag**: `v1.0.0` on `main`
- **Deploy**: To production
- **Communicate**: Release announcement
- **Monitor**: Production metrics

#### Phase 6: Ongoing Development
- **Merge**: `main` → `develop` to sync
- **Bump version**: To `v1.0.1-dev` or `v1.1.0-dev`
- **Continue**: Feature development

---

## Version Numbering: Semantic Versioning

### Format: `MAJOR.MINOR.PATCH[-PRERELEASE]`

| Version | Type | When Used | Examples |
|---------|------|-----------|----------|
| `1.0.0-dev` | Development | Active feature development | Current |
| `1.0.0-RC1` | Release Candidate | Dedicated testing phase | Before release |
| `1.0.0-RC2` | Release Candidate 2 | If issues found in RC1 | If needed |
| `1.0.0` | Release | Production ready | After RC testing passes |
| `1.0.1` | Patch | Bug fixes only | Post-release hotfixes |
| `1.1.0` | Minor | New features, backward compatible | Next iteration |
| `2.0.0` | Major | Breaking changes | Future major redesign |

### Version Update Locations

Update these files when bumping version:

1. `backend/config.py` or version constant
2. `frontend/pubspec.yaml` (Flutter version)
3. `app.py` Swagger configuration
4. `CHANGELOG.md` (only for releases)
5. Git tags (only for releases)
6. GitHub Releases (only for releases)

---

## Rationale: Why This Strategy?

### Why Not Immediate RC1?
1. **RC signals stability** without deployment readiness
2. **Unclear decision criteria** for RC → 1.0.0 transition
3. **No testing phase** defined
4. **Better for team environments** — less value in solo development

### Why This Path Instead?
1. **Honest versioning** — `-dev` clearly signals work-in-progress
2. **Continued innovation** — Add features and improvements
3. **Proper release readiness** — Build procedures before RC tag
4. **Professional release** — When RC1 is tagged, it's meaningful
5. **Scalable approach** — Works for solo or team development

---

## Roadmap: Path to v1.0.0

```
NOW (Feb 22, 2026)
    ↓
v1.0.0-dev — Active Development
    • JWT revocation
    • Rate limiting  
    • Permission enhancements
    • Bug fixes
    (Duration: TBD — when release date set)
    ↓
Release Planning Phase
    • Create deployment procedures
    • Create testing checklist
    • Create monitoring strategy
    • Create rollback plan
    (Duration: 1 week estimated)
    ↓
v1.0.0 Release Branch
    • Freeze features
    • Version bumps only
    • CHANGELOG updates
    (Duration: < 1 week)
    ↓
v1.0.0-RC1 Testing
    • Execute formal tests
    • Deploy to staging
    • Monitor metrics
    • Document findings
    (Duration: 2-4 weeks)
    ↓
v1.0.0 Release
    • Merge to main
    • Tag v1.0.0
    • Deploy to production
    • Release announcement
    ↓
Post-Release
    • Monitor production
    • Fix hotfixes if needed (v1.0.1)
    • Plan v1.1.0 features
```

---

## Commitment & Next Steps

### Immediate Actions
1. ✅ Document this decision (this file)
2. ✅ Update README.md with project status
3. ✅ Continue development on `develop` with `feature/*` branches
4. ⏳ When release date identified: Begin release planning phase

### Team Communication
- Share this document with team
- Review quarterly or when strategy changes
- Update if approach needs adjustment

---

## References

- [GIT_WORKFLOW.md](./GIT_WORKFLOW.md) — Branching & commit conventions
- [CHANGELOG.md](./backend/CHANGELOG.md) — Version history
- [DEVELOPMENT_LOG.md](./backend/DEVELOPMENT_LOG.md) — Session notes
- [Semantic Versioning](https://semver.org/)

---

**Document Version**: 1.0  
**Last Updated**: February 22, 2026  
**Next Review**: When release planning phase begins
