# !/bin/bash
# description: sumbarine install scripts.

ROOT=$(cd "$(dirname "$0")"; pwd)
PACKAGE_DIR=${ROOT}/package
SCRIPTS_DIR=${ROOT}/scripts
INSTALL_TEMP_DIR=${ROOT}/temp
DATE=`date +%Y%m%d-%H:%M:%S`
INSTALL_PID_FILE=${ROOT}/install.pid
LOG=${ROOT}/logs/install.log.`date +%Y%m%d%H%M%S`
LOCAL_HOST_IP=''

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
echo "###############################################################"
echo "#                   submarine assembly                        #"
echo "#                   Version: 1.0                              #"
echo "#                   Release date: September 20, 2018          #"
echo "###############################################################"

if [[ -f $INSTALL_PID_FILE ]];then
  echo "无法执行安装程序，$INSTALL_PID_FILE已经存在，安装脚本已经在运行!" | tee -a $LOG
  exit
fi

echo "count="$#

if [ $# -ne 1 ];then
  echo -ne "Usag: $0 \e[31m localhost_ip\e[0m\n"
  exit 0
fi

check_install_conf

LOCAL_HOST_IP=$2
echo "local host ip:${LOCAL_HOST_IP}"

# check_install_user

# 创建安装脚本pid文件
if [[ ! -f $INSTALL_PID_FILE ]]; then
  touch $INSTALL_PID_FILE
fi
echo $$ > $INSTALL_PID_FILE

# 清理安装临时目录
rm $INSTALL_TEMP_DIR/* -rf >>$LOG 2>&1

menu_index="0"
for ((j=1;;j++))
do
  menu
  case "$menu_index" in 
    "0")
      menu_index="$menu_choice"
    ;;
    "1"|"2"|"3"|"4"|"5"|"6")
#     echo "aaaa=$menu_index-$menu_choice"
      menu_process
      if [[ $? = 1 ]]; then
        echo "Press any key to return!"
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
