# Automated Kickstart profile for Bare-Metal RKE2 Fleet Nodes
# OS: Oracle Linux 9 (UEK - Unbreakable Enterprise Kernel)

text
skipx
firstboot --disable
eula --agreed

lang en_US.UTF-8
keyboard us
timezone UTC --utc

# Network configuration (LACP bonding bond0)
network --bootproto=dhcp --device=bond0 --bondslaves=enp3s0f0,enp3s0f1 --bondopts=mode=802.3ad,miimon=100 --activate

# Disk partitioning
zerombr
clearpart --all --initlabel
part /boot --fstype="xfs" --size=1024
part /boot/efi --fstype="efi" --size=512
part pv.01 --size=1 --grow
volgroup vg_system pv.01
logvol / --vgname=vg_system --size=51200 --name=lv_root --fstype=xfs
logvol /var/lib/rancher --vgname=vg_system --size=102400 --name=lv_rke2 --fstype=xfs
logvol swap --vgname=vg_system --size=8192 --name=lv_swap

# Package selection (Minimal Server + Systems Tools)
%packages --default
@core
kernel-uek
systemd-udev
ethtool
iproute
curl
tar
iptables
conntrack-tools
%end

# Post-installation optimization & kernel parameters
%post
cat <<EOF > /etc/sysctl.d/99-kubernetes-fleet.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
vm.swappiness = 10
vm.max_map_count = 262144
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 8192
EOF
sysctl --system

# Load required overlay & br_netfilter modules
cat <<EOF > /etc/modules-load.d/k8s-modules.conf
overlay
br_netfilter
EOF
%end
reboot
