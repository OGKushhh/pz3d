# STATUS — what's current vs deprecated

> **Last updated:** 2026-09-12 (repo restructure)

## Canonical (current truth)

| What | Where |
|---|---|
| GDD | `docs/GDD.md` (was `GDD_v1.8_unified.md`) |
| Lore | `docs/lore.md` (was `lore_mazar_v1.2.md`) |
| Poly budget | `docs/poly_budget.md` (was `download/poly_budget_v3_path_b.md`) |
| Furniture decision | `docs/furniture_decision.md` (was `download/furniture_merging_decision.md`) |
| Asset count | `docs/asset_count.md` |
| Asset review strategy | `docs/asset_review_strategy.md` |
| Retired v3 extraction | `docs/retired_city_builder_v3_extraction.md` (Phase B reference) |
| Worklog | `worklog.md` (root, append-only) |
| Godot project | `godot_project/` |
| Source assets | `assets/{category}/{src,out,renders}/` |
| Build scripts | `scripts/` (batch_001-012 + helpers) |
| MoGen DSL reference | `mogen-docs/compiled.md` |
| MoGen upstream examples | `mogen-examples/` |
| Asset pipeline docs | `asset-pipeline/` |

## Archived (historical, do not edit)

| What | Where |
|---|---|
| Old GDD versions (v0-v8, 17 files) | `archive/gdd_history/` |
| Old poly budgets (v1, v2, low_end) | `archive/poly_budgets/` |
| Old city lore options | `archive/city_lore_options.md` |
| Frozen reference architecture | `archive/reference_architecture/mazar_city_builder/` |
| Original Python generator | `archive/mazar_city_builder.py` |
| Early-batch lookbook | `archive/lookbook/mogen-lookbook/` |
| Old contact sheets | `archive/contact_sheets/` (recent 2 kept in `download/asset-batches/`) |
| Old screenshots | `archive/screenshots/` (recent 3 kept in `screenshots/`) |

## Gitignored (not in repo)

| What | Why |
|---|---|
| `.env` | Secrets (DATABASE_URL) |
| `upload/` | User-uploaded reference images |
| `tool-results/` | AI tool call artifacts |
| `skills/`, `.claude/` | Skill system internals |
| `*.deb` | System packages (libegl, libosmesa, mesa-vulkan, xvfb) |
| `godot_engine/` | Local Godot binary |
| `godot.zip` | Local Godot archive |
| `backup/` | Local backups |
| `*.pyc`, `__pycache__/` | Python cache |
| `.godot/` | Godot editor cache |
| `*.tmp` | Temp files |

## Naming convention
- Canonical docs in `docs/` have **no version suffix** — there's only one `GDD.md`, period.
- Versions are tracked in git history (and inside the doc's frontmatter if relevant).
- If a doc needs versioning (e.g. GDD goes through major revisions), use git branches or commit messages — don't rename the file.

## How to know if a file is current
1. Check `docs/` — if it's there, it's current.
2. Check `archive/` — if it's there, it's historical.
3. If it's at root or `download/` and not in this STATUS table, it's likely orphaned — check git log + ask before editing.
