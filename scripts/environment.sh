#!/bin/bash

. ${ROOT}/scripts/utils.sh

function check_operationSystem()
{
  echo -e "The submarine assembly support \033[32m[centos-release-7-3.1611.el7.centos.x86_64]\033[0m or higher operating system version."

case ${OPERATING_SYSTEM} in
centos)
  local operationSystemVersion=`rpm --query centos-release` 
  echo -e "The current operating system version is \e[31m[${operationSystemVersion}]\e[0m" | tee -a $LOG
  ;;
*)
  echo -e "\033[31mWARN: The submarine assembly Unsupported [${OPERATING_SYSTEM}] operating system\033[0m"
  ;;
esac
}

function update_operationSystemKernel()
{
  echo "If the server is unable to connect to the network, execute the following command yourself:
        wget http://vault.centos.org/7.3.1611/os/x86_64/Packages/kernel-headers-3.10.0-514.el7.x86_64.rpm
        rpm -ivh kernel-headers-3.10.0-514.el7.x86_64.rpm"

  echo -n "Do you want to kernel upgrades?[y|n]"
  read myselect
  if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
  then
    echo "Now try to use the yum command for kernel upgrades ..."
    yum install kernel-devel-$(uname -r) kernel-headers-$(uname -r)

    local kernelVersion=`uname -r`
    echo -e "After the upgrade, the operating system kernel version is \e[31m${kernelVersion}\e[0m" | tee -a $LOG
  fi
}

function check_operationSystemKernel()
{
case ${OPERATING_SYSTEM} in
centos)
  local kernelVersion=`uname -r`

  echo -e "Submarine support operating system kernel version is \033[32m 3.10.0-514.el7.x86_64 \033[0m" | tee -a $LOG
  echo -e "Current operating system kernel version is \e[31m${kernelVersion}\e[0m" | tee -a $LOG

  update_operationSystemKernel
  ;;
*)
  echo -e "\033[31m WARN: The submarine assembly Unsupported operating system [${OPERATING_SYSTEM}] \033[0m"
  ;;
esac
}

function get_gcc_version()
{
  local gccVersion=`gcc --version`
  version=${gccVersion%Copyright*}
  echo $version
}

function install_gcc()
{
  echo -n "Do you want to install gcc?[y|n]"
  read myselect
  if [[ "$myselect" = "y" || "$myselect" = "Y" ]]; then
    echo "Execute the yum install gcc make g++ command"
    yum install gcc make g++

    local gccVersion=`gcc --version`
    echo -e "After the install, the gcc version is \e[31m${gccVersion}\e[0m" | tee -a $LOG
  fi
}

function check_gccVersion()
{
  local gccVersionInfo=`gcc --version`
  local gccVersion=${gccVersionInfo%Copyright*}

  if [[ "$gccVersion" = "" ]]; then
    echo "The gcc was not installed on the system. Automated installation ..."
    install_gcc
  else
    echo -e "Submarine gcc version need \033[34mgcc (GCC) 4.8.5 20150623 (Red Hat 4.8.5-11)\033[0m or higher."
    echo -e "Current gcc version was \033[34m${gccVersion}\033[0m"
  fi
}

function check_GPU()
{
  gpuInfo=`lspci | grep -i nvidia`

  if [[ "$gpuInfo" = "" ]]; then
    echo -e "\033[31mWARN: The system did not detect the GPU graphics card.\033[0m"
  else
    echo -e "\033[32mWARN: The system detect the GPU graphics card.\033[0m"
  fi
}

function check_userGroup()
{
  echo -e "check hadoop user group ..."

  echo -e "Hadoop runs the required user [hdfs, mapred, yarn] and groups [hdfs, mapred, yarn, hadoop] installed by ambari."
  echo -e "If you are not using ambari for hadoop installation, 
then you can add the user and group by root by executing the following command:
\033[34madduser hdfs
adduser mapred
adduser yarn
addgroup hadoop
usermod -aG hdfs,hadoop hdfs
usermod -aG mapred,hadoop mapred
usermod -aG yarn,hadoop yarn
usermod -aG hdfs,hadoop hadoop
groupadd docker
usermod -aG docker yarn
usermod -aG docker hadoop\033[0m\n"

  echo -e "check docker user group ..."
  # check user group
  DOCKER_USER_GROUP='docker'
  egrep "^${DOCKER_USER_GROUP}" /etc/group >& /dev/null
  if [[ $? -ne 0 ]]; then
    echo -e "user group ${DOCKER_USER_GROUP} does not exist, Please execute the following command:"
    echo -e "\033[34mgroupadd $DOCKER_USER_GROUP\033[0m"
  fi

  # check user
  USER_GROUP=(yarn hadoop)
  for user in ${USER_GROUP[@]}
  do
    egrep "^${user}" /etc/passwd >& /dev/null
    if [[ $? -ne 0 ]]; then
      echo -e "User ${user} does not exist, Please execute the following command:"
      echo -e "\033[34madduser ${user}\033[0m"
      echo -e "\033[34musermod -aG ${DOCKER_USER_GROUP} ${user}\033[0m"
    fi

    echo -e "Please execute the following command:"
    echo -e "\033[34musermod -aG ${DOCKER_USER_GROUP} ${user}\033[0m"
  done
}

# Some preparatory work for nvidia driver installation
function prepare_nvidia_environment()
{
  echo "prepare nvidia environment ..."

  yum -y update
  yum install kernel-devel-$(uname -r) kernel-headers-$(uname -r)

  yum -y install epel-release
  yum -y install dkms

  echo -e "\033[34m ===== Please manually execute the following command =====
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
\033[0m"
}

