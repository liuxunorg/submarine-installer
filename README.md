## hdp-submarine-assembly

### Hadoop {Submarine} 项目简介

Hadoop {Submarine}  是 hadoop 3.2 版本中最新发布的机器学习框架子项目，它让 hadoop 也能够为数据科学家进行机器学习的算法开发、模型训练和服务发布，提供分布式全功能深度学习框架，易学易用，高效灵活，支持 Tensorflow、MXNet、Caffe、Spark 等多种机器或深度学习框架，结合 hadoop 与身俱来的数据存储和分析能力，更好的挖掘出数据的价值。

### hdp-submarine-assembly 介绍

hadoop 在 2.9 版本中就已经让 YARN 支持了 Docker 的资源调度，Hadoop {Submarine} 在此基础之上让 YARN把分布式深度学习框架通过 Docker 的方式运行起来，由于深度学习框架需要运行在 Docker 的容器之中，并且能够让容器之中的各个服务相互协调完成分布式机器学习的模型训练和模型上线服务，其中就会牵涉到 Docker 、 GPU、网络模型、显卡驱动和操作系统内核修改等众多问题，这需要熟练掌握这些技术的工程师才能够正确的部署好 Hadoop {Submarine}  的运行环境。为了降低部署难度，所以专门开发了 `hdp-submarine-assembly` 这个是用来部署 `Hadoop {Submarine} ` 运行时环境的辅助项目，我们同时还向 hadoop 社区提交了部署 `Hadoop {Submarine} ` 运行时环境的 [中文文档](InstallationGuideChineseVersion.md) 和 [英文文档](InstallationGuide.md) 可以和本项目配套使用。

#### hdp-submarine-assembly 操作说明

使用 hdp-submarine-assembly 进行部署之前，你可以参考 install.conf 文件已有的配置格式，根据你的使用情况进行如下的参数配置：

+ **DNS 配置项**

  LOCAL_DNS_HOST：服务器端本地 DNS IP 地址配置，可以从 /etc/resolv.conf 中查看

  YARN_DNS_HOST：yarn dns server 启动的 ip 地址

+ **ETCD 配置项**

  机器学习是一个计算密度型系统，对数据传输性能要求非常高，所以我们使用了效率损耗最小的 ETCD 网络组件，它可以通过 BGP 路由方式支持 overlay 网络和跨机房时支持隧道模式。

  你需要选择三台以上的服务器作为 ETCD 的运行服务器，这样可以有较好的容错性和稳定性。输入作为 ETCD 服务器的IP数组，参数配置一般是这样：ETCD_HOSTS=(hostIP1 hostIP2 hostIP3)，注意hostIP之间的空格分割。

+ **DOCKER_REGISTRY 配置项**

  你首先需要安装好一个可用的 docker 的镜像管理仓库（这个镜像仓库用来存放你所需要的各种深度学习框架的镜像文件），然后将镜像仓库的 IP 地址和端口配置进来，参数配置一般是这样：DOCKER_REGISTRY="10.120.196.232:5000"

+ **DOWNLOAD_HTTP 配置项**

  `hdp-submarine-assembly` 默认都是从网络上直接下载所有的几百M的依赖包（例如：GCC、Docker、Nvidia 驱动等等），这往往需要消耗大量的时间，并且在有些服务器不能连接互联网的环境中将导致部署失败，所以我们在 `hdp-submarine-assembly` 中内置了 HTTP 下载服务。

  1. 首先，你需要将 `DOWNLOAD_HTTP_IP` 配置为一台能够连接互联网的服务器IP地址，将 `DOWNLOAD_HTTP_PORT` 配置为一个不会被占用的端口地址。
  2. 在  `DOWNLOAD_HTTP_IP` 所在的那台服务器中运行 `hdp-submarine-assembly/install.sh` 命令后，选择 `start download server` 菜单项，`hdp-submarine-assembly` 将会把部署所有的依赖包全部下载到 `hdp-submarine-assembly/downloads` 目录中，然后通过 `python -m SimpleHTTPServer ${DOWNLOAD_HTTP_PORT}`  命令启动一个 HTTP 下载服务。
  3. 在其他服务器中，按照安装菜单依次进行依赖组件的安装时，会自动从 `DOWNLOAD_HTTP_IP` 所在的那台服务器下载依赖包进行离线安装部署。

+ **YARN_CONTAINER_EXECUTOR_PATH 配置项**

  如何编译 YARN 的 container-executor：你进入到 `hadoop/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-server/hadoop-yarn-server-nodemanager` 目录中执行 `mvn package -Pnative -DskipTests`  命令，将会编译出 `./target/native/target/usr/local/bin/container-executor` 文件。
  你需要将 `container-executor` 文件的完整路径填写在 YARN_CONTAINER_EXECUTOR_PATH 配置项中。

+ **YARN_HIERARCHY 配置项**

  请保持和你所使用的 YARN 集群的 yarn-site.xml 配置文件中的 'yarn.nodemanager.linux-container-executor.cgroups.hierarchy' 相同的配置，yarn-site.xml 中如果未配置该项，那么默认为 '/hadoop-yarn'。

+ **YARN_NODEMANAGER_LOCAL_DIRS 配置项**

  请保持和你所使用的 YARN 集群的 yarn-site.xml 配置文件中的 'yarn.nodemanager.local-dirs' 相同的配置。

+ **YARN_NODEMANAGER_LOG_DIRS 配置项**

  请保持和你所使用的 YARN 集群的 yarn-site.xml 配置文件中的 'yarn.nodemanager.log-dirs' 相同的配置。



**Hadoop {Submarine} JIRA**

+ https://issues.apache.org/jira/browse/YARN-8135
+ https://issues.apache.org/jira/browse/YARN-8238
+ https://issues.apache.org/jira/browse/YARN-8488