#!/bin/bash
set -euxo pipefail

[ $(id -u) -eq 0 ] || exec sudo bash $0 "$@"

[ -e /usr/share/devtools/pacman-extra.conf ] || {
	echo "Missing 'devtools' on this system. Please 'pacman -S devtools'."
	exit 1
}

# Packages required for the minimal system
packages=(
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
	rm -rf ${tmpdir}
}
trap rm_temp EXIT

# Pacstrap the requested packages
env -i pacstrap -C /usr/share/devtools/pacman-extra.conf -c -d -G -M ${tmpdir} "${packages[@]}"

# Add local configurations
cp --recursive --preserve=timestamps --backup --suffix=.pacnew rootfs/* ${tmpdir}/

# Initialize locales and pacman-keys
arch-chroot ${tmpdir} locale-gen
arch-chroot ${tmpdir} pacman-key --init
arch-chroot ${tmpdir} pacman-key --populate archlinux

# Temporarily break the tmpfiles hook which causes every pacman operation to hang forever
sed -i 's!^Exec.*!Exec = /usr/bin/true!' ${tmpdir}/usr/share/libalpm/hooks/30-systemd-tmpfiles.hook

cat >${tmpdir}/usr/share/libalpm/hooks/01-remove-tmpfiles.hook <<-'EOF'
	[Trigger]
	Type = Path
	Operation = Install
	Operation = Upgrade
	Target = usr/share/libalpm/hooks/*.hook

	[Action]
	Description = Removing tmpfiles hook...
	When = PostTransaction
	Exec = /usr/bin/bash -exc "/usr/bin/sed -i 's!^Exec = .*/systemd-hook tmpfiles!Exec = /usr/bin/true!' /usr/share/libalpm/hooks/*.hook"
EOF

# Pack rootfs
tar --numeric-owner --xattrs --acls --exclude-from=exclude -C ${tmpdir} -c . -f archlinux.tar
