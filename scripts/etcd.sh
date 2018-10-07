#!/bin/bash

function install_etcd_bin()
{
  # install etcd bin
  wget -P ${INSTALL_TEMP_DIR} ${ETCD_DOWNLOAD_URL}
  tar zxvf ${ETCD_TAR_GZ} -C ./etcd
  cp ./etcd/etcd /usr/bin
  cp ./etcd/etcdctl /usr/bin
  mkdir -p /var/lib/etcd
  chmod -R a+rw /var/lib/etcd
}

function install_etcd_config()
{
  # config etcd.service
  cp -R ${PACKAGE_DIR}/etcd ${INSTALL_TEMP_DIR}/

  # 1. 根据本地IP在$ETCD_HOSTS中的位置生成name,替换 ETCD_NODE_NAME_REPLACE
  listIndex ${LOCAL_HOST_IP} ${#ETCD_HOSTS[@]}
  indexEtcdList=`echo $?`   # get return result
  echo ${indexEtcdList}
  etcdNodeName='etcdnode'+${indexEtcdList}
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
    index=$(($index+1))
    initialCluster="${initialCluster}etcdnode${index}=http://${item}:2380"
    if [[ ${index} -lt ${etcdHostsSize} ]]; then
      initialCluster=${initialCluster}","
    fi
  done
  echo "initialCluster=${initialCluster}"
  sed -i "s/INITIAL_CLUSTER_REPLACE/${initialCluster}/g" $INSTALL_TEMP_DIR/etcd/etcd.service >>$LOG

  cp $INSTALL_TEMP_DIR/etcd/etcd.service /etc/systemd/system/ >>$LOG
}

function install_etcd()
{
  install_etcd_bin

  install_etcd_config

  # start etcd
  systemctl daemon-reload
  systemctl enable etcd.service
  systemctl start etcd.service

  # Test
  echo " ===== Please manually execute the following command ====="
  echo "
        $ etcdctl cluster-health
        member 3adf2673436aa824 is healthy: got healthy result from http://etcd_host_ip1:2379
        member 85ffe9aafb7745cc is healthy: got healthy result from http://etcd_host_ip2:2379
        member b3d05464c356441a is healthy: got healthy result from http://etcd_host_ip3:2379
        cluster is healthy

        $ etcdctl member list
        3adf2673436aa824: name=etcdnode3 peerURLs=http://etcd_host_ip1:2380 clientURLs=http://etcd_host_ip1:2379 isLeader=false
        85ffe9aafb7745cc: name=etcdnode2 peerURLs=http://etcd_host_ip2:2380 clientURLs=http://etcd_host_ip2:2379 isLeader=false
        b3d05464c356441a: name=etcdnode1 peerURLs=http://etcd_host_ip3:2380 clientURLs=http://etcd_host_ip3:2379 isLeader=true
  "
}
