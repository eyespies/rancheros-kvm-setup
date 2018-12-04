#!/bin/bash

if [ -z "$1" ] ; then
  printf 'Required parameter "SERVER_ID" is not set\n'
  exit -1
fi

# Hostname from which the cloud init config files are retrieved.
HH=${HTTP_HOST:-cloud-init}

# Default name of the config file
CF=${CONFIG_FILE:-install-config}

# Which version of Rancher OS is installed
RV=${RANCHEROS_VERSION:-latest}

# How big to make the LV used to host the OS
DS=${DISK_SIZE:-40G}

PF=${PREFIX:-rancheros}

case "$1" in
  1)
    MAC=",mac=52:54:00:4d:d2:00"
    ;;
  2)
    MAC=",mac=52:54:00:4d:d2:01"
    ;;
  3)
    MAC=",mac=52:54:00:4d:d2:02"
    ;;
  *)
    MAC=""
esac

# virt-install does not currently support booting Rancher OS using '--location' with the ISO file as the location. It is
# possible to use '--boot kernel=...,initrd=...', however that is an ephemeral system. To install and run from disk, instead
# of from ramdisk, we create the pxeboot directory and put the initrd and vmlinuz files into the pxeboot path.
test -d RancherOS/images/pxeboot || mkdir -p RancherOS/images/pxeboot
test -f RancherOS/images/pxeboot/vmlinuz || /bin/curl --fail --output $(pwd)/RancherOS/images/pxeboot/vmlinuz https://releases.rancher.com/os/${RV}/vmlinuz
test -f RancherOS/images/pxeboot/initrd.img || /bin/curl --fail --output $(pwd)/RancherOS/images/pxeboot/initrd.img https://releases.rancher.com/os/${RV}/initrd

if ! lvs | grep ${PF}0${1}Vol > /dev/null ; then
  lvcreate -L ${DS} -n ${PF}0${1}Vol vg00
fi

virsh destroy ${PF}-0$1
virsh undefine ${PF}-0$1
dd if=/dev/zero of=/dev/vg00/${PF}0${1}Vol if=/dev/zero bs=1M count=128
printf  'mklabel gpt\nq\n' | parted /dev/vg00/${PF}0${1}Vol

printf 'Data source is "%s"\n' "rancher.cloud_init.datasources=['url:https://${HH}/${CF}']"

virt-install --name ${PF}-0$1 --memory 8192 --vcpus 6 --cpu host --os-type linux --os-variant rhel7 \
  --vnc \
  --noautoconsole \
  --accelerate \
  -w bridge=bridge0,model=virtio${MAC} \
  --disk /dev/vg00/${PF}0${1}Vol,device=disk,bus=virtio \
  --extra-args="rancher.state.dev=LABEL=RANCHER_STATE rancher.state.autoformat=[/dev/sda,/dev/vda] rancher.password=password rancher.cloud_init.datasources=['url:https://${HH}/${CF}']" \
  --location '/srv/rancher/RancherOS' \
  --boot hd


# This boots from the local kernel if the HD isn't available, however it never truly goes through the install phase, so the process is not meant to be permanent. 
#  --boot hd,kernel=/srv/docker/RancherOS/vmlinuz,initrd=/srv/docker/RancherOS/initrd,kernel_args="rancher.state.dev=LABEL=RANCHER_STATE rancher.state.autoformat=[/dev/sda,/dev/vda] rancher.password=password rancher.cloud_init.datasources=['url:http://192.168.86.35/install-config']"
