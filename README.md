# 📦 Kitly

**One command. Every tool.**

A modern, lightweight package bundle installer for Windows using Winget.  
Install bundles of applications with a single command — like Homebrew for Windows.

Website: [kitly.app](https://kitly.app) · [GitHub](https://github.com/YOUR_USERNAME/kitly) · [Report a Bug](https://github.com/YOUR_USERNAME/kitly/issues)

---

## 🚀 Installation

### One-Command Install (Recommended)

**PowerShell:**
```powershell
iwr https://kitly.app/install.ps1 | iex
```

**CMD:**
```cmd
curl -L https://kitly.app/install.ps1 | powershell
```

This will:
- Download Kitly to `C:\kitly`
- Create a global `kitly` command
- Add it to your PATH automatically

After installation, **restart your terminal** and run:
```
kitly list
```

---

### Manual Install (Fallback)

If you prefer to install manually:

1. **Download** the repository (or clone it):
   ```
   git clone https://github.com/YOUR_USERNAME/kitly.git C:\kitly
   ```

2. **Create the CMD wrapper** — save this as `C:\kitly\kitly.cmd`:
   ```cmd
   @echo off
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0kitly.ps1" %*
   ```

3. **Add to PATH:**
   - Press `Win + R`, type `sysdm.cpl`, hit Enter
   - Go to **Advanced** → **Environment Variables**
   - Under **User variables**, select `Path` → **Edit**
   - Click **New** and add: `C:\kitly`
   - Click **OK** and restart your terminal

4. **Verify:**
   ```
   kitly list
   ```

---

### Execution Policy (if needed)

If PowerShell blocks script execution, run **as Administrator**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 🛠️ Usage

| Command | Description |
|---------|-------------|
| `kitly install <bundle>` | Install all apps in a bundle (or a single winget package) |
| `kitly search <keyword>` | Search the Winget registry |
| `kitly list` | List all available bundles |
| `kitly describe <bundle>` | Show details of a specific bundle |
| `kitly create <name> <app1> <app2> ...` | Create a custom bundle |
| `kitly update <bundle>` | Upgrade all packages in a bundle |
| `kitly generate-docs` | Auto-generate `PACKS.md` documentation |

### Examples

Install the essentials on a fresh Windows machine:
```powershell
kitly install essential
```

Set up a full frontend dev environment:
```powershell
kitly install dev-frontend
```

Create your own bundle:
```powershell
kitly create my-tools Microsoft.VisualStudioCode Git.Git Python.Python.3.11
```

Update everything in a bundle:
```powershell
kitly update dev-backend
```

---

## 📦 Available Bundles

| Bundle | Description | Apps |
|--------|-------------|------|
| `essential` | Bare minimum for a clean Windows install | 7-Zip, Chrome, VLC, Notepad++, Everything, PowerToys |
| `dev-frontend` | Frontend web development | VS Code, Node.js, Git, Chrome, Firefox, Figma, Postman |
| `dev-backend` | Backend & API development | Docker, Python, Git, Postman, DBeaver, AWS CLI |
| `dev-csharp` | .NET & C# development | Visual Studio, .NET SDK, SSMS, Git, Postman |
| `gaming` | Game launchers & comms | Steam, Discord, Epic Games, NVIDIA App, GOG Galaxy |
| `office` | Office & productivity | LibreOffice, SumatraPDF, Zoom, Slack, 7-Zip |
| `media-creator` | Creative tools | OBS, Blender, Audacity, GIMP, Krita |
| `sysadmin` | System administration | PuTTY, WinSCP, WireGuard, Wireshark, Sysinternals |

See [`PACKS.md`](PACKS.md) for the full list with winget IDs.

---

## 🏗️ How It Works

Kitly is a lightweight PowerShell CLI that wraps [Winget](https://github.com/microsoft/winget-cli). Bundles are defined in `packages.json` — a simple JSON file mapping bundle names to arrays of winget package IDs.

```
C:\kitly\
├── kitly.ps1        # Main CLI script
├── kitly.cmd        # CMD/PowerShell wrapper (global command)
├── utils.ps1        # Utility functions & UI helpers
├── packages.json    # Bundle definitions
└── PACKS.md         # Auto-generated docs
```

You can share your `packages.json` with teammates to replicate identical environments.

---

## 🤝 Contributing

Contributions are welcome! Submit issues, suggest new bundles, or open pull requests.

---

## 📄 License

Open source under the [MIT License](LICENSE).