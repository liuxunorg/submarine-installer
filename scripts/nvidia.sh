#!/bin/bash


function get_nvidia_version()
{
  chmod +x ${PACKAGE_DIR}/nvidia/nvidia-detect
  local nvidia_detect_info=`${PACKAGE_DIR}/nvidia/nvidia-detect -v`
  echo $nvidia_detect_info | sed "s/^.*This device requires the current \([0-9.]*\).*/\1/"
}

function install_nvidia()
{
  echo "execution nvidia-detect to check the graphics card ..."
  local nvidiaVersion=`get_nvidia_version`
  echo -e "detect nvidia version is \033[31m${nvidiaVersion}\033[0m"
  
  # download NVIDIA driver
  if [[ "$nvidiaVersion" = "" ]]; then
    echo "ERROR: No graphics card device detected"
    exit_install
  else
    local nvidia_run_file="NVIDIA-Linux-x86_64-${nvidiaVersion}.run"
    if [[ -f ${DOWNLOAD_DIR}/${nvidia_run_file} ]]; then
      echo "NVIDIA driver files already exist in the ${DOWNLOAD_DIR}/${nvidia_run_file} directory."
      echo "===== Please make sure the ${DOWNLOAD_DIR}/${nvidia_run_file} file is complete and can be used normally. ====="
    else
      # http://us.download.nvidia.com/XFree86/Linux-x86_64/390.87/NVIDIA-Linux-x86_64-390.87.run
      local downloadUrl="http://us.download.nvidia.com/XFree86/Linux-x86_64/${nvidiaVersion}/NVIDIA-Linux-x86_64-${nvidiaVersion}.run"
      echo "Download the NVIDIA driver from the ${downloadUrl}"
      wget -P ${DOWNLOAD_DIR} ${downloadUrl}
    fi
  fi

  # Confirm that the system disables nouveau
  local disable_nouveau_info=`lsmod | grep nouveau`
  if [[ "$disable_nouveau_info" = "" ]]; then
    echo "===== Start installing the NVIDIA driver ====="
    echo -e "
Some options during the installation
Would you like to register the kernel module sources with DKMS? 
  This will allow DKMS to automatically build a new module, if you install a different kernel later. \033[33m[Yes]\033[0m
Install NVIDIA's 32-bit compatibility libraries \033[33m[Yes]\033[0m
centos Install NVIDIA's 32-bit compatibility libraries \033[33m[Yes]\033[0m
Would you like to run the nvidia-xconfig utility to automatically update your X configuration file... \033[33m[No]\033[0m
          "
    sleep 2
    sh ${DOWNLOAD_DIR}/${nvidia_run_file}
  else
    echo -e "ERROR: Nouveau is not disabled"
    exit_install
  fi

  echo " ===== After the installation is complete, execute NVIDIA-SMI, you should see the list of graphics cards ===== "
  echo -e "\033[33m
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 390.87                 Driver Version: 390.87                    |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  GeForce GTX 108...  Off  | 00000000:04:00.0 Off |                  N/A |
| 23%   28C    P8    15W / 250W |     10MiB / 11178MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
+-----------------------------------------------------------------------------+
| Processes:                                                       GPU Memory |
|  GPU       PID   Type   Process name                             Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+
\033[0m"
  echo "===== If you don't see the list of graphics cards above, the NVIDIA driver installation failed. ====="
  sleep 2
  nvidia-smi
}

function uninstall_nvidia()
{
  if [ ! -f "/usr/bin/nvidia-uninstall" ]; then
    echo -e "ERROR: /usr/bin/nvidia-uninstall file is not exist!"
    return 1
  fi

  echo -e "execute /usr/bin/nvidia-uninstall"
  /usr/bin/nvidia-uninstall
}
