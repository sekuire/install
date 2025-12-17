# Sekuire CLI Installer

Official installation scripts for the Sekuire CLI.

## Usage

### macOS / Linux

```bash
curl -fsSL https://install.sekuire.com | sh
```

This will:
- Detect your platform and architecture
- Download the latest Sekuire CLI binary
- Verify the download with SHA256 checksum
- Install to `~/.sekuire/bin/`
- Add to your PATH automatically

### Windows

```powershell
irm https://install.sekuire.com/windows | iex
```

This will:
- Detect your architecture
- Download the latest Sekuire CLI binary
- Verify the download with SHA256 checksum
- Install to `%USERPROFILE%\.sekuire\bin\`
- Add to your PATH automatically

## Custom Installation Directory

Set `SEKUIRE_INSTALL_DIR` to install to a custom location:

**Unix:**
```bash
export SEKUIRE_INSTALL_DIR=/usr/local/bin
curl -fsSL https://install.sekuire.com | sh
```

**Windows:**
```powershell
$env:SEKUIRE_INSTALL_DIR = "C:\tools\sekuire"
irm https://install.sekuire.com/windows | iex
```

## Supported Platforms

- **macOS:** ARM64 (Apple Silicon), x86_64 (Intel)
- **Linux:** x86_64, ARM64
- **Windows:** x86_64

## Security

- All downloads are over HTTPS
- SHA256 checksums are verified automatically
- Scripts are hosted on GitHub Pages
- Source code is available in this repository

## Troubleshooting

### Command not found after installation

Restart your terminal or run:

**bash:**
```bash
source ~/.bashrc
```

**zsh:**
```bash
source ~/.zshrc
```

**Windows:**
Restart PowerShell or your terminal.

### Permission denied (macOS)

If macOS blocks the binary:
```bash
xattr -d com.apple.quarantine ~/.sekuire/bin/sekuire
```

Or allow in **System Preferences → Security & Privacy**.

### Manual Installation

If the installer script fails, you can download binaries directly from:
https://github.com/sekuire/releases/releases/latest

## Uninstall

**Unix:**
```bash
rm -rf ~/.sekuire
# Remove the PATH entry from your shell RC file
```

**Windows:**
```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.sekuire"
# Remove from PATH in Environment Variables
```

## Contributing

Issues and pull requests welcome at:
https://github.com/sekuire/install

## License

MIT License - see LICENSE file for details.
