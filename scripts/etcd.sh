#!/bin/bash

function install_etcd_bin()
{
  if [[ -f ${DOWNLOAD_DIR}/${ETCD_TAR_GZ} ]]; then
    echo "${DOWNLOAD_DIR}/${ETCD_TAR_GZ} is exist."
  else
    echo "download ${DOWNLOAD_DIR}/${ETCD_TAR_GZ} ..."
    wget -P ${DOWNLOAD_DIR} ${ETCD_DOWNLOAD_URL}
  fi

  # install etcd bin
  mkdir -p ${INSTALL_TEMP_DIR}
  rm -rf ${INSTALL_TEMP_DIR}/etcd-*-linux-amd6
  tar zxvf ${DOWNLOAD_DIR}/${ETCD_TAR_GZ} -C ${INSTALL_TEMP_DIR}

  cp ${INSTALL_TEMP_DIR}/etcd-*-linux-amd64/etcd ${INSTALL_BIN_PATH}
  cp ${INSTALL_TEMP_DIR}/etcd-*-linux-amd64/etcdctl ${INSTALL_BIN_PATH}

  mkdir -p /var/lib/etcd
  chmod -R a+rw /var/lib/etcd
}

function install_etcd_config()
{
  # config etcd.service
  rm -rf ${INSTALL_TEMP_DIR}/etcd
  cp -R ${PACKAGE_DIR}/etcd ${INSTALL_TEMP_DIR}/

  # 1. 根据本地IP在$ETCD_HOSTS中的位置生成name,替换 ETCD_NODE_NAME_REPLACE
  indexEtcdList=$(indexByEtcdHosts ${LOCAL_HOST_IP})
  echo ${indexEtcdList}
  etcdNodeName="etcdnode${indexEtcdList}"
  echo ${etcdNodeName}
  sed -i "s/ETCD_NODE_NAME_REPLACE/${etcdNodeName}/g" $INSTALL_TEMP_DIR/etcd/etcd.service >>$LOG
  
  # 2. 替换本地IP地址
  sed -i "s/LOCAL_HOST_REPLACE/${LOCAL_HOST_IP}/g" $INSTALL_TEMP_DIR/etcd/etcd.service >>$LOG

  # 3. 替换 initial-cluster 参数
  # --initial-cluster=etcdnode1=http://10.196.69.173:2380,etcdnode2=http://10.196.69.174:2380,etcdnode3=http://10.196.69.175:2380 \
  initialCluster=''
  index=0
  etcdHostsSize=${#ETCD_HOSTS[@]}
  for item in ${ETCD_HOSTS[@]}
  do
    # char '/' need to escape '\/'
    initialCluster="${initialCluster}etcdnode${index}=http:\/\/${item}:2380"
    if [[ ${index} -lt ${etcdHostsSize} ]]; then
      initialCluster=${initialCluster}","
    fi
    index=$(($index+1))
  done
  echo "initialCluster=${initialCluster}"
  sed -i "s/INITIAL_CLUSTER_REPLACE/${initialCluster}/g" $INSTALL_TEMP_DIR/etcd/etcd.service >>$LOG

  cp $INSTALL_TEMP_DIR/etcd/etcd.service /etc/systemd/system/ >>$LOG
}

function install_etcd()
{
  index=$(indexByEtcdHosts ${LOCAL_HOST_IP})
  if [ -z "$index" ]; then
    echo -e "STOP: This host\033[31m[${LOCAL_HOST_IP}]\033[0m is not in the ETCD server list\033[31m[${ETCD_HOSTS[@]}]\033[0m"
    return 1
  fi
  
  install_etcd_bin

  install_etcd_config

  systemctl daemon-reload
  systemctl enable etcd.service
}

function uninstall_etcd()
{
  systemctl stop etcd.service

  rm /usr/bin/etcd
  rm /usr/bin/etcdctl
  rm -rf /var/lib/etcd
  rm /etc/systemd/system/etcd.service
}

function start_etcd()
{
  systemctl restart etcd.service

  echo " ===== Check the status of the etcd service, You should see the following output ====="
  echo -e "
$ etcdctl cluster-health
\033[34mmember 3adf2673436aa824 is healthy: got healthy result from http://etcd_host_ip1:2379
member 85ffe9aafb7745cc is healthy: got healthy result from http://etcd_host_ip2:2379
member b3d05464c356441a is healthy: got healthy result from http://etcd_host_ip3:2379\033[0m
cluster is healthy"

  sleep 1
  etcdctl cluster-health

  echo -e "
$ etcdctl member list
\033[34m3adf2673436aa824: name=etcdnode3 peerURLs=http://etcd_host_ip1:2380 clientURLs=http://etcd_host_ip1:2379 isLeader=false
85ffe9aafb7745cc: name=etcdnode2 peerURLs=http://etcd_host_ip2:2380 clientURLs=http://etcd_host_ip2:2379 isLeader=false
b3d05464c356441a: name=etcdnode1 peerURLs=http://etcd_host_ip3:2380 clientURLs=http://etcd_host_ip3:2379 isLeader=true\033[0m"

  sleep 1
  etcdctl member list
}

function stop_etcd()
{
  systemctl stop etcd.service
}
