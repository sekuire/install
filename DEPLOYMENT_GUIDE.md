# Deployment Guide for CLI Installation Improvements

## Quick Start

Follow these steps in order to deploy all the installation improvements.

---

## Step 1: Deploy to `sekuire/install` Repository

```bash
# Clone the install repository (if you haven't already)
cd /tmp
git clone git@github.com:sekuire/install.git
cd install

# Copy files from staging
cp /Volumes/Work/code/sekuire/.installer-staging/install-repo/* .

# Commit and push
git add .
git commit -m "Add installation scripts

- Add install.sh for Unix (macOS/Linux)
- Add windows PowerShell installer
- Add index.html redirect page
- Add README with usage instructions"
git push origin main
```

**Verify:**
- Visit https://github.com/sekuire/install
- Files should be visible: `install.sh`, `windows`, `index.html`, `README.md`

---

## Step 2: Deploy to `sekuire/homebrew-tap` Repository

```bash
# Clone the homebrew-tap repository (if you haven't already)
cd /tmp
git clone git@github.com:sekuire/homebrew-tap.git
cd homebrew-tap

# Create Formula directory and copy files
mkdir -p Formula
cp /Volumes/Work/code/sekuire/.installer-staging/homebrew-tap/Formula/sekuire.rb Formula/
cp /Volumes/Work/code/sekuire/.installer-staging/homebrew-tap/README.md .

# Commit and push
git add .
git commit -m "Add Homebrew formula for Sekuire CLI

- Add Formula/sekuire.rb with multi-platform support
- Add README with installation instructions
- Formula will be auto-updated by release workflow"
git push origin main
```

**Verify:**
- Visit https://github.com/sekuire/homebrew-tap
- Check that `Formula/sekuire.rb` exists

---

## Step 3: Enable GitHub Pages for Install Repository

1. Go to https://github.com/sekuire/install/settings/pages
2. **Source**: Deploy from a branch
3. **Branch**: `main` (or `master`)
4. **Folder**: `/ (root)`
5. Click **Save**
6. Wait for deployment (usually 1-2 minutes)

**Verify:**
```bash
# Test that GitHub Pages is serving the files
curl -I https://sekuire.github.io/install/install.sh
# Should return 200 OK
```

---

## Step 4: Configure DNS

Add a CNAME record in your DNS provider (e.g., Cloudflare, Namecheap, etc.):

```
Type: CNAME
Name: install
Value: sekuire.github.io
TTL: 3600 (or Auto)
```

**For Cloudflare:**
1. Go to DNS → Records
2. Click **Add record**
3. Type: `CNAME`
4. Name: `install`
5. Target: `sekuire.github.io`
6. Proxy status: DNS only (gray cloud)
7. Click **Save**

**Verify (after DNS propagates):**
```bash
# Check DNS resolution
dig install.sekuire.com
# Should show CNAME to sekuire.github.io

# Test HTTPS
curl -I https://install.sekuire.com
# Should return 200 OK (may take 24-48 hours for DNS to propagate)
```

---

## Step 5: Configure GitHub Pages Custom Domain

After DNS is configured:

1. Go back to https://github.com/sekuire/install/settings/pages
2. Under **Custom domain**, enter: `install.sekuire.com`
3. Click **Save**
4. Wait for DNS check to complete
5. Enable **Enforce HTTPS** (appears after DNS check passes)

**Verify:**
```bash
curl -I https://install.sekuire.com/install.sh
# Should return 200 OK and redirect to HTTPS
```

---

## Step 6: Add GitHub Secrets to Main Repository

### Create Personal Access Tokens

