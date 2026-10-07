# Recovery, migration and upgrades

Start with Status. Preserve the current portal index, manager CSS, state and transaction directories before manual recovery. Do not copy an older full product index over a newer RAS installation. Do not modify compiled bundles or RAS Theme assets.

## Paths

Target: `%ProgramData%\RASInsider\RAS-UserPortal-SkinManager\state.json`, `active-transaction.json`, `transactions\<id>\manifest.json`, and `Index/Css/State.before` / `.after` snapshots when those files existed. Coordinator: the project's `coordinator\<id>.json` and `events.jsonl`. Coordinator journals contain target identities and desired content; keep them private and out of GitHub. They are not reusable public configuration examples.

Locks intentionally survive crashes. A second operation must not remove them blindly. Successful commit verification or verified rollback is required before lock finalization.

## Failed pre-flight

No live portal files were changed. Isolated probes/state directories may have been created. Resolve WinRM access, elevation, product path, build, encoding, free space, prototype conflict or API identity and retry the full scope. Do not exclude a failed HALB node just to get a green result.

## Interrupted deployment or failed commit

Use the reported coordinator transaction ID on the original administration machine:

```powershell
.\RAS-UserPortal-SkinManager.ps1 -Action Status -LicensingServer ras-license.example.test `
  -RecoverTransaction 0123456789abcdef0123456789abcdef
```

This parameter takes precedence over normal Status behavior and performs a **confirmed recovery mutation**, not a read-only status request. It rediscovers targets through RAS and requires exact identity matches. Preparing/committing/recovery-required transactions roll back immediate snapshots. Fully verified/finalization-required transactions verify desired hashes and finish lock release. Use `-WhatIf` to preview; do not edit journal phase to force a desired outcome.

The command needs existing WinRM administration access to every journal target. If a node is unreachable, keep the journal and its lock, restore connectivity and retry. Already recovered nodes are checked against their baseline, not rewritten blindly. The tool reports incomplete recovery as failure.

If a remote response is lost, the coordinator includes the attempted node in rollback evaluation. If a snapshot/manifest is missing or current file hashes match neither before nor after, automatic rollback refuses and requires surgical recovery. Do not clear a lock while any target remains ambiguous.

## Concurrent upgrade or manual edits

Rollback validates all affected current files before modifying any on that target. If another change/upgrade intervened, restore by removing only the recognized manager link block from the current index. Keep unrelated tags and the current product's bundled paths. Archive unexpected CSS, reconcile its ownership, and remove only known manager files. Do not replace the current index with `Index.before` unless you have independently proved it is the correct immediate product version and no other edits will be lost.

## Existing prototype migration

The recorded working prototype may have an **unmarked** link to `/userportal/rasinsider.css`. The manager deliberately refuses that ambiguity.

1. Archive the current index and independent prototype CSS in a private backup location, recording hashes and build. Inspect that no other files implement styling.
2. On all relevant lab Gateways, identify the exact prototype stylesheet link. Replace that link in place with the recognized BEGIN/END block and its link only, preserving product tags/encoding. If the prototype includes independent inline CSS, archive it and reconcile it separately; the manager will not broadly remove inline styles.
3. Review your physical mapping. Run Install with `-AdoptPrototype -MappingValidated` and the desired preset across the full pool. A marked/no-state CSS collision is snapshot-backed and explicitly adopted. Adoption is not an instruction to delete unknown HTML.
4. Verify styling/Theme behavior and retain prototype snapshots. A successful transaction rollback restores the immediate adopted files.

If state is lost but the hook/CSS remains, preserve files and use reviewed adoption. Corrupt/mismatched state is refused; reconcile its identity/config against backups before moving it aside manually. Do not fabricate state hashes to hide drift.

## Clean restore

`-Action Restore` detaches only the recognized hook from the **current** index, then removes owned CSS and records Installed=false. It leaves product updates/branding intact. Repeated restore is a no-op. Unknown unowned CSS requires migration; it is not deleted simply because its filename matches.

## Upgrade re-apply

Redetect Farm topology and build. A lost hook with retained valid state can be repaired from the saved skin against the new current index. CSS/index drift requires review and `-AcceptDrift` where appropriate. New/unverified builds require explicit `-AllowUnverifiedBuild` lab opt-in; that does not create a compatibility claim. No product upgrade is performed by this tool.

Confirm the target set, full HALB pool, new path/URL mapping and saved configuration before re-apply. Newly discovered Gateways are not silently added to previous IDs; explicit scope is required each run. A new Gateway with no state cannot Re-apply: install on the chosen scope.

## Manual surgical removal checklist

Identify the current physical index and archive it. Remove only one recognized manager marker block; unexpected content inside it must be preserved/reconciled. Verify no manager link remains, remove/archive only the known independent manager stylesheet, and test the current RAS portal directly on every relevant Gateway. Reconcile state and any pending transactions only after confirming the outcome. Keep records for unreachable nodes; a mixed farm is not healthy.
