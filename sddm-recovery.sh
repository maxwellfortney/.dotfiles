#!/bin/bash
# SDDM Theme Recovery Script
# Run this if SDDM breaks after stowing the theme

echo "SDDM Theme Recovery Script"
echo "========================="

echo "1. Unstowing SDDM theme..."
sudo stow -D --target=/ sddm

echo "2. Restarting SDDM..."
sudo systemctl restart sddm

echo "3. Checking SDDM status..."
sudo systemctl status sddm --no-pager

echo "Recovery complete! Try switching back to the display manager."











