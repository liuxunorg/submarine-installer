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
  echo "Exit the installation!" | tee -a $LOG
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

function indexByEtcdHosts() {
  index=0
  while [ "$index" -lt "${#ETCD_HOSTS[@]}" ]; do
    if [ "${ETCD_HOSTS[$index]}" = "$1" ]; then
      echo $index
      return
    fi
    let "index++"
  done
  echo ""
}

getLocalIP() {
  local _ip _myip _line _nl=$'\n'
  while IFS=$': \t' read -a _line ;do
      [ -z "${_line%inet}" ] &&
         _ip=${_line[${#_line[1]}>4?1:2]} &&
         [ "${_ip#127.0.0.1}" ] && _myip=$_ip
    done< <(LANG=C /sbin/ifconfig)
  printf ${1+-v} $1 "%s${_nl:0:$[${#1}>0?0:1]}" $_myip
}

get_ip_list()
{
  array=$(ifconfig | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2)

  for ip in ${array[@]}
  do
    LOCAL_HOST_IP_LIST+=(${ip})
  done
}
