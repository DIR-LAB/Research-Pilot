# Research Copilot

<p align="center">
  <a href="https://github.com/DIR-LAB/Research-Pilot/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/DIR-LAB/Research-Pilot?style=for-the-badge&color=14B8A6&labelColor=1f2937&label=LATEST"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/LICENSE-MIT-14B8A6?style=for-the-badge&labelColor=1f2937"></a>
  <img alt="Platforms" src="https://img.shields.io/badge/PLATFORMS-macOS_%7C_Windows_%7C_Linux-7c3aed?style=for-the-badge&labelColor=1f2937">
</p>

An AI-powered desktop research assistant for scientists and academics — literature search, data analysis, academic writing, cross-project paper memory, and project management.

**Website:** https://dir-lab.github.io/Research-Pilot/
**Downloads:** https://github.com/DIR-LAB/Research-Pilot/releases/latest

> This repository hosts the **public website** and **release binaries** of Research Copilot.
> The application source code is maintained privately; only built artifacts are published here.

## Install

### macOS (signed & notarized)

```bash
curl -fsSL https://raw.githubusercontent.com/DIR-LAB/Research-Pilot/main/install.sh | bash
```

Or download the `.dmg` from the [latest release](https://github.com/DIR-LAB/Research-Pilot/releases/latest) (Apple Silicon and Intel builds available).

### Windows (unsigned — SmartScreen warning expected)

```powershell
irm https://raw.githubusercontent.com/DIR-LAB/Research-Pilot/main/install.ps1 | iex
```

Or download the `.exe` installer from the [latest release](https://github.com/DIR-LAB/Research-Pilot/releases/latest). On first launch, click "More info" → "Run anyway".

### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/DIR-LAB/Research-Pilot/main/install.sh | bash
```

Or download the `.AppImage` / `.deb` from the [latest release](https://github.com/DIR-LAB/Research-Pilot/releases/latest). AppImage requires `libfuse2` on Ubuntu 22.04+.

## Auto-updates

Research Copilot checks this repository for new releases on startup and every 4 hours. When a new version finishes downloading, an `Update ready · Restart` indicator appears in the status bar — one click and the app relaunches into the new build.

## Support

- **Issues / bug reports:** [GitHub Issues](https://github.com/DIR-LAB/Research-Pilot/issues)
- **License:** [MIT](LICENSE)
