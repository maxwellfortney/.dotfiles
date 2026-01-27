# Arch Linux test environment for dotfiles disaster recovery
FROM archlinux:latest

# Update system and install base packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    base-devel \
    git \
    stow \
    shellcheck \
    sudo \
    fish \
    cronie \
    fontconfig \
    && pacman -Scc --noconfirm

# Create test user with sudo access
RUN useradd -m -G wheel -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set up working directory
WORKDIR /home/testuser/.dotfiles

# Copy dotfiles into container
COPY . .

# Remove .git directory and fix permissions
RUN rm -rf .git && chown -R testuser:testuser .

# Switch to test user
USER testuser

# Set home directory
ENV HOME=/home/testuser

# Default command
CMD ["/bin/bash"]
