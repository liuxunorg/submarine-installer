#!/bin/bash

function start_download_server()
{
  if [[ "$DOWNLOAD_HTTP_IP" != "$LOCAL_HOST_IP" ]]; then
    echo -e "\033[31mERROR: Only $DOWNLOAD_HTTP_IP can start the download service.\033[0m"
    return 1
  fi

  echo -e "You can put the install package file in the \033[34m${DOWNLOAD_DIR}\033[0m folder first, Or automatic download."
  echo -n "Do you want to start download http server?[y|n]"
  read myselect
  if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
  then
    download_etcd_bin
    download_calico_bin
#    download_docker_rpm
#    download_nvidia_driver
#    download_nvidia_docker_bin
#    download_yarn_container_executor

    python -m SimpleHTTPServer ${DOWNLOAD_HTTP_PORT}
  fi
}
