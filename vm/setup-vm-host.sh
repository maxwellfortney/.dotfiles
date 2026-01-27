#!/bin/bash
# Setup VM host dependencies (run on your main machine)
set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Dotfiles VM Test Environment - Host Setup                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "ERROR: Don't run this as root. It will use sudo when needed."
    exit 1
fi

echo "This script will install:"
echo "  - qemu-desktop (VM hypervisor)"
echo "  - libvirt (VM management)"
echo "  - virt-manager (GUI for VMs)"
echo "  - dnsmasq (VM networking)"
echo "  - edk2-ovmf (UEFI support)"
echo

read -rp "Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo
echo "▶ Installing packages..."
sudo pacman -S --needed qemu-desktop libvirt virt-manager dnsmasq edk2-ovmf acl

echo
echo "▶ Enabling libvirt service..."
sudo systemctl enable --now libvirtd.service
sudo systemctl enable --now virtlogd.service

echo
echo "▶ Adding $USER to libvirt group..."
sudo usermod -aG libvirt "$USER"

echo
echo "▶ Setting up default network..."
# Define the default network if it doesn't exist
if ! sudo virsh net-info default &>/dev/null; then
    sudo virsh net-define /usr/share/libvirt/networks/default.xml
fi
# Start and autostart it
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true
echo "  Network status:"
sudo virsh net-list --all

echo
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ Host setup complete!                                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo
echo "IMPORTANT: Log out and back in for group changes to take effect."
echo
echo "Next steps:"
echo "  1. Log out and back in (or run: newgrp libvirt)"
echo "  2. Download Arch ISO: make vm-download-iso"
echo "  3. Create the VM: make vm-create"
echo
