#!/bin/bash
# Create the Arch Linux test VM
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
VM_NAME="dotfiles-test"
VM_RAM="4096"  # 4GB
VM_CPUS="2"
VM_DISK_SIZE="50"  # 50GB
# Use system libvirt paths (accessible by libvirt-qemu user)
VM_DIR="/var/lib/libvirt/images"
ISO_DIR="$DOTFILES_DIR/vm"
ISO_SOURCE="$ISO_DIR/archlinux.iso"
ISO_PATH="/var/lib/libvirt/images/archlinux.iso"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Create Arch Linux Test VM                                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo

# Check for ISO in local dir, copy to libvirt path if needed
if [[ ! -f "$ISO_SOURCE" ]]; then
    echo "ERROR: Arch ISO not found at $ISO_SOURCE"
    echo "Download it with: make vm-download-iso"
    exit 1
fi

# Copy ISO to libvirt-accessible location if not already there
if [[ ! -f "$ISO_PATH" ]]; then
    echo "▶ Copying ISO to $VM_DIR (requires sudo)..."
    sudo cp "$ISO_SOURCE" "$ISO_PATH"
    sudo chown libvirt-qemu:libvirt-qemu "$ISO_PATH" 2>/dev/null || true
fi

# Grant libvirt-qemu access to dotfiles directory for virtiofs sharing
echo "▶ Setting up permissions for shared folder..."
# Add execute permission on parent directories so libvirt-qemu can traverse
sudo setfacl -m u:libvirt-qemu:x "$HOME"
sudo setfacl -R -m u:libvirt-qemu:rX "$DOTFILES_DIR"
sudo setfacl -R -d -m u:libvirt-qemu:rX "$DOTFILES_DIR"

# Use system connection for all virsh commands
VIRSH="virsh --connect qemu:///system"

# Check if VM already exists
if $VIRSH list --all --name | grep -q "^${VM_NAME}$"; then
    echo "VM '$VM_NAME' already exists."
    read -rp "Delete and recreate? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "Removing existing VM..."
        $VIRSH destroy "$VM_NAME" 2>/dev/null || true
        $VIRSH undefine "$VM_NAME" --remove-all-storage --nvram 2>/dev/null || true
        # Force remove disk if still present
        sudo rm -f "$VM_DIR/${VM_NAME}.qcow2" 2>/dev/null || true
        sleep 1
    else
        echo "Aborted."
        exit 0
    fi
fi

# Clean up any orphaned disk from previous failed attempts
if [ -f "$VM_DIR/${VM_NAME}.qcow2" ]; then
    echo "Removing orphaned disk..."
    sudo rm -f "$VM_DIR/${VM_NAME}.qcow2"
fi

echo "Creating VM with:"
echo "  Name: $VM_NAME"
echo "  RAM: ${VM_RAM}MB"
echo "  CPUs: $VM_CPUS"
echo "  Disk: ${VM_DISK_SIZE}GB"
echo "  Shared folder: $DOTFILES_DIR → /mnt/dotfiles"
echo

# Create disk directory
mkdir -p "$VM_DIR"

# Create the VM (use system connection for network access)
echo "▶ Creating VM..."
virt-install \
    --connect qemu:///system \
    --check path_in_use=off \
    --name "$VM_NAME" \
    --memory "$VM_RAM" \
    --vcpus "$VM_CPUS" \
    --disk path="$VM_DIR/${VM_NAME}.qcow2,size=$VM_DISK_SIZE,format=qcow2" \
    --cdrom "$ISO_PATH" \
    --os-variant archlinux \
    --network network=default \
    --graphics spice \
    --video virtio \
    --boot uefi \
    --filesystem source="$DOTFILES_DIR",target=dotfiles,driver.type=virtiofs \
    --memorybacking source.type=memfd,access.mode=shared \
    --noautoconsole

echo
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ VM created! Opening virt-manager...                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo
echo "The VM will boot from the Arch ISO."
echo
echo "INSTALL ARCH MANUALLY with these steps:"
echo "────────────────────────────────────────────────────────────────"
echo "1. In the VM, run: archinstall"
echo "2. Configure:"
echo "   - Disk: Use best-effort partitioning on /dev/vda"
echo "   - Bootloader: systemd-boot"
echo "   - Profile: Minimal"
echo "   - User: Create user 'testuser' with sudo"
echo "   - Additional packages: git stow base-devel fish"
echo "3. Complete installation and reboot"
echo "4. After reboot, run IN THE VM:"
echo "   sudo mkdir -p /mnt/dotfiles"
echo "   echo 'dotfiles /mnt/dotfiles virtiofs defaults 0 0' | sudo tee -a /etc/fstab"
echo "   sudo mount -a"
echo "5. Take a snapshot: make vm-snapshot"
echo "────────────────────────────────────────────────────────────────"
echo

# Open virt-manager
virt-manager --connect qemu:///system --show-domain-console "$VM_NAME" &
