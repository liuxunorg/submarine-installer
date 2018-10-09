#!/bin/bash

function download_calico_bin()
{
  # submarin http server
  if [[ -n "$DOWNLOAD_HTTP" ]]; then
    MY_CALICOCTL_DOWNLOAD_URL=${DOWNLOAD_HTTP}/downloads/calico/calicoctl
    MY_CALICO_DOWNLOAD_URL=${DOWNLOAD_HTTP}/downloads/calico/calico
    MY_CALICO_IPAM_DOWNLOAD_URL=${DOWNLOAD_HTTP}/downloads/calico/calico-ipam
  else
    MY_CALICOCTL_DOWNLOAD_URL=${CALICOCTL_DOWNLOAD_URL}
    MY_CALICO_DOWNLOAD_URL=${CALICO_DOWNLOAD_URL}
    MY_CALICO_IPAM_DOWNLOAD_URL=${CALICO_IPAM_DOWNLOAD_URL}
  fi

  mkdir -p ${DOWNLOAD_DIR}/calico

  if [[ -f ${DOWNLOAD_DIR}/calico/calico ]]; then
    echo "${DOWNLOAD_DIR}/calico/calico is exist."
  else
    echo "download ${MY_CALICO_DOWNLOAD_URL} ..."
    wget -P ${DOWNLOAD_DIR}/calico ${MY_CALICO_DOWNLOAD_URL}
  fi

  if [[ -f ${DOWNLOAD_DIR}/calico/calicoctl ]]; then
    echo "${DOWNLOAD_DIR}/calico is exist."
  else
    echo "download ${MY_CALICOCTL_DOWNLOAD_URL} ..."
    wget -P ${DOWNLOAD_DIR}/calico ${MY_CALICOCTL_DOWNLOAD_URL}
  fi

  if [[ -f ${DOWNLOAD_DIR}/calico/calico-ipam ]]; then
    echo "${DOWNLOAD_DIR}/calico/calico-ipam is exist."
  else
    echo "download ${MY_CALICO_IPAM_DOWNLOAD_URL} ..."
    wget -P ${DOWNLOAD_DIR}/calico ${MY_CALICO_IPAM_DOWNLOAD_URL}
  fi
}

function install_calico_bin()
{
  download_calico_bin

  cp ${DOWNLOAD_DIR}/calico/calico /usr/bin/calico
  cp ${DOWNLOAD_DIR}/calico/calicoctl /usr/bin/calicoctl
  cp ${DOWNLOAD_DIR}/calico/calico-ipam /usr/bin/calico-ipam

  chmod +x /usr/bin/calico
  chmod +x /usr/bin/calicoctl
  chmod +x /usr/bin/calico-ipam
}

# TODO: check https or http?
function install_calico_config()
{
  mkdir -p /etc/calico

  cp -R ${PACKAGE_DIR}/calico ${INSTALL_TEMP_DIR}/

  # 1. 替换 etcdEndpoints 参数
  # etcdEndpoints: https://10.196.69.173:2379,https://10.196.69.174:2379,https://10.196.69.175:2379
  etcdEndpoints=''
  index=0
  etcdHostsSize=${#ETCD_HOSTS[@]}
  for item in ${ETCD_HOSTS[@]}
  do
    index=$(($index+1))
    etcdEndpoints="${etcdEndpoints}http:\/\/${item}:2379"
    if [[ ${index} -lt ${etcdHostsSize} ]]; then
      etcdEndpoints=${etcdEndpoints}","
    fi
  done
  # echo "etcdEndpoints=${etcdEndpoints}"
  sed -i "s/ETCD_ENDPOINTS_REPLACE/${etcdEndpoints}/g" $INSTALL_TEMP_DIR/calico/calicoctl.cfg >>$LOG

  if [[ ! -d /etc/calico ]]; then
    mkdir /etc/calico
  else
    rm -rf /etc/calico/*
  fi

  cp $INSTALL_TEMP_DIR/calico/calicoctl.cfg /etc/calico/calicoctl.cfg

  sed -i "s/ETCD_ENDPOINTS_REPLACE/${etcdEndpoints}/g" $INSTALL_TEMP_DIR/calico/calico-node.service >>$LOG
  sed -i "s/CALICO_IPV4POOL_CIDR_REPLACE/${CALICO_IPV4POOL_CIDR}/g" $INSTALL_TEMP_DIR/calico/calico-node.service >>$LOG
  cp $INSTALL_TEMP_DIR/calico/calico-node.service /etc/systemd/system/ >>$LOG

  systemctl daemon-reload
  systemctl enable calico-node.service
}

function kernel_network_config()
{
  if [ `grep -c "net.ipv4.conf.all.rp_filter=1" /etc/sysctl.conf` -eq '0' ]; then
    echo "net.ipv4.conf.all.rp_filter=1" >>/etc/sysctl.conf
  fi

  if [ `grep -c "net.ipv4.ip_forward=1" /etc/sysctl.conf` -eq '0' ]; then
    echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf
  fi

  sysctl -p
}

function claico_network_exist()
{
  local dockerNetwokInfo=`docker network ls --filter NAME=${CALICO_NETWORK_NAME}`
  echo ${dockerNetwokInfo} | grep ${CALICO_NETWORK_NAME}
}

function verification_calico()
{
  echo " ===== Check if the network between 2 containers can be connected ====="
  local claicoNetworkExist=`claico_network_exist`
  if [[ "$claicoNetworkExist" = "" ]]; then
    echo "Create a calico network"
    docker network create --driver calico --ipam-driver calico-ipam ${CALICO_NETWORK_NAME}
  else
    echo "calico network ${CALICO_NETWORK_NAME} is exist."
  fi

  local verifyA="verify-calico-network-A"
  local verifyAInfo=`containers_exist ${verifyA}`
  if [[ -n "$verifyAInfo" ]]; then
    echo "Delete existing container ${verifyA}."
    docker stop ${verifyA}
    docker rm ${verifyA}
  fi
  echo "Create containers verify-calico-network-A"
  docker run --net ${CALICO_NETWORK_NAME} --name ${verifyA} -tid busybox

  local verifyB="verify-calico-network-B"
  local verifyBInfo=`containers_exist ${verifyB}`
  if [[ -n "$verifyBInfo" ]]; then
    echo "Delete existing container ${verifyB}."
    docker stop ${verifyB}
    docker rm ${verifyB}
  fi
  echo "Create containers verify-calico-network-B"
  docker run --net ${CALICO_NETWORK_NAME} --name ${verifyB} -tid busybox

  echo -e "\033[33m${verifyA} ping ${verifyB}\033[0m"
  docker exec ${verifyA} ping ${verifyB} -c 5
}

function install_calico()
{
  kernel_network_config
  install_calico_bin
  install_calico_config
  start_calico
  verification_calico
}

function uninstall_calico()
{
  echo "stop calico-node.service"
  systemctl stop calico-node.service

  echo "rm /usr/bin/calico ..."
  rm /usr/bin/calicoctl
  rm /usr/bin/calico
  rm /usr/bin/calico-ipam

  rm -rf /etc/calico/
  rm /etc/systemd/system/calico-node.service
  systemctl daemon-reload
}

function start_calico()
{
  systemctl restart calico-node.service
  systemctl status calico-node.service
}

function stop_calico()
{
  systemctl stop calico-node.service
  systemctl status calico-node.service
}

