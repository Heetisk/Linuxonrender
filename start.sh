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

# ── 2. Start SSH daemon ──────────────────────────────────────────────
/usr/sbin/sshd
echo "✔ SSH server started on port 22"

# ── 3. Start localhost.run tunnel ────────────────────────────────────
(
  sleep 3
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Starting SSH tunnel via localhost.run..."
  echo "  Look for: 'tunneled with tls termination, https://xxxxx.localhost.run'"
  echo "  Use that hostname + port in PuTTY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ssh -o StrictHostKeyChecking=no \
      -o ServerAliveInterval=30 \
      -o ServerAliveCountMax=3 \
      -R 22:localhost:22 \
      nokey@localhost.run 2>&1
) &

# ── 4. Start ttyd web terminal ───────────────────────────────────────
echo "✔ Starting web terminal on port ${PORT:-7681}"
exec ttyd --port "${PORT:-7681}" \
          --writable \
          --base-path / \
          bash --login
