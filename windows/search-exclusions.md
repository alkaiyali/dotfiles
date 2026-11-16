# Windows Search exclusions (repos)

Rule: one parent folder, never one-by-one.

- `C:\Users\Wayne\repos` → exclude the **whole folder**. Excluding
  individual repos (`repos\setup`, …) rots: every new clone gets indexed
  until someone remembers to exclude it.
- Repos worked on from WSL → move into the Linux filesystem
  (`~/projects`). Windows Search cannot index the WSL2 ext4 disk, and
  `/mnt/c` file access is slow for git/npm.
- Anything that must stay on the Windows side → single folder `C:\dev`,
  exclude that one folder.

Classic vs Enhanced: Classic indexes only libraries (Documents, Pictures,
Music) + Desktop, so a `C:\dev` outside those is never indexed and needs no
exclusion. Enhanced indexes the whole PC, so the exclusion is required.
Observed 2026-11-16: this machine's crawl scope has `Include=1` on `Users\`
(Enhanced-like) with only a stale per-repo exclusion for
`Users\Wayne\repos\setup\` — a folder that no longer exists — so all ~23
repos were being indexed.

## Exclude (UI, ~30s)

1. Open Indexing Options (`control.exe /name Microsoft.IndexingOptions`) →
   Modify — or Settings → Privacy & security → Searching Windows →
   Add an excluded folder.
2. Add `C:\Users\Wayne\repos` (the whole folder).
3. Remove stale per-repo exclusions (e.g. `repos\setup`).

## Verify (human or agent, read-only, no admin)

```powershell
$base = 'HKLM:\SOFTWARE\Microsoft\Windows Search\CrawlScopeManager\Windows\SystemIndex\WorkingSetRules'
Get-ChildItem $base | ForEach-Object {
  $p = $_.PSPath
  "$((Get-ItemProperty -Path $p -Name Include -ErrorAction SilentlyContinue).Include)`t$((Get-ItemProperty -Path $p -Name URL -ErrorAction SilentlyContinue).URL)"
} | Sort-Object
```

Expect `0` (excluded) on `...\Users\Wayne\repos\` and no per-repo entries.

## Why a note, not a script

Win11 has no registered SearchManager COM API for scope changes, and
hand-editing the crawl-scope keys (volume-GUID URLs, binary ACLs,
EvaluationOrder counters, HKLM = elevation) is fragile. UI + verify above
is the reliable path.
