#!/bin/bash
VER="570.169"
#git clone git@github.com:NVIDIA/open-gpu-kernel-modules.git
sudo systemctl isolate multi-user.target
cd open-gpu-kernel-modules/
git checkout ${VER}
make modules -j40
sudo make modules_install
sudo rmmod nvidia_uvm
sudo rmmod nvidia_drm
sudo rmmod nvidia_modeset
sudo rmmod nvidia
sudo mv /lib/modules/$(uname -r)/updates/dkms/nvidia-uvm.ko{,.bak}
sudo mv /lib/modules/$(uname -r)/updates/dkms/nvidia-drm.ko{,.bak}
sudo mv /lib/modules/$(uname -r)/updates/dkms/nvidia-modeset.ko{,.bak}
sudo mv /lib/modules/$(uname -r)/updates/dkms/nvidia.ko{,.bak}
sudo depmod -a
sudo modprobe nvidia

