#!/bin/bash
set -e

# ── 1. Set SSH password ──────────────────────────────────────────────
PASSWORD="${SSH_PASSWORD:-changeme123}"
echo "termuser:${PASSWORD}" | chpasswd
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SSH username : termuser"
echo "  SSH password : ${PASSWORD}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 2. Setup rclone config from env var ──────────────────────────────
if [ -n "$RCLONE_CONFIG_BASE64" ]; then
    mkdir -p /home/termuser/.config/rclone
    echo "$RCLONE_CONFIG_BASE64" | base64 -d > /home/termuser/.config/rclone/rclone.conf
    chown -R termuser:termuser /home/termuser/.config
    echo "✔ rclone config loaded"

    # ── 3. Restore config files only (skip .local) ───────────────────
    echo "⟳ Restoring config from Google Drive..."
    sudo -u termuser rclone sync gdrive:terminal-home /home/termuser \
        --exclude ".config/**" \
        --exclude ".local/**" \
        --drive-acknowledge-abuse \
        --log-level INFO 2>&1 || echo "⚠ Restore failed or first run — starting fresh"
    echo "✔ Restore complete"

    # ── 4. Install OpenClaw from zip ─────────────────────────────────
    OPENCLAW_MJS="/home/termuser/.local/lib/node_modules/openclaw/openclaw.mjs"
    OPENCLAW_BIN="/home/termuser/.local/bin/openclaw"
    OPENCLAW_READY="/home/termuser/.local/lib/node_modules/openclaw/.install-complete"

    if [ ! -f "$OPENCLAW_READY" ]; then
        echo "⟳ Installing OpenClaw from zip..."
        # Clean any partial install first
        rm -rf /home/termuser/.local/lib/node_modules/openclaw
        sudo -u termuser rclone copyto gdrive:terminal-home/openclaw.zip /home/termuser/openclaw.zip \
            --drive-acknowledge-abuse 2>&1
        mkdir -p /home/termuser/.local/lib/node_modules
        unzip -o -q /home/termuser/openclaw.zip -d /home/termuser/.local/lib/node_modules/
        rm /home/termuser/openclaw.zip
        # Mark install complete
        touch "$OPENCLAW_READY"
        chown -R termuser:termuser /home/termuser/.local
        echo "✔ OpenClaw installed from zip"
    else
        echo "✔ OpenClaw already installed"
    fi

    # ── 5. Create symlink if missing ─────────────────────────────────
    if [ -f "$OPENCLAW_MJS" ] && [ ! -f "$OPENCLAW_BIN" ]; then
        mkdir -p /home/termuser/.local/bin
        ln -s "$OPENCLAW_MJS" "$OPENCLAW_BIN"
        chmod +x "$OPENCLAW_BIN"
        chown termuser:termuser "$OPENCLAW_BIN"
        echo "✔ OpenClaw symlink created"
    fi

    # ── 6. Start openclaw gateway ────────────────────────────────────
    if [ -f "$OPENCLAW_MJS" ]; then
        echo "⟳ Starting OpenClaw gateway..."
        sudo -u termuser bash -c 'export PATH="$HOME/.local/bin:$PATH"; openclaw gateway' &
        echo "✔ OpenClaw gateway started"
    fi

else
    echo "⚠ RCLONE_CONFIG_BASE64 not set — Google Drive sync disabled"
fi

# ── 7. Start SSH daemon ──────────────────────────────────────────────
/usr/sbin/sshd
echo "✔ SSH server started"

# ── 8. Auto-sync to Google Drive every 5 minutes ────────────────────
if [ -n "$RCLONE_CONFIG_BASE64" ]; then
    (
        while true; do
            sleep 300
            sudo -u termuser rclone sync /home/termuser gdrive:terminal-home \
                --exclude ".config/**" \
                --exclude "openclaw.zip" \
                --drive-acknowledge-abuse \
                --log-level ERROR 2>&1 | grep -v "^$" || true
            echo "[$(date)] ✔ Synced to Google Drive"
        done
    ) &
    echo "✔ Auto-sync started (every 5 min → gdrive:terminal-home)"
fi

# ── 9. Start serveo.net SSH tunnel ───────────────────────────────────
(
    sleep 3
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Starting SSH tunnel via serveo.net..."
    echo "  Look for: 'Forwarding TCP connections from tcp://serveo.net:XXXXX'"
    echo "  In PuTTY: Host=serveo.net  Port=XXXXX"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ssh -o StrictHostKeyChecking=no \
        -o ServerAliveInterval=30 \
        -o ServerAliveCountMax=3 \
        -R 0:localhost:22 \
        serveo.net 2>&1
) &

# ── 10. Start ttyd web terminal ──────────────────────────────────────
echo "✔ Starting web terminal on port ${PORT:-7681}"
exec ttyd --port "${PORT:-7681}" \
          -W \
          --base-path / \
          bash --login
