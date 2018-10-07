# !/bin/bash
# description: sumbarine install scripts.

ROOT=$(cd "$(dirname "$0")"; pwd)/..
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
. ${ROOT}/scripts/nvidia.sh
. ${ROOT}/scripts/nvidia-docker.sh
. ${ROOT}/scripts/submarine.sh
. ${ROOT}/scripts/utils.sh

#=================================Main========================================
echo "###############################################################"
echo "#                   submarine 运行环境安装脚本                   #"
echo "#                   Version: 1.0                              #"
echo "#                   发布日期: 2018年9月20日                      #"
echo "###############################################################"

if [[ -f $INSTALL_PID_FILE ]];then
  echo "无法执行安装程序，$INSTALL_PID_FILE已经存在，安装脚本已经在运行!" | tee -a $LOG
  exit
fi

if [ $# -ne 3 ];then
  echo -ne "Usag: $0 \e[31m-f install.conf -i localhost_ip\e[0m\n"
  exit 0
fi

while getopts "f:i:" arg
do 
  case $arg in
    f)
    if [[ ! -f $OPTARG ]]; then
      echo "$OPTARG不存在！"
      exit
    fi
    INSTALL_CONF_FILE=$OPTARG
    . $OPTARG
    check_install_conf
    ;;
    i)
    LOCAL_HOST_IP=$OPTARG
    echo "local host ip:$LOCAL_HOST_IP"
    ;;
    ?)
    echo -ne "Usag: $0 \e[31m-f install.conf -i localhost_ip\e[0m\n"
    exit 1 
    ;;
  esac
done

check_install_user

# 创建安装脚本pid文件
if [[ ! -f $INSTALL_PID_FILE ]]; then
  touch $INSTALL_PID_FILE
fi
echo $$ > $INSTALL_PID_FILE

# 清理安装临时目录
rm $INSTALL_TEMP_DIR/* -rf >>$LOG 2>&1

