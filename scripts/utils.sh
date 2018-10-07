# !/bin/bash

function check_install_user()
{
  if [[ $(id -u) -ne 0 ]];then
    echo "必须使用 ROOT 用户运行此脚本!"
    exit # don't call exit_install()
  fi
}

function exit_install()
{
  echo "\n退出安装!" | tee -a $LOG
  rm $INSTALL_PID_FILE
  exit $1
}

# 检查IP地址格式是否正确
function valid_ip()
{
  local ip=$1
  local stat=1

  if [[ $ip =~ ^[0-9]{1,3\}.[0-9]{1,3\}.[0-9]{1,3\}.[0-9]{1,3\}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip)
    IFS=$OIFS

    if [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]; then
      stat=$?
    fi
  fi

  return $stat
}

# 检查配置文件配置是否正确
function check_install_conf()
{
  echo "$BASH_SOURCE:$LINENO 检查配置文件配置是否正确 ..." | tee -a $LOG

  # check etcd conf
  hostCount=${#ETCD_HOSTS[@]}
  if [[ $hostCount -lt 3 && hostCount -ne 0 ]]; then # <>2
    echo "$BASH_SOURCE:$LINENO ETCD_HOSTS 节点数=[$hostCount],必须配置大于等于3台服务器! " | tee -a $LOG
    exit_install
  fi
  for ip in ${ETCD_HOSTS[@]}
  do
    if ! valid_ip $ip; then
      echo "$BASH_SOURCE:$LINENO ETCD_HOSTS=[$ip],IP地址格式不正确! " | tee -a $LOG
      exit_install
    fi
  done
  echo "$BASH_SOURCE:$LINENO 检查配置文件配置是否正确 [ Done ]" | tee -a $LOG
}

# listIndex 'abc' array
function listIndex() 
{
  int index=0
	for item in $2
  do
    if [ "$item" = "$1" ];then
      return $index
    fi
    index=$(($index+1))
  done

  return -1
}

function exit_install()
{
  echo "\n退出安装!" | tee -a $LOG
  rm $INSTALL_PID_FILE
  exit $1
}
