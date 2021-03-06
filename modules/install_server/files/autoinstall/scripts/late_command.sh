#!/bin/sh

set -e
set -x

# Install the public root ssh key
mkdir /target/root/.ssh
wget -O /target/root/.ssh/authorized_keys http://apt.wikimedia.org/autoinstall/ssh/authorized_keys
chmod go-rwx /target/root/.ssh/authorized_keys

# lsb-release: allows conditionals in this script on in-target release codename
apt-install lsb-release
LSB_RELEASE=$(chroot /target /usr/bin/lsb_release --codename --short)

if printf $LSB_RELEASE | grep -qv buster
then
  # we dont use this service, also the reimage script assumes it is the first to run puppet
  in-target systemctl mask puppet.service
fi

# openssh-server: to make the machine accessible
# puppet: because we'll need it soon anyway
# lldpd: announce the machine on the network
apt-install openssh-server puppet lldpd

# nvme-cli: on machines with NVMe drives, this allows late_command to change
# LBA format below, but this package doesn't exist in jessie
if [ "${LSB_RELEASE}" != "jessie" ]; then
	apt-install nvme-cli
fi

# Change /etc/motd to read the auto-install date
chroot /target /bin/sh -c 'echo $(cat /etc/issue.net) auto-installed on $(date). > /etc/motd.tail'

# Disable IPv6 privacy extensions before the first boot
[ -f /target/etc/sysctl.d/10-ipv6-privacy.conf ] && rm -f /target/etc/sysctl.d/10-ipv6-privacy.conf

case `hostname` in \
	cp107[5-9]|cp108[0-9]|cp1090|cp30[56][0-9])
		# new cache nodes (mid-2018) use a single NVMe drive (Samsung
		# pm1725[ab]) for storage, which needs its LBA format changed
		# to 4K block size before manually partitioning.
		in-target /usr/sbin/nvme format /dev/nvme0n1 -l 2
		echo ';' | /usr/sbin/sfdisk /dev/nvme0n1
		;; \
esac

# Use a more recent kernel on jessie and deinstall nfs-common/rpcbind
# (we don't want these to be installed in general, only pull them in
# where actually needed. >= stretch doesn't install nfs-common/rpcbind
# any longer (T106477)
# (the upgrade is to grab our updated firmware packages first for initramfs)
if [ "$(chroot /target /usr/bin/lsb_release --codename --short)" = "jessie" ]; then
	in-target apt-get -y upgrade
	apt-install linux-meta-4.9
	in-target dpkg --purge rpcbind nfs-common libnfsidmap2 libtirpc1
fi

# Temporarily pre-provision swift user at a fixed UID on new installs.
# Once T123918 is resolved and swift is the same uid/gid everywhere, the
# 'admin' puppet module can take over.
case `hostname` in \
	ms-be[12]*|ms-fe[12]*|thanos-fe[12]*|thanos-be[12]*)
		in-target /usr/sbin/groupadd --gid 902 --system swift
		in-target /usr/sbin/useradd --gid 902 --uid 902 --system --shell /bin/false \
			--create-home --home /var/lib/swift swift
	;; \
esac

# Enable structured puppet facts on first puppet run, same as production - T169612
in-target /usr/bin/puppet config set --section agent stringify_facts false
