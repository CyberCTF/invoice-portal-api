# Gate UI: Black-only

Review gate: black-only UI checklist.

- [ ] `<html class="theme-dark">` present on all pages
- [ ] Global stylesheet loaded before other styles
- [ ] No hard-coded colors found (grep: `#([0-9a-fA-F]{3,8})|rgb\(|hsl\(|linear-gradient`)
- [ ] All backgrounds/text/borders use tokens `var(--*)`
- [ ] Links/buttons use `--accent` / `--accent-fg`
- [ ] Contrast OK (bg vs fg ≥ WCAG AA simplified)
- [ ] No library forcing white backgrounds without override
