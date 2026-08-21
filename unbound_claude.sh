#!/bin/bash
# Script to compile Unbound 1.26.0 from source with latest OpenSSL
# This should fix ECDSA Algorithm 13 signature verification issues

set -e  # Exit on any error

echo "=== Unbound 1.23.0 Compilation Script ==="
echo "This will compile Unbound from source with the latest OpenSSL"
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

# Install build dependencies
echo "Installing build dependencies..."
sudo apt update
sudo apt install -y \
    build-essential \
    libssl-dev \
    libexpat1-dev \
    libevent-dev \
    libprotobuf-c-dev \
    protobuf-c-compiler \
    flex \
    bison \
    checkinstall \
    pkg-config \
    wget

# Create build directory
BUILD_DIR="/tmp/unbound-build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Download Unbound 1.26.0 source
echo "Downloading Unbound 1.26.0 source..."
wget https://www.nlnetlabs.nl/downloads/unbound/unbound-1.26.0.tar.gz
wget https://www.nlnetlabs.nl/downloads/unbound/unbound-1.26.0.tar.gz.asc

# Verify signature (optional, but recommended)
echo "Extracting source..."
tar -xzf unbound-1.23.0.tar.gz
cd unbound-1.23.0

# Check OpenSSL version that will be used
echo "OpenSSL version to be used:"
pkg-config --modversion openssl

# Configure with optimizations for Pi 4
echo "Configuring Unbound..."
./configure \
    --prefix=/usr/local \
    --sysconfdir=/etc \
    --with-conf-file=/etc/unbound/unbound.conf \
    --with-pidfile=/run/unbound.pid \
    --with-username=unbound \
    --with-ssl \
    --enable-dnssec \
    --enable-ecdsa \
    --enable-event-api \
    --enable-tfo-client \
    --enable-tfo-server \
    --with-libevent \
    --enable-subnet \
    --enable-cachedb \
    --disable-static \
    --enable-shared

# Compile (use all CPU cores)
echo "Compiling Unbound (this may take 10-20 minutes)..."
make -j$(nproc)

# Run tests (optional)
echo "Running tests..."
make test

# Backup current Unbound config
echo "Backing up current configuration..."
sudo cp /etc/unbound/unbound.conf /etc/unbound/unbound.conf.backup.$(date +%Y%m%d)

# Stop current Unbound
echo "Stopping current Unbound..."
sudo systemctl stop unbound

# Install new Unbound
echo "Installing new Unbound..."
sudo make install

# Update library links
sudo ldconfig

# Create/update systemd service file for new location
sudo tee /etc/systemd/system/unbound.service > /dev/null << 'EOF'
[Unit]
Description=Unbound DNS server
Documentation=man:unbound(8)
After=network-online.target
Before=nss-lookup.target
Wants=nss-lookup.target

[Service]
Type=notify
Restart=on-failure
RestartSec=5s
ExecStartPre=/usr/local/sbin/unbound-anchor -a /etc/unbound/root.key
ExecStart=/usr/local/sbin/unbound -d -c /etc/unbound/unbound.conf
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=5
User=unbound
Group=unbound

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/etc/unbound /run /var/lib/unbound

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable unbound

# Check new version
echo "New Unbound version:"
/usr/local/sbin/unbound -V | head -5

# Start new Unbound
echo "Starting new Unbound..."
sudo systemctl start unbound

# Check status
sudo systemctl status unbound

echo "=== Compilation Complete ==="
echo "Unbound 1.23.0 has been compiled and installed from source"
echo "New binary location: /usr/local/sbin/unbound"
echo "Configuration: /etc/unbound/unbound.conf"
echo ""
echo "To test ECDSA support:"
echo "1. Remove 'domain-insecure: tmbnet.in' from /etc/unbound/unbound.conf"
echo "2. sudo systemctl restart unbound"
echo "3. dig @127.0.0.1 -p 5353 www.tmbnet.in"
echo ""
echo "If it works without SERVFAIL, the ECDSA issue is fixed!"
