#!/bin/bash
# VM control script for dotfiles testing
set -e

VM_NAME="dotfiles-test"
SNAPSHOT_NAME="clean-base"
VIRSH="virsh --connect qemu:///system"

usage() {
    echo "Usage: $0 <command>"
    echo
    echo "Commands:"
    echo "  start       - Start the VM"
    echo "  stop        - Gracefully stop the VM"
    echo "  kill        - Force stop the VM"
    echo "  console     - Open VM console in virt-manager"
    echo "  ssh         - SSH into the VM"
    echo "  snapshot    - Create a 'clean-base' snapshot"
    echo "  reset       - Restore to 'clean-base' snapshot"
    echo "  restore     - Run restore.sh in the VM"
    echo "  status      - Show VM status"
    echo "  ip          - Show VM IP address"
    echo
}

get_vm_ip() {
    $VIRSH domifaddr "$VM_NAME" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1
}

wait_for_vm() {
    echo -n "Waiting for VM to be ready"
    for _ in {1..60}; do
        if ip=$(get_vm_ip) && [[ -n "$ip" ]]; then
            echo " ✓"
            echo "VM IP: $ip"
            return 0
        fi
        echo -n "."
        sleep 2
    done
    echo " timeout"
    return 1
}

wait_for_ssh() {
    local ip="$1"
    echo -n "Waiting for SSH"
    for _ in {1..30}; do
        if ssh -q -o ConnectTimeout=2 -o StrictHostKeyChecking=no "testuser@$ip" exit 2>/dev/null; then
            echo " ✓"
            return 0
        fi
        echo -n "."
        sleep 2
    done
    echo " timeout"
    return 1
}

case "${1:-}" in
    start)
        echo "Starting VM '$VM_NAME'..."
        $VIRSH start "$VM_NAME"
        wait_for_vm
        ;;
    
    stop)
        echo "Stopping VM '$VM_NAME'..."
        $VIRSH shutdown "$VM_NAME"
        ;;
    
    kill)
        echo "Force stopping VM '$VM_NAME'..."
        $VIRSH destroy "$VM_NAME"
        ;;
    
    console)
        echo "Opening console..."
        virt-manager --connect qemu:///system --show-domain-console "$VM_NAME" &
        ;;
    
    ssh)
        ip=$(get_vm_ip)
        if [[ -z "$ip" ]]; then
            echo "ERROR: Cannot get VM IP. Is the VM running?"
            exit 1
        fi
        echo "Connecting to testuser@$ip..."
        ssh -o StrictHostKeyChecking=no "testuser@$ip"
        ;;
    
    snapshot)
        echo "Creating snapshot '$SNAPSHOT_NAME'..."
        # VM must be off for external snapshots with UEFI
        state=$($VIRSH domstate "$VM_NAME" 2>/dev/null || echo "unknown")
        if [[ "$state" == "running" ]]; then
            echo "Shutting down VM first..."
            $VIRSH shutdown "$VM_NAME"
            sleep 5
            for _ in {1..30}; do
                state=$($VIRSH domstate "$VM_NAME" 2>/dev/null)
                [[ "$state" == "shut off" ]] && break
                sleep 2
            done
        fi
        
        # Delete old snapshot if exists
        $VIRSH snapshot-delete "$VM_NAME" "$SNAPSHOT_NAME" 2>/dev/null || true
        
        # Create snapshot
        $VIRSH snapshot-create-as "$VM_NAME" "$SNAPSHOT_NAME" \
            --description "Clean Arch install for dotfiles testing"
        echo "✓ Snapshot '$SNAPSHOT_NAME' created"
        ;;
    
    reset)
        echo "Restoring to snapshot '$SNAPSHOT_NAME'..."
        $VIRSH snapshot-revert "$VM_NAME" "$SNAPSHOT_NAME"
        echo "✓ VM restored to clean state"
        echo
        read -rp "Start the VM now? [Y/n] " confirm
        if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
            $VIRSH start "$VM_NAME"
            wait_for_vm
        fi
        ;;
    
    restore)
        ip=$(get_vm_ip)
        if [[ -z "$ip" ]]; then
            echo "ERROR: Cannot get VM IP. Is the VM running?"
            exit 1
        fi
        
        echo "Running restore.sh in VM..."
        echo "────────────────────────────────────────────────────────────────"
        ssh -o StrictHostKeyChecking=no "testuser@$ip" \
            "cd /mnt/dotfiles && ./restore/restore.sh"
        echo "────────────────────────────────────────────────────────────────"
        echo
        echo "✓ Restore complete!"
        echo "Reboot the VM to test: make vm-reboot"
        ;;
    
    reboot)
        echo "Rebooting VM '$VM_NAME'..."
        $VIRSH reboot "$VM_NAME"
        sleep 3
        wait_for_vm
        ;;
    
    status)
        echo "VM Status:"
        $VIRSH domstate "$VM_NAME"
        echo
        echo "Snapshots:"
        $VIRSH snapshot-list "$VM_NAME" 2>/dev/null || echo "  (none)"
        echo
        ip=$(get_vm_ip)
        if [[ -n "$ip" ]]; then
            echo "IP Address: $ip"
        fi
        ;;
    
    ip)
        ip=$(get_vm_ip)
        if [[ -n "$ip" ]]; then
            echo "$ip"
        else
            echo "ERROR: Cannot get VM IP. Is the VM running?"
            exit 1
        fi
        ;;
    
    *)
        usage
        exit 1
        ;;
esac
