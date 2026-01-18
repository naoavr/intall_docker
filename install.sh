#!/usr/bin/env bash
# Install Docker Engine on Debian (official repository)

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)." >&2
  exit 1
fi

echo "[1/6] Updating package index..."
apt-get update -y

echo "[2/6] Installing prerequisites..."
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

echo "[3/6] Setting up Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.asc ]; then
  curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
fi

echo "[4/6] Adding Docker apt repository..."
ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"

cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${CODENAME} stable
EOF

echo "[5/6] Updating package index (with Docker repo)..."
apt-get update -y

echo "[6/6] Installing Docker Engine and plugins..."
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

echo "Enabling and starting Docker service..."
systemctl enable docker
systemctl start docker

# Optional: create docker group and add invoking user (if run via sudo)
if [ -n "$SUDO_USER" ]; then
  echo "Configuring non-root Docker usage for user: $SUDO_USER"
  groupadd -f docker
  usermod -aG docker "$SUDO_USER"
  echo "User '$SUDO_USER' was added to 'docker' group."
  echo "You must log out and back in for group changes to take effect."
fi

echo "Verifying Docker installation with 'hello-world' image..."
if docker run --rm hello-world >/dev/null 2>&1; then
  echo "Docker installed and works correctly."
else
  echo "Docker installed, but 'hello-world' test failed; check 'docker run hello-world' manually." >&2
fi

echo "Done."