1. Go to https://github.com/settings/tokens
2. Click **Generate new token (classic)**
3. Name: `Sekuire Install Repo Access`
4. Scopes: Check `repo` (full control of private repositories)
5. Click **Generate token**
6. **COPY THE TOKEN** (you won't see it again)

Repeat for a second token named `Sekuire Homebrew Tap Access`.

### Add Secrets to Repository

1. Go to https://github.com/sekuire/agent/settings/secrets/actions
2. Click **New repository secret**

**Secret 1:**
- Name: `INSTALL_REPO_TOKEN`
- Value: [paste the first token]
- Click **Add secret**

**Secret 2:**
- Name: `HOMEBREW_TAP_TOKEN`
- Value: [paste the second token]
- Click **Add secret**

**Verify:**
- Both secrets should appear in the list
- `RELEASE_REPO_TOKEN` should already exist (verify it's there)

---

## Step 7: Test with a Beta Release

**IMPORTANT:** Do a beta release first to test everything before doing a real release.

1. Go to https://github.com/sekuire/agent/actions/workflows/release-cli.yml
2. Click **Run workflow**
3. Select branch: `master`
4. Version bump type: **beta**
5. Click **Run workflow**

### Watch the Workflow

Monitor the workflow progress:
- ✅ `prepare-release` - Should bump version to something like `0.1.4-beta.1`
- ✅ `build-and-upload` - Should build 4 binaries (Linux, macOS x2, Windows)
- ✅ `create-release` - Should create GitHub release in `sekuire/releases`
- ✅ `update-homebrew` - Should update formula (skipped for beta)
- ✅ `update-install-scripts` - Should commit to install repo
- ✅ `build-linux-packages` - Should build .deb and .rpm (skipped for beta)

**If any job fails:**
- Check the logs
- Common issues:
  - GitHub secrets not set
  - Token doesn't have correct permissions
  - External repos don't exist

---

## Step 8: Verify Beta Release

After the workflow completes successfully:

### Check GitHub Releases
1. Go to https://github.com/sekuire/releases/releases
2. Latest release should be `v0.1.4-beta.1` (or similar)
3. Should have these files:
   - `sekuire-darwin-arm64.tar.gz` + `.sha256`
   - `sekuire-darwin-amd64.tar.gz` + `.sha256`
   - `sekuire-linux-amd64.tar.gz` + `.sha256`
   - `sekuire-windows-x86_64.zip` + `.sha256`

### Test Installers (Optional for Beta)

**Only test if DNS is fully configured (install.sekuire.com working)**

```bash
# macOS/Linux
curl -fsSL https://install.sekuire.com | sh

# Should download and install the beta version
sekuire --version
# Should show v0.1.4-beta.1 (or whatever version was created)
```

---

## Step 9: Create a Real Release

Once beta testing is successful:

1. Go to https://github.com/sekuire/agent/actions/workflows/release-cli.yml
2. Click **Run workflow**
3. Select branch: `master`
4. Version bump type: **patch** (or **minor** if appropriate)
5. Click **Run workflow**

### This Release Will:
- Create version `0.1.4` (removing the beta tag)
- Build all binaries including Windows
- Upload to GitHub Releases
- Build .deb and .rpm packages
- Update Homebrew formula
- Publish to crates.io
- Update install scripts

---

## Step 10: Verify Production Release

### Check All Assets
1. Go to https://github.com/sekuire/releases/releases
2. Latest release should be `v0.1.4`
3. Should have:
   - All 4 binary tarballs/zip
   - All 4 SHA256 files
   - `sekuire_0.1.4_amd64.deb`
   - `sekuire-0.1.4-1.x86_64.rpm`

### Check Homebrew Formula
1. Go to https://github.com/sekuire/homebrew-tap/blob/main/Formula/sekuire.rb
2. Version should be updated to `0.1.4`
3. SHA256 checksums should be updated (not placeholders)
4. Download URLs should point to `v0.1.4`

### Test All Installation Methods

**1. Shell Script (macOS/Linux):**
```bash
curl -fsSL https://install.sekuire.com | sh
sekuire --version  # Should show v0.1.4
```

**2. Homebrew (macOS):**
```bash
brew tap sekuire/tap
brew install sekuire
sekuire --version  # Should show v0.1.4
```

**3. PowerShell (Windows):**
```powershell
irm https://install.sekuire.com/windows | iex
sekuire --version  # Should show v0.1.4
```

**4. Debian Package:**
```bash
curl -LO https://github.com/sekuire/releases/releases/latest/download/sekuire_0.1.4_amd64.deb
sudo dpkg -i sekuire_0.1.4_amd64.deb
sekuire --version
```

**5. RPM Package:**
```bash
curl -LO https://github.com/sekuire/releases/releases/latest/download/sekuire-0.1.4-1.x86_64.rpm
sudo rpm -i sekuire-0.1.4-1.x86_64.rpm
sekuire --version
```

**6. Cargo:**
```bash
cargo install sekuire-agent-cli
sekuire --version
```

---

## Step 11: Announce!

Once everything is verified:

### Update Website
- Add installation section with one-line installers
- Link to full installation guide

### Social Media
- Tweet about new easy installation
- Post on Discord
- Reddit (r/rust, r/programming if appropriate)

### Sample Announcement

```markdown
🎉 Sekuire CLI v0.2.0 - Now Easier to Install!

Installing the Sekuire CLI is now as simple as:

**macOS/Linux:**
curl -fsSL https://install.sekuire.com | sh

**macOS (Homebrew):**
brew install sekuire/tap/sekuire

**Windows:**
irm https://install.sekuire.com/windows | iex

Also available: .deb, .rpm, cargo, and pre-built binaries.

Full guide: https://github.com/sekuire/agent/blob/master/docs/getting-started/installation.md
```

---

## Troubleshooting

### "DNS_PROBE_FINISHED_NXDOMAIN" when accessing install.sekuire.com
- **Issue:** DNS not configured or not propagated
- **Fix:** Check DNS records, wait 24-48 hours for propagation

### "404 Not Found" when accessing install.sekuire.com
- **Issue:** GitHub Pages not enabled or custom domain not configured
- **Fix:** Check GitHub Pages settings in install repo

### Workflow fails with "Resource not accessible by integration"
- **Issue:** GitHub secrets not set or incorrect permissions
- **Fix:** Verify secrets exist and tokens have `repo` scope

### Homebrew formula has "REPLACE_WITH_*_SHA256"
- **Issue:** Workflow didn't update formula (beta release or workflow failed)
- **Fix:** Check workflow logs, ensure non-beta release, verify HOMEBREW_TAP_TOKEN

### .deb or .rpm not in release
- **Issue:** build-linux-packages job failed or was skipped (beta)
- **Fix:** Check workflow logs, ensure non-beta release

---

## Rollback Procedure

If something goes wrong:

### Disable Installers
```bash
# In sekuire/install repo
git revert HEAD
git push
```

### Revert Homebrew Formula
```bash
# In sekuire/homebrew-tap repo
git revert HEAD
git push
```

### Delete Bad Release
1. Go to https://github.com/sekuire/releases/releases
2. Click on the bad release
3. Click **Delete release**

---

## Success Checklist

- [ ] Files uploaded to `sekuire/install`
- [ ] Files uploaded to `sekuire/homebrew-tap`
- [ ] GitHub Pages enabled for install repo
- [ ] Custom domain configured (install.sekuire.com)
- [ ] DNS CNAME record added
- [ ] HTTPS enforced on GitHub Pages
- [ ] GitHub secrets added (INSTALL_REPO_TOKEN, HOMEBREW_TAP_TOKEN)
- [ ] Beta release tested successfully
- [ ] Production release created
- [ ] All assets in GitHub release
- [ ] Homebrew formula updated
- [ ] All installers tested and working
- [ ] Documentation updated
- [ ] Announcement posted

---

## Next Steps

After successful deployment:

1. **Monitor Metrics:**
   - Watch GitHub release download counts
   - Monitor installation-related GitHub issues
   - Track time-to-first-command metrics

2. **Iterate:**
   - Gather user feedback
   - Fix bugs in installers
   - Add more platforms (Chocolatey, winget, etc.)

3. **Future Improvements:**
   - Shell completion scripts
   - ARM64 Linux support
   - Code signing for Windows
   - GPG signing for packages

---

**Need Help?** Check the main INSTALLATION_IMPROVEMENTS_SUMMARY.md or open an issue in the repository.
