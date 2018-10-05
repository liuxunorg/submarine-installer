#!/bin/bash
# Author: Xun Liu
# description: sumbarine install scripts.

function install_etcd()
{
  cp ${PACKAGE_DIR}/etcd/etcd /usr/bin
  cp ${PACKAGE_DIR}/etcd/etcdctl /usr/bin
  mkdir -p /var/lib/etcd
  chmod -R a+rw /var/lib/etcd

  cp ${PACKAGE_DIR}/etcd/* ${INSTALL_TEMP_DIR}/

  # config etcd.service

  # 1. 根据本地IP在$ETCD_HOSTS中的位置生成name,替换 ETCD_NODE_NAME_REPLACE
  listIndex ${LOCAL_HOST_IP}
  indexEtcdList=`echo $?`   # get return result
  echo ${indexEtcdList}
  etcdNodeName='etcdnode'+indexEtcdList
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
    initialCluster=${initialCluster}"etcdnode"${index}"=http://"${item}":2380"
    if [[ ${index} -lt ${etcdHostsSize} ]]; then
      initialCluster=${initialCluster}","
    fi
  done
  echo "initialCluster=${initialCluster}"
  sed -i "s/INITIAL_CLUSTER_REPLACE/${initialCluster}/g" $INSTALL_TEMP_DIR/etcd/etcd.service >>$LOG

  cp $INSTALL_TEMP_DIR/etcd/etcd.service /etc/systemd/system/ >>$LOG
}