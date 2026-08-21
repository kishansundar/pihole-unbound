#!/bin/bash

# This script installs Unbound, a validating, recursive, and caching DNS resolver.
# It can install Unbound from the latest source tarball or from the git repository.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
UNBOUND_USER="unbound"
UNBOUND_GROUP="unbound"
UNBOUND_USER_ID=88
UNBOUND_GROUP_ID=88
UNBOUND_VERSION="1.23.0" # Specify the version to download

# --- Helper Functions ---

# Log messages with a consistent format.
log() {
    echo "------------------------------------------"
    echo "$1"
    echo "------------------------------------------"
}

# Check if a command exists.
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Script Functions ---

# Create the Unbound user and group.
setup_user_and_group() {
    log "Setting up Unbound user and group..."
    if ! getent group "$UNBOUND_GROUP" >/dev/null; then
        sudo groupadd -g "$UNBOUND_GROUP_ID" "$UNBOUND_GROUP"
    else
        echo "Group '$UNBOUND_GROUP' already exists."
    fi

    if ! id "$UNBOUND_USER" >/dev/null 2>&1; then
        sudo useradd -c "Unbound DNS resolver" -d /var/lib/unbound -u "$UNBOUND_USER_ID" -g "$UNBOUND_GROUP" -s /bin/false "$UNBOUND_USER"
    else
        echo "User '$UNBOUND_USER' already exists."
    fi
}

# Install required dependencies for building Unbound.
install_dependencies() {
    log "Installing dependencies..."
    sudo apt-get update -y
    sudo apt-get install -y \
        build-essential \
        git \
        wget \
        libssl-dev \
        libevent-dev \
        libexpat-dev \
        libnghttp2-dev \
        libsodium-dev \
        libprotobuf-c-dev \
        protobuf-c-compiler
}

# Configure, compile, and install Unbound.
build_and_install() {
    log "Configuring, compiling, and installing Unbound..."
    ./configure --prefix=/usr \
                --sysconfdir=/etc \
                --with-libevent \
                --with-ssl \
                --with-pthreads \
                --enable-ecdsa \
                --enable-ed25519 \
                --enable-gost \
                --enable-pie

    make
    sudo make install
}

# Download and install Unbound from the latest source tarball.
install_from_source() {
    log "Installing Unbound from source..."
    cd ~
    wget "https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz"
    tar -xzf "unbound-${UNBOUND_VERSION}.tar.gz"
    rm "unbound-${UNBOUND_VERSION}.tar.gz"
    cd "unbound-${UNBOUND_VERSION}"
    build_and_install
    cd ~
    rm -rf "unbound-${UNBOUND_VERSION}"
}

# Clone and install Unbound from the git repository.
install_from_git() {
    log "Installing Unbound from git..."
    cd ~
    if [ -d "unbound" ]; then
        rm -rf "unbound"
    fi
    git clone https://github.com/NLnetLabs/unbound.git
    cd "unbound"
    build_and_install
    cd ~
    rm -rf "unbound"
}

# Perform post-installation tasks.
post_install() {
    log "Performing post-installation tasks..."
    sudo mv -v /usr/sbin/unbound-host /usr/bin/
    sudo curl --output /etc/unbound/root.hints https://www.internic.net/domain/named.root
    sudo unbound-anchor -a /etc/unbound/root.key -v
    unbound-control-setup
}

# --- Main ---

main() {
    setup_user_and_group
    install_dependencies

    # Ask the user for the installation method.
    read -p "Install Unbound from 'source' or 'git'? " choice
    case "$choice" in
        source)
            install_from_source
            ;;
        git)
            install_from_git
            ;;
        *)
            echo "Invalid choice. Please run the script again and choose 'source' or 'git'."
            exit 1
            ;;
    esac

    post_install
    log "Unbound installation complete."
}

main
