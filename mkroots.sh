#!/bin/bash
set -euxo pipefail

[ $(id -u) -eq 0 ] || exec sudo bash $0 "$@"

[ -e /usr/share/devtools/pacman.conf.d/extra.conf ] || {
  echo "Missing 'devtools' on this system. Please 'pacman -S devtools'."
  exit 1
}

# Packages required for the minimal system
packages=(
  archlinux-keyring
  awk
  gzip
  pacman
  sed
  systemd
)

# In case more packages were passed add them to the package list
if [ $# -gt 0 ]; then
  packages+=("$@")
fi

# Build in a tempdir
tmpdir=$(mktemp -d)
function rm_temp() {
  umount ${tmpdir}
  rm -rf ${tmpdir}
}
trap rm_temp EXIT

# Create a bind-mount to avoid side-effects on the host system
mount --bind ${tmpdir} ${tmpdir}

# Pacstrap the requested packages
env -i pacstrap -C /usr/share/devtools/pacman.conf.d/extra.conf -c -G -M ${tmpdir} "${packages[@]}"

# Add local configurations
cp --recursive --preserve=timestamps --backup --suffix=.pacnew rootfs/* ${tmpdir}/

# Initialize locales and pacman-keys
arch-chroot ${tmpdir} bash -ex <<EOF
# Generate locales
locale-gen

# Initialize pacman-key keyring
pacman-key --init
pacman-key --populate archlinux

# Disable sandboxes for Container pacman
sed -i 's/#DisableSandbox/DisableSandbox/' /etc/pacman.conf

# Stop agent to free /dev mount
export GNUPGHOME=/etc/pacman.d/gnupg
gpgconf --kill gpg-agent

# Give the agent some time to die
sleep 5
EOF

# Pack rootfs
tar --numeric-owner --xattrs --acls --exclude-from=exclude -C ${tmpdir} -c . -f archlinux.tar
