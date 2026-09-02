# Contributing to xfce-night-switch

Thank you for your interest in contributing to **xfce-night-switch**! We welcome contributions of all kinds: bug fixes, new features, translations, documentation improvements, and bug reports.

This project is built to be simple, lightweight, and maintainable. Anyone is welcome to contribute using standard open-source Git workflows with any code editor, terminal, or AI assistant of their choice.

---

## Development Setup

### Prerequisites

For developing and testing locally on Ubuntu / Debian / Mint:

```bash
# Core runtime dependencies
sudo apt install bash yad xfconf gsettings-desktop-schemas python3 python3-dbus curl wget cron

# Optional tools (for icon rendering & monitor dimming)
sudo apt install imagemagick librsvg2-bin x11-xserver-utils ddcutil i2c-tools

# Quality & linting tools
sudo apt install shellcheck
```

### Local Installation from Source

Clone the repository and run the installer locally:

```bash
git clone https://github.com/prostopasta/xfce-night-switch.git
cd xfce-night-switch
bash install.sh
```

`install.sh` detects that it is running from a local git repository and installs files directly from your workspace without downloading packages.

---

## Testing & Quality Gate

We maintain an automated test suite located in `tests/`. All pull requests must pass the test gate before merging.

### Running Tests Locally

Run the complete test suite (syntax validation and functional tests):

```bash
./tests/run-tests.sh
```

### Static Analysis (ShellCheck)

All shell scripts must pass ShellCheck validation:

```bash
shellcheck scripts/*.sh packaging/bin/* install.sh tests/*.sh
```

---

## Conventional Commits & Versioning

This project uses [Conventional Commits](https://www.conventionalcommits.org/) to automate semantic versioning and release packaging:

- `feat:` or `feat(scope):` — Introduces a new feature (triggers a **minor** version bump, e.g. `v1.6.0` → `v1.7.0`).
- `fix:` or `fix(scope):` — Fixes a bug (triggers a **patch** version bump, e.g. `v1.7.0` → `v1.7.1`).
- `docs:` or `docs(scope):` — Documentation changes (does **not** trigger a version bump).
- `test:` or `test(scope):` — Adding or modifying tests (does **not** trigger a version bump).
- `chore:` or `chore(scope):` — Maintenance tasks, CI workflows (does **not** trigger a version bump).
- `BREAKING CHANGE:` in commit footer — Triggers a **major** version bump (e.g. `v1.7.0` → `v2.0.0`).

---

## Pull Request Workflow

1. **Create a branch**:
   ```bash
   git checkout -b feature/my-new-feature
   # or
   git checkout -b fix/my-bug-fix
   ```

2. **Make your changes & run tests**:
   Ensure `./tests/run-tests.sh` passes and ShellCheck is clean.

3. **Open a Pull Request**:
   Push your branch to GitHub and open a PR against the `main` branch.

4. **Automated PR Test Build & Verification**:
   - The CI pipeline automatically builds a test `.deb` package artifact and posts a test checklist comment on the PR.
   - Test the generated `.deb` artifact or verify checklist items.
   - Once verified, commenting `/test-passed` triggers the automated test gate to squash-merge the PR into `main`.

---

## CI Test Plan Generator (Optional Configuration)

The CI test gate includes an automated test plan generator:
- **Default (Static Analysis)**: Generates a checklist based on the files changed in the pull request diff.
- **Enhanced (Optional LLM Integration)**: If a maintainer configures an Anthropic-compatible API endpoint via repository secrets (`ANTHROPIC_API_KEY`, optional `ANTHROPIC_BASE_URL`, `ANTHROPIC_MODEL`), CI will generate a contextual test checklist. This is completely optional and not required for contributing.

---

## Adding Translations

To add a new language or customize UI strings:

1. Copy `locales/en.sh` to `locales/<lang_code>.sh` (e.g. `locales/de.sh` or `locales/fr.sh`).
2. Translate the string variables.
3. Submit a PR with the new locale file!
