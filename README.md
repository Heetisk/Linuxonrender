# 🖥️ Web Linux Terminal with Google Drive Sync

## 📁 Files
```
Dockerfile          — Ubuntu + ttyd + SSH + rclone
start.sh            — Startup: restore from Drive, SSH, sync loop, ttyd
welcome.sh          — Login banner
render.yaml         — Render deployment
docker-compose.yml  — Local testing
README.md           — This file
```

---

## 🔧 Google Drive Setup (one-time)

### Step 1 — Configure rclone locally
Install rclone on your PC: https://rclone.org/downloads/

```bash
rclone config
```
- Choose: `n` (new remote)
- Name: `gdrive`
- Storage type: `drive` (Google Drive)
- Follow OAuth flow in browser
- Finish config

### Step 2 — Get your rclone config as base64
```bash
# On Linux/Mac:
base64 ~/.config/rclone/rclone.conf

# On Windows (PowerShell):
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:APPDATA\rclone\rclone.conf"))
```
Copy the entire base64 output.

### Step 3 — Add to Render environment
- Render Dashboard → your service → **Environment**
- Add variable: `RCLONE_CONFIG_BASE64` = (paste base64 string)
- Redeploy

---

## 💾 How sync works
| Event | What happens |
|---|---|
| **Container starts** | Downloads all files from `gdrive:terminal-home` → `/home/termuser` |
| **Every 5 minutes** | Uploads changes from `/home/termuser` → `gdrive:terminal-home` |
| **Container stops/restarts** | Next startup restores everything from Drive |

Files are stored in a folder called `terminal-home` in your Google Drive root.

---

## 🚀 Deploy to Render
1. Push all files to GitHub
2. Render → New → Blueprint → connect repo
3. Set `SSH_PASSWORD` and `RCLONE_CONFIG_BASE64` in Environment
4. Deploy ✅

## 🧪 Local Testing
```bash
docker-compose up --build
# Web terminal: http://localhost:7681
# SSH: ssh -p 2222 termuser@localhost
```
