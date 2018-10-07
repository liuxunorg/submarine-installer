#!/bin/bash
. ${ROOT}/scripts/docker.sh

function install_calico()
{
  kernel_network_config
  install_calico_bin
  install_calico_config
  verification_calico
}

function install_calico_bin()
{
  wget -O /usr/local/bin/calicoctl ${CALICOCTL_DOWNLOAD_URL}
  chmod +x /usr/local/bin/calicoctl
  mkdir /var/lib/calico
  wget -O /var/lib/calico/calico ${CALICO_DOWNLOAD_URL}
  wget -O /var/lib/calico/calico-ipam ${CALICO_IPAM_DOWNLOAD_URL}
  chmod +x /var/lib/calico/calico
  chmod +x/var/lib/calico/calico-ipam
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
    etcdEndpoints="${etcdEndpoints}http://${item}:2379"
    if [[ ${index} -lt ${etcdHostsSize} ]]; then
      etcdEndpoints=${etcdEndpoints}","
    fi
  done
  echo "etcdEndpoints=${etcdEndpoints}"
  sed -i "s/ETCD_ENDPOINTS_REPLACE/${etcdEndpoints}/g" $INSTALL_TEMP_DIR/calico/calicoctl.cfg >>$LOG

  sed -i "s/ETCD_ENDPOINTS_REPLACE/${etcdEndpoints}/g" $INSTALL_TEMP_DIR/calico/calico-node.service >>$LOG

  sed -i "s/CALICO_IPV4POOL_CIDR_REPLACE/${CALICO_IPV4POOL_CIDR}/g" $INSTALL_TEMP_DIR/calico/calico-node.service >>$LOG

  systemctl daemon-reload
  systemctl enable calico-node.service
  systemctl start calico-node.service
}

function kernel_network_config()
{
  if [ `grep -c "net.ipv4.conf.all.rp_filter=1" /etc/sysctl.conf` -eq '0' ]; then
    echo "net.ipv4.conf.all.rp_filter=1">> /etc/sysctl.conf
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
  echo " ===== Check the status of the calico ====="
  echo "Show the all host status in the cluster except localhost.
        Calico process is running.
        IPv4 BGP status
        +---------------+-------------------+-------+------------+-------------+
        | PEER ADDRESS  |     PEER TYPE     | STATE |   SINCE    |    INFO     |
        +---------------+-------------------+-------+------------+-------------+
        | host_ip1      | node-to-node mesh | up    | 2018-09-21 | Established |
        | host_ip2      | node-to-node mesh | up    | 2018-09-21 | Established |
        | host_ip3      | node-to-node mesh | up    | 2018-09-21 | Established |
        +---------------+-------------------+-------+------------+-------------+
        "
  calicoctl node status

  echo " ===== Check if the network between 2 containers can be connected ====="
  local claicoNetworkExist=`claico_network_exist`
  if [[ "$claicoNetworkExist" = "" ]]; then
    echo "Create a calico network"
    docker network create --driver calico --ipam-driver calico-ipam ${CALICO_NETWORK_NAME}
  else
    echo "calico network ${CALICO_NETWORK_NAME} exist."
  fi

  local verifyA="verify-calico-network-A"
  local verifyAInfo=`containers_exist ${verifyA}`
  if [[ "$verifyAInfo" = "" ]]; then
    echo "Create containers verify-calico-network-A"
    docker run --net ${CALICO_NETWORK_NAME} --name ${verifyA} -tid busybox
  else
    echo "containers ${verifyA} exist."
  fi

  local verifyB="verify-calico-network-B"
  local verifyBInfo=`containers_exist ${verifyB}`
  if [[ "$verifyBInfo" = "" ]]; then
    echo "Create containers verify-calico-network-B"
    docker run --net ${CALICO_NETWORK_NAME} --name ${verifyB} -tid busybox
  else
    echo "containers ${verifyB} exist."
  fi

  echo "${verifyA} ping ${verifyB}"
  docker exec ${verifyA} ping ${verifyB}  
}
