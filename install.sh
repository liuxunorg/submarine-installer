# !/bin/bash
# description: sumbarine install scripts.

ROOT=$(cd "$(dirname "$0")"; pwd)
PACKAGE_DIR=${ROOT}/package
SCRIPTS_DIR=${ROOT}/scripts
INSTALL_TEMP_DIR=${ROOT}/temp
DOWNLOAD_DIR=${ROOT}/downloads
DATE=`date +%Y%m%d-%H:%M:%S`
INSTALL_PID_FILE=${ROOT}/install.pid
LOG=${ROOT}/logs/install.log.`date +%Y%m%d%H%M%S`
LOCAL_HOST_IP_LIST=()
LOCAL_HOST_IP=''
OPERATING_SYSTEM=""

# import shell script
. ${ROOT}/install.conf
. ${ROOT}/scripts/calico.sh
. ${ROOT}/scripts/docker.sh
. ${ROOT}/scripts/environment.sh
. ${ROOT}/scripts/etcd.sh
. ${ROOT}/scripts/hadoop.sh
. ${ROOT}/scripts/menu.sh
. ${ROOT}/scripts/nvidia.sh
. ${ROOT}/scripts/nvidia-docker.sh
. ${ROOT}/scripts/submarine.sh
. ${ROOT}/scripts/utils.sh

#=================================Main========================================
mkdir $ROOT/logs/ -p
mkdir $INSTALL_TEMP_DIR -p

source /etc/os-release
OPERATING_SYSTEM=$ID

if [[ -f $INSTALL_PID_FILE ]];then
  echo "无法执行安装程序，$INSTALL_PID_FILE已经存在，安装脚本已经在运行!" | tee -a $LOG
  exit
fi

check_install_conf

get_ip_list
ipCount=${#LOCAL_HOST_IP_LIST[@]}
if [[ $ipCount -eq 1 ]]; then
  LOCAL_HOST_IP = ${LOCAL_HOST_IP_LIST[0]}
  echo -n -e "Please confirm if the IP address of this machine is \e[31m${LOCAL_HOST_IP}\e[0m?[y|n]"
else
  echo -e "This machine has multiple IPs\e[31m[${LOCAL_HOST_IP_LIST[@]}]\e[0m."
  echo -n -e "please enter a valid IP address: "

  read ipInput
  if ! valid_ip $ipInput; then
    echo -e "you input \e[31m$ipInput\e[0m address format is incorrect! " | tee -a $LOG
    exit_install
  else
    LOCAL_HOST_IP=$ipInput
  fi
fi

echo -n -e "Please confirm whether the IP address of this machine is \e[31m${LOCAL_HOST_IP}\e[0m?[y|n]"
read myselect
if [[ "$myselect" != "y" && "$myselect" != "Y" ]]; then
  exit_install
fi

# check_install_user

# 创建安装脚本pid文件
#if [[ ! -f $INSTALL_PID_FILE ]]; then
#  touch $INSTALL_PID_FILE
#fi
#echo $$ > $INSTALL_PID_FILE

# 清理安装临时目录
rm $INSTALL_TEMP_DIR/* -rf >>$LOG 2>&1

if [[ ! -d ${INSTALL_BIN_PATH} ]]; then
  mkdir -p ${INSTALL_BIN_PATH}
fi

menu_index="0"
for ((j=1;;j++))
do
  menu
  case "$menu_index" in 
    "0")
      menu_index="$menu_choice"
    ;;
    "1"|"2"|"3"|"4")
#     echo "aaaa=$menu_index-$menu_choice"
      menu_process
      if [[ $? = 1 ]]; then
        echo "Press any key to return menu!"
        read
      fi
    ;;
    "a") 
      exit_install
      ;; 
    "q") 
      exit_install
      ;;
    *)
      menu_index="0"
      menu_choice="0"
      menu
    ;;
  esac  
done
