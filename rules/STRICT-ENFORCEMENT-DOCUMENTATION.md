# Documentation-Specific Critical Errors

Documentation-specific critical errors in the points-based enforcement system.

**These documentation errors are ABSOLUTELY FORBIDDEN and result in massive point loss (-500 points each):**

1. **README Template Violations** (-500 points)
   - Repository README is missing or diverges from the mandated GitHub template (title, Scenario, How to run, and Access lines exactly as specified)
   - Adding extra sections, changing wording, or omitting commands/Access details
   - **CORRECT**: Copy the official template, only swap in the lab's slug/title, and keep the length identical

2. **Metadata Description Length/Format Issues** (-500 points)
   - `.ctf/metadata.json` contains a description longer than two short sentences or >320 characters
   - Description fails to mention the vulnerability objective succinctly
   - **CORRECT**: Summarize the exploit goal in 1–2 concise sentences per the metadata rule

3. **Evidence Value Not Exact Artifact** (-500 points)
   - `dev_evidence` or `.ctf/EVIDENCE.md` stores explanatory sentences, prefixes, or combined values instead of the precise evidence string
   - Tests cannot assert the exact credential/token because extra prose is included
   - **CORRECT**: Store only the bare artifact (e.g., the password itself) with no surrounding text, matching the declared `evidence_kind`
