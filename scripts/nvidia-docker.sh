#!/bin/bash

. ${ROOT}/scripts/nvidia.sh


function install_nvidia_docker()
{
  # download nvidia-docker
  wget -P ${INSTALL_TEMP_DIR} ${NVIDIA_DOCKER_ENGINE_SELINUX_RPM}
  
  sudo rpm -i ${INSTALL_TEMP_DIR}/nvidia-docker*.rpm

  echo "===== Start nvidia-docker ====="
  sudo systemctl start nvidia-docker

  echo "===== Check nvidia-docker status ====="
  systemctl status nvidia-docker

  echo "===== Check nvidia-docker log ====="
  journalctl -u nvidia-docker

  echo "===== Test nvidia-docker-plugin ====="
  curl http://localhost:3476/v1.0/docker/cli

  # create nvidia driver library path
  if [ ! -d "/var/lib/nvidia-docker/volumes/nvidia_driver" ]; then
    echo "WARN: /var/lib/nvidia-docker/volumes/nvidia_driver folder path is not exist!"
    mkdir -p /var/lib/nvidia-docker/volumes/nvidia_driver
  fi

  local nvidiaVersion=`get_nvidia_version`

  mkdir /var/lib/nvidia-docker/volumes/nvidia_driver/${nvidiaVersion}
  # 390.8 is nvidia driver version

  mkdir /var/lib/nvidia-docker/volumes/nvidia_driver/${nvidiaVersion}/bin
  mkdir /var/lib/nvidia-docker/volumes/nvidia_driver/${nvidiaVersion}/lib64

  cp /usr/bin/nvidia* /var/lib/nvidia-docker/volumes/nvidia_driver/${nvidiaVersion}/bin
  cp /usr/lib64/libcuda* /var/lib/nvidia-docker/volumes/nvidia_driver/${nvidiaVersion}/lib64
  cp /usr/lib64/libnvidia* /var/lib/nvidia-docker/volumes/nvidia_driver/${nvidiaVersion}/lib64

  echo " ===== After the installation is complete, execute NVIDIA-SMI, you should see the list of graphics cards ===== "
  echo "+-----------------------------------------------------------------------------+
        | NVIDIA-SMI 390.87                 Driver Version: 390.87                    |
        |-------------------------------+----------------------+----------------------+
        | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
        | Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
        |===============================+======================+======================|
        |   0  GeForce GTX 108...  Off  | 00000000:04:00.0 Off |                  N/A |
        | 23%   28C    P8    15W / 250W |     10MiB / 11178MiB |      0%      Default |
        +-------------------------------+----------------------+----------------------+
        +-----------------------------------------------------------------------------+
        | Processes:                                                       GPU Memory |
        |  GPU       PID   Type   Process name                             Usage      |
        |=============================================================================|
        |  No running processes found                                                 |
        +-----------------------------------------------------------------------------+
  "
  echo "===== If you don't see the list of graphics cards above, the NVIDIA driver installation failed. ====="
  nvidia-docker pull nvidia/cuda:9.0-devel
  nvidia-docker run --rm nvidia/cuda:9.0-devel nvidia-smi

  echo "===== Please manually execute the following command ====="
  echo "
        # Test with tf.test.is_gpu_available()
        shell:> nvidia-docker run -it tensorflow/tensorflow:1.9.0-gpu bash
        # In docker container
        container:> python
        python:> import tensorflow as tf
        python:> tf.test.is_gpu_available()
        python:> exit()
        "
}
