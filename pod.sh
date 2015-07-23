#! /bin/bash

if [ "$1" == "-s" ]
then
    KVM_OPTS="-snapshot"
else
    KVM_OPTS=""
fi

KVM="qemu-system-x86_64"

MAC="52:54:00:00:00:02"

TAP=$(sudo tunctl -b -u ilan)
sudo ifconfig $TAP up
sudo brctl addif intbr $TAP

KVM_OPTS="$KVM_OPTS -netdev type=tap,id=net0,script=no,downscript=no,vhost=off,ifname=$TAP -device virtio-net-pci,netdev=net0,mac=$MAC"
KVM_OPTS="$KVM_OPTS -m 4G -name Ubuntu"
#KVM_OPTS="$KVM_OPTS -smp 2"

KVM_OPTS="$KVM_OPTS -drive file=/home/ilan/images/UbuntuBase.img,if=virtio"

$KVM $KVM_OPTS

sudo brctl delif intbr $TAP
sudo tunctl -d $TAP > /dev/null
