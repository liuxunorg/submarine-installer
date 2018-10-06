

function get_nvidia_version()
{
  local nvidia_detect_info=`nvidia-detect -v`
  echo $nvidia_detect_info | sed "s/^.*This device requires the current \([0-9.]*\).*/\1/"
}

function install_cuda()
{

}

function uninstall_cuda()
{
  if [ ! -d "/usr/local/cuda/bin" ]; then
    echo "/usr/local/cuda/bin folder path is not exist!"
    return 1
  fi

  uninstall_pl=`find /usr/local/cuda/bin -name uninstall_cuda_*.pl`
  if [ ! -f ${uninstall_pl} ]; then
    echo "/usr/local/cuda/bin/uninstall_cuda_*.pl file is not exist!"
    return 1
  fi

  echo "sudo >>> ${uninstall_pl}"

  exit
	sudo ${uninstall_pl}
}

# Some preparatory work for nvidia driver installation
function prepare_installation()
{
  yum -y update
  yum -y install kernel-devel

  yum -y install epel-release
  yum -y install dkms

  echo " ===== Please manually execute the following command ====="
  echo "
        # 1. Disable nouveau
        # Add the content 'rd.driver.blacklist=nouveau nouveau.modeset=0' 
        # to the 'GRUB_CMDLINE_LINUX' configuration item in the /etc/default/grub file.
        shell:> vi /etc/default/grub
        vi:> GRUB_CMDLINE_LINUX=\"rd.driver.blacklist=nouveau nouveau.modeset=0 ...\"

        # 2. Generate configuration
        shell:> grub2-mkconfig -o /boot/grub2/grub.cfg

        # 3. Open (new) /etc/modprobe.d/blacklist.conf, add content 'blacklist nouveau'
        shell:> vi /etc/modprobe.d/blacklist.conf
        vi:> blacklist nouveau

        # 4. Update configuration and reboot
        mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r)-nouveau.img
        dracut /boot/initramfs-$(uname -r).img $(uname -r)
        reboot
  "
}

function install_nvidia()
{
  echo "add ElRepo source"
  rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
  rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm

  echo "Install nvidia-detect to check the graphics card ..."
  yum install nvidia-detect

  echo "execution nvidia-detect to check the graphics card ..."
  local nvidiaVersion=`get_nvidia_version`
  
  # download NVIDIA driver
  if [[ "$nvidiaVersion" = "" ]]; then
    echo "ERROR: No graphics card device detected"
    exit_install
  else
    local nvidia_run_file="NVIDIA-Linux-x86_64-${nvidiaVersion}.run"
    if [[ -f ${INSTALL_TEMP_DIR}/${nvidia_run_file}]]; then
      echo "NVIDIA driver files already exist in the ${INSTALL_TEMP_DIR}/${nvidia_run_file} directory."
      echo "===== Please make sure the ${INSTALL_TEMP_DIR}/${nvidia_run_file} file is complete and can be used normally. ====="
    else
      # http://us.download.nvidia.com/XFree86/Linux-x86_64/390.87/NVIDIA-Linux-x86_64-390.87.run
      local downloadUrl="http://us.download.nvidia.com/XFree86/Linux-x86_64/${nvidiaVersion}/NVIDIA-Linux-x86_64-${nvidiaVersion}.run"
      echo "Download the NVIDIA driver from the ${downloadUrl}"
      wget -P ${INSTALL_TEMP_DIR} ${downloadUrl}
    fi
  fi

  # Confirm that the system disables nouveau
  local disable_nouveau_info=`lsmod | grep nouveau`
  if [[ "$nvidiaVersion" = "" ]]; then
    echo "===== Start installing the NVIDIA driver ====="
    echo "
          Some options during the installation
          Install NVIDIA's 32-bit compatibility libraries (Yes)
          centos Install NVIDIA's 32-bit compatibility libraries (Yes) 
          Would you like to run the nvidia-xconfig utility to automatically update your X configuration file... (NO)
          "
    sleep 2
    sh ${nvidia_run_file}
  else
    echo "ERROR: Nouveau is not disabled"
    exit_install
  fi

  echo " ===== After the installation is complete, execute NVIDIA-SMI, you should see the list of graphics cards ===== "
  echo "+-----------------------------------------------------------------------------+
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
  "
  echo "===== If you don't see the list of graphics cards above, the NVIDIA driver installation failed. ====="
  sleep 2
  nvidia-smi
}

function uninstall_nvidia()
{
  if [ ! -f "/usr/bin/nvidia-uninstall" ]; then
    echo "/usr/bin/nvidia-uninstall file is not exist!"
    return 1
  fi

  echo "sudo >>> /usr/bin/nvidia-uninstall"
  # sudo /usr/bin/nvidia-uninstall
}
