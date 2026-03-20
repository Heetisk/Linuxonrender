# 🖥️ Web Linux Terminal

A Linux terminal (Ubuntu 22.04) accessible in the browser, powered by **ttyd** and deployed on **Render**.

---

## 📁 Project Structure

```
linux-terminal/
├── Dockerfile          # Ubuntu + ttyd setup
├── welcome.sh          # Login banner script
├── docker-compose.yml  # For local testing
├── render.yaml         # Render deployment config
└── README.md
```

---

## 🚀 Deploy to Render

### Option A — One-click via render.yaml
1. Push this folder to a GitHub repo
2. Go to [render.com](https://render.com) → **New** → **Blueprint**
3. Connect your GitHub repo — Render auto-detects `render.yaml`
4. Click **Deploy** ✅

### Option B — Manual
1. Push to GitHub
2. Go to Render → **New** → **Web Service**
3. Connect your repo
4. Set **Environment** to `Docker`
5. Render auto-sets the `PORT` — no changes needed
6. Click **Create Web Service**

Once deployed, your terminal is live at:
```
https://<your-service-name>.onrender.com
```

---

## 🧪 Run Locally

```bash
# Build and run with Docker Compose
docker-compose up --build

# Then open in browser:
# http://localhost:7681
```

Or with plain Docker:
```bash
docker build -t web-terminal .
docker run -p 7681:7681 -e PORT=7681 web-terminal
```

---

## 🔧 Customization

### Add more tools
Edit the `apt-get install` line in `Dockerfile`:
```dockerfile
RUN apt-get update && apt-get install -y \
    ttyd bash curl wget git vim nano htop \
    python3 python3-pip \
    nodejs npm \        # ← add more here
    ...
```

### Add password protection
Add `-c username:password` to the ttyd CMD in Dockerfile:
```dockerfile
CMD ttyd --port ${PORT:-7681} \
         --credential admin:yourpassword \
         --writable bash --login
```

### Persist data between sessions
Mount a volume in docker-compose.yml:
```yaml
volumes:
  - ./data:/home/termuser/data
```

---

## ⚠️ Notes

- **Render Free tier** spins down after inactivity — use `starter` plan for always-on
- **No persistence** by default — files are lost on restart unless you add a volume/disk
- ttyd is **single-session** by default; multiple users share the same shell
- Add `--max-clients 1` to ttyd flags to limit to one user at a time
