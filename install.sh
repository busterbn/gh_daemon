#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== gh-daemon installer ==="

# Copy unit files
sudo cp "$SCRIPT_DIR/gh-daemon.service" /etc/systemd/system/
sudo cp "$SCRIPT_DIR/gh-daemon.timer" /etc/systemd/system/

# Reload systemd, enable and start the timer
sudo systemctl daemon-reload
sudo systemctl enable gh-daemon.timer
sudo systemctl start gh-daemon.timer

echo ""
echo "Installed and started. Timer status:"
systemctl status gh-daemon.timer --no-pager
echo ""
echo "Next run:"
systemctl list-timers gh-daemon.timer --no-pager
echo ""
echo "To test manually:  sudo systemctl start gh-daemon.service"
echo "To view logs:      journalctl -u gh-daemon.service -f"
echo "To uninstall:      sudo systemctl disable --now gh-daemon.timer && sudo rm /etc/systemd/system/gh-daemon.{service,timer}"
