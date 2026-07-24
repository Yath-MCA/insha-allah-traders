# Phase 9 — Security, Audit, Testing, Backup & Production Deployment

**Goal:** Harden the app for production: security review, audit completeness, tests, deployment docs, and backup/recovery runbooks.

## Prerequisites

- Phases 1–8 feature-complete enough to operate the business day-to-day.
- Existing RLS, audit triggers, Storage policies from Phase 1 migrations.

## In scope

### Security

- Confirm no service-role key in client bundle or committed env files
- Review RLS policies for gaps (anon blocked; company isolation; Viewer read-only; issued invoice immutability)
- Storage path policies per company
- Zod validation on all remaining forms; sanitize display of user content
- Auth redirect URLs documented for production domain
- Edge Functions only where privileged ops still need service role (numbering should stay in DB)

### Audit

- Verify financial + master mutations write `audit_logs`
- UI filters: user, table, action, date range
- Ensure cancel/issue/payment paths are audited

### Testing

- Critical path smoke tests (Playwright or Vitest + Testing Library): login, customer create, invoice draft, permission deny for Viewer
- Document how to run tests in root README

### Deployment

- Production build (`npm run build`) + static host guidance (Vercel/Netlify/Cloudflare Pages) or any static host
- Supabase production project: migrations `db push`, seed caution (no re-seed on prod blindly)
- Env vars checklist
- Optional CI: typecheck + build on PR

### Backup & recovery

- Expand runbook: `pg_dump` / restore, Supabase dashboard backups, Storage backup notes
- Pre-migration backup checklist
- Point-in-time recovery notes (plan-dependent)

### Documentation

- Finalize root README: full install, migrate, seed, env, local, prod deploy, backup
- Keep `docs/phase-prompts/` as historical build order
- Operator notes: FY close, GST rate updates, Super Admin bootstrap

## Out of scope

- New business modules
- GST portal API integration (explicitly not claimed)

## Tables / systems involved

- All — focus on policies, `audit_logs`, Auth, Storage, CI config files

## Routes / deliverables

- No major new routes required; polish existing
- Add `docs/DEPLOYMENT.md` and `docs/BACKUP.md` if README would become too long
- Update root README with Production + Backup sections (may already exist — expand)

## Components / work areas

```
docs/DEPLOYMENT.md          # optional
docs/BACKUP.md              # optional
e2e/ or src/**/*.test.ts    # smoke tests
.github/workflows/ci.yml    # optional CI
README.md                   # finalize
```

## Acceptance criteria

- [ ] Security checklist completed and documented
- [ ] Audit log coverage verified for financial actions
- [ ] At least minimal automated smoke tests pass
- [ ] Deployment + backup instructions in repo
- [ ] `npm run build` succeeds
- [ ] Disclaimer retained: not a CA / tax filing substitute

**This is the final phase. After completion, treat further work as iterative product enhancements.**
