#!/bin/bash

function check_operationSystem()
{
  local operationSystemVersion=`rpm --query centos-release`

  echo -e "$BASH_SOURCE:$LINENO The submarine installation script verifies minimum version of the operating system version is \033[32m centos-release-7-3.1611.el7.centos.x86_64 \033[0m"
  echo -e "$BASH_SOURCE:$LINENO The operating system version of the ${LOCAL_HOST_IP} is \e[31m${operationSystemVersion}\e[0m" | tee -a $LOG

  read -n2 -p "Do you want to continue installer [Y/N]?" answer
  case $answer in
  (Y | y)
        echo "Continue the installer";;
  (N | n)
        echo "Exit the installer";;
        exit_install
  (*)
        echo "error choice";;
  esac
}

function check_operationSystemKernel()
{
  local KernelVersion=`uname -r`

  echo -e "$BASH_SOURCE:$LINENO The submarine installation script verifies minimum version of the operating system kernel version is \033[32m 3.10.0-514.el7.x86_64 \033[0m"
  echo -e "$BASH_SOURCE:$LINENO The operating system kernel version of the ${LOCAL_HOST_IP} is \e[31m${operationSystemVersion}\e[0m" | tee -a $LOG

  read -n2 -p "Do you want to update the kernel [Y/N]?" answer
  case $answer in
  (Y | y)
        echo "If the server is unable to connect to the network, execute the following command yourself:
              wget http://vault.centos.org/7.3.1611/os/x86_64/Packages/kernel-headers-3.10.0-514.el7.x86_64.rpm
              rpm -ivh kernel-headers-3.10.0-514.el7.x86_64.rpm";;
        echo "Now try to use the yum command for kernel upgrades ...";;
        yum install kernel-devel-$(uname -r) kernel-headers-$(uname -r)
  (N | n)
        echo "Exit the installer";;
        exit_install
  (*)
        echo "error choice";;
  esac
}

function check_gccVersion()
{
  gccVersion=`gcc --version`

  if [ "$gccVersion" = "" ]
  then
    echo "The gcc was not installed on the system. Automated installation ..."
    yum install gcc make g++
  else
    echo "Submarine runtime environment must use [gcc (GCC) 4.8.5 20150623 (Red Hat 4.8.5-11)] or higher."
    echo "The original gcc version was: ${gccVersion}"
  fi
}

function check_GPU()
{
  gpuInfo=`lspci | grep -i nvidia`

  if [ "$gpuInfo" = "" ]
  then
    echo "The system did not detect the GPU graphics card."

    read -n2 -p "Do you want to continue install [Y/N]?" answer
    case $answer in
    (Y | y)
          ;;
    (N | n)
          echo "Exit the installer";;
          exit_install
    (*)
          echo "error choice";;
    esac
  fi
}

function check_userGroup()
{
  echo -e "$BASH_SOURCE:$LINENO check hadoop user group ..."

  echo -e "$BASH_SOURCE:$LINENO The submarine installation script only checks \033[32m docker \033[0m user group."
  echo -e "$BASH_SOURCE:$LINENO Hadoop runs the required user [hdfs, mapred, yarn] and groups [hdfs, mapred, yarn, hadoop] installed by ambari."
  echo -e "$BASH_SOURCE:$LINENO If you are not using ambari for hadoop installation, 
                                then you can install the user and user group by root by executing the following statement.
                                root:> adduser hdfs
                                root:> adduser mapred 
                                root:> adduser yarn 
                                root:> addgroup hadoop
                                root:> usermod -aG hdfs,hadoop hdfs
                                root:> usermod -aG mapred,hadoop mapred
                                root:> usermod -aG yarn,hadoop yarn
                                root:> usermod -aG hdfs,hadoop hadoop
                                root:> groupadd docker
                                root:> usermod -aG docker yarn
                                root:> usermod -aG docker hadoop"

  echo -e "$BASH_SOURCE:$LINENO check docker user group ..."
  # check user group
  DOCKER_USER_GROUP='docker'
  egrep "^${DOCKER_USER_GROUP}" /etc/group >& /dev/null
  if [ $? -ne 0 ]
  then
    echo -e "$BASH_SOURCE:$LINENO add group ${DOCKER_USER_GROUP} ..."
    groupadd $DOCKER_USER_GROUP
  fi

  # check user
  USER_GROUP=(yarn hadoop)
  for user in ${USER_GROUP[@]}
  do
    egrep "^${user}" /etc/passwd >& /dev/null
    if [ $? -ne 0 ]
    then
      echo -e "$BASH_SOURCE:$LINENO User ${user} does not exist, Automatically add user ${user}."
      adduser ${user}
    fi

    echo -e "$BASH_SOURCE:$LINENO Automatically add user ${user} to user group ${DOCKER_USER_GROUP}."
    usermod -aG ${DOCKER_USER_GROUP} ${user}
  done
}


