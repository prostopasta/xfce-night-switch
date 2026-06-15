Analyze the changes in the current branch and generate a focused manual test plan for xfce-night-switch.

Steps:
1. Run `git log main..HEAD --oneline` to list commits
2. Run `git diff main...HEAD --stat` to see which files changed
3. Run `git diff main...HEAD -- scripts/ packaging/ systemd/` to read the actual diffs

Based on the changes, generate:
- **Standard checks** always included (panel visible, toggle works, settings opens)
- **Change-specific checks** derived from what was modified:
  - `install-panel-launcher.sh` changed → test panel switching, panel restart behavior
  - `auto-update.sh` changed → test update flow (delete stamp, trigger service)
  - `auto-theme.sh` / `toggle-theme.sh` changed → test theme switching, icon updates
  - `theme-settings.sh` changed → test settings dialog options
  - systemd service files changed → test service start/stop, journalctl output
  - config path changes → test migration from old path

Output format — a markdown checklist:
```
## Test plan for PR #N

### Always verify
- [ ] Panel icon visible after `xfce-night-switch-setup`
- [ ] Left-click toggles day ↔ night theme
- [ ] Arrow → opens Theme Settings dialog
- [ ] `journalctl --user -u xfce-night-switch-startup.service` shows no errors

### This PR specifically
- [ ] <specific item from diff 1>
- [ ] <specific item from diff 2>
```

Then check if there is an open PR for the current branch (`gh pr list --head $(git branch --show-current)`).
If a PR exists, offer to post the test plan as a PR comment with:
`gh pr comment <PR_NUMBER> --body '<test plan>'`
