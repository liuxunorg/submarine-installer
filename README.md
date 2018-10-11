## hdp-submarine-assembly

### 项目介绍

介绍 hdp-submarine-assembly 项目之前，首先要说明一下 Hadoop {Submarine}  这个项目，Hadoop {Submarine}  是 hadoop 3.2 版本中最新发布的机器学习框架子项目，他让 hadoop 支持 Tensorflow、MXNet、Caffe、Spark 等多种深度学习框架，提供了机器学习算法开发、分布式模型训练、模型管理和模型发布等全功能的系统框架，结合 hadoop 与身俱来的数据存储和数据处理能力，让数据科学家们能够更好的挖掘和发挥出数据的价值。

hadoop 在 2.9 版本中就已经让 YARN 支持了 Docker 容器的资源调度模式，Hadoop {Submarine} 在此基础之上通过 YARN 把分布式深度学习框架以 Docker 容器的方式进行调度和运行起来。

由于分布式深度学习框架需要运行在多个 Docker 的容器之中，并且需要能够让运行在容器之中的各个服务相互协调，完成分布式机器学习的模型训练和模型发布等服务，这其中就会牵涉到 DNS、Docker 、 GPU、Network、显卡、操作系统内核修改等多个系统工程问题，正确的部署好 Hadoop {Submarine}  的运行环境是一件很困难和耗时的事情。

为了降低 hadoop 2.9 以上版本的 docker 等组件的部署难度，所以我们专门开发了这个用来部署 `Hadoop {Submarine} ` 运行时环境的 `hdp-submarine-assembly` 项目，提供一键安装脚本，也可以分步执行安装、卸载、启动和停止各个组件，同时讲解每一步主要参数配置和注意事项。我们同时还向 hadoop 社区提交了部署 `Hadoop {Submarine} ` 运行时环境的 [中文手册](https://github.com/apache/hadoop/blob/trunk/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-applications/hadoop-yarn-submarine/src/site/markdown/InstallationGuideChineseVersion.md) 和 [英文手册](https://github.com/apache/hadoop/blob/trunk/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-applications/hadoop-yarn-submarine/src/site/markdown/InstallationGuide.md) ，帮助用户更容易的部署，发现问题也可以及时解决。

### 先决条件

**hdp-submarine-assembly** 目前只支持 centos-release-7-3.1611.el7.centos.x86_64 以上版本的操作系统中进行使用。

### 配置说明

使用 **hdp-submarine-assembly** 进行部署之前，你可以参考 [install.conf](install.conf) 文件中已有的配置参数和格式，根据你的使用情况进行如下的参数配置：

+ **DNS 配置项**

  LOCAL_DNS_HOST：服务器端本地 DNS IP 地址配置，可以从 /etc/resolv.conf 中查看

  YARN_DNS_HOST：yarn dns server 启动的 IP 地址

+ **ETCD 配置项**

  机器学习是一个计算密度型系统，对数据传输性能要求非常高，所以我们使用了网络效率损耗最小的 ETCD 网络组件，它可以通过 BGP 路由方式支持 overlay 网络，同时在跨机房部署时支持隧道模式。

  你需要选择至少三台以上的服务器作为 ETCD 的运行服务器，这样可以让 `Hadoop {Submarine} ` 有较好的容错性和稳定性。

  在 ETCD_HOSTS 配置项中输入作为 ETCD 服务器的IP数组，参数配置一般是这样：

  ETCD_HOSTS=(hostIP1 hostIP2 hostIP3)，注意多个 hostIP 之间请使用空格进行隔开。

+ **DOCKER_REGISTRY 配置项**

  你首先需要安装好一个可用的 docker 的镜像管理仓库，这个镜像仓库用来存放你所需要的各种深度学习框架的镜像文件，然后将镜像仓库的 IP 地址和端口配置进来，参数配置一般是这样：DOCKER_REGISTRY="10.120.196.232:5000"

+ **DOWNLOAD_SERVER 配置项**

  `hdp-submarine-assembly` 默认都是从网络上直接下载所有的依赖包（例如：GCC、Docker、Nvidia 驱动等等），这往往需要消耗大量的时间，并且在有些服务器不能连接互联网的环境中将无法部署，所以我们在 `hdp-submarine-assembly` 中内置了 HTTP 下载服务，只需要在一台能够连接互联网的服务器中运行 `hdp-submarine-assembly` ，就可以为所有其他服务器提供依赖包的下载，只需要你按照以下配置进行操作：

  1. 首先，你需要将 `DOWNLOAD_SERVER_IP` 配置为一台能够连接互联网的服务器IP地址，将 `DOWNLOAD_SERVER_PORT` 配置为一个不会不太常用的端口。
  2. 在  `DOWNLOAD_SERVER_IP` 所在的那台服务器中运行 `hdp-submarine-assembly/install.sh` 命令后，在安装界面中选择 `[start download server]` 菜单项，`hdp-submarine-assembly` 将会把部署所有的依赖包全部下载到 `hdp-submarine-assembly/downloads` 目录中，然后通过 `python -m SimpleHTTPServer ${DOWNLOAD_SERVER_PORT}`  命令启动一个 HTTP 下载服务，不要关闭这台服务器中运行着的 `hdp-submarine-assembly` 。
  3. 在其他服务器中同样运行 `hdp-submarine-assembly/install.sh` 命令 ，按照安装界面中的 `[install component]`  菜单依次进行各个组件的安装时，会自动从 `DOWNLOAD_SERVER_IP` 所在的那台服务器下载依赖包进行安装部署。
  4. **DOWNLOAD_SERVER** 另外还有一个用处是，你可以自行把各个依赖包手工下载下来，然后放到其中一台服务器的 `hdp-submarine-assembly/downloads` 目录中，然后开启 `[start download server]` ，这样就可以为整个集群提供离线安装部署的能力。

+ **YARN_CONTAINER_EXECUTOR_PATH 配置项**

  如何编译 YARN 的 container-executor：你进入到 `hadoop/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-server/hadoop-yarn-server-nodemanager` 目录中执行 `mvn package -Pnative -DskipTests`  命令，将会编译出 `./target/native/target/usr/local/bin/container-executor` 文件。

  你需要将 `container-executor` 文件的完整路径填写在 YARN_CONTAINER_EXECUTOR_PATH 配置项中。

+ **YARN_HIERARCHY 配置项**

  请保持和你所使用的 YARN 集群的 yarn-site.xml 配置文件中的 'yarn.nodemanager.linux-container-executor.cgroups.hierarchy' 相同的配置，yarn-site.xml 中如果未配置该项，那么默认为 '/hadoop-yarn'。

+ **YARN_NODEMANAGER_LOCAL_DIRS 配置项**

  请保持和你所使用的 YARN 集群的 yarn-site.xml 配置文件中的 'yarn.nodemanager.local-dirs' 相同的配置。

+ **YARN_NODEMANAGER_LOG_DIRS 配置项**

  请保持和你所使用的 YARN 集群的 yarn-site.xml 配置文件中的 'yarn.nodemanager.log-dirs' 相同的配置。

### 使用说明

**hdp-submarine-assembly**  完全使用 Shell 脚本编写，不需要安装 ansible 等任何部署工具，避免了不同公司用户的服务器管理规范不同而导致程序不通用，例如：有些机房是不容许 ROOT 用户通过 SHELL 直接进行远程服务器操作等。

**hdp-submarine-assembly**  的部署过程，完全是通过在菜单中进行选择的操作方式进行的，避免了误操作的同时，你还可以通过各个菜单项目对任意一个组件进行分步执行安装、卸载、启动和停止各个组件，具有很好的灵活性，在部分组件出现问题后，也可以通过 **hdp-submarine-assembly**  对系统进行诊断和修复。

**hdp-submarine-assembly**  部署过程中屏幕中会显示日志信息，日志信息一共有三种字体颜色：

+ 红色字体颜色：说明组件安装出现了错误，部署已经终止。

+ 绿色文字颜色：说明组件安装正常，部署正常运行。

+ 蓝色文字颜色：需要你按照提示信息在另外一个 SHELL 终端中进行手工输入命令，一般是修改操作系统内核配置操作，按照提示信息依次操作就可以了。

**启动 hdp-submarine-assembly**

运行 `hdp-submarine-assembly/install.sh` 命令启动，部署程序首先会检测服务器中的网卡 IP 地址，如果服务器有多个网卡或配置了多个 IP ，会以列表的形式显示，选择你实际使用的 IP 地址。

**hdp-submarine-assembly**  菜单说明：

![hdp-submarine-assembly](assets/hdp-submarine-assembly.gif)

### 部署说明

部署流程如下所示：

1. 参照配置说明，根据你的服务器使用情况配置好 install.conf 文件

2. 将整个 `hdp-submarine-assembly` 文件夹打包复制到所有的服务器节点中

3. 首先在配置为 **DOWNLOAD_SERVER** 的服务器中

   + 运行 `hdp-submarine-assembly/install.sh` 命令

   + 在安装界面中选择 `[start download server]` 菜单项，等待下载完各个依赖包后，启动 HTTP 服务

4. 在其他需要进行部署的服务器中

   运行 `hdp-submarine-assembly/install.sh` 命令，显示的主菜单 **[Main menu]** 中有以下菜单：

   + prepare system environment
   + install component
   + uninstall component
   + start component
   + stop component
   + start download server

5. **prepare system environment**

   + prepare operation system

   + prepare operation system kernel

   + prepare GCC version

   + check GPU

   + prepare user&group

   + prepare nvidia environment

6. install component

   + instll etcd
   + instll docker
   + instll calico network
   + instll nvidia driver
   + instll nvidia docker
   + instll yarn container-executor
   + instll submarine autorun script

7. uninstall component

   - uninstll etcd
   - uninstll docker
   - uninstll calico network
   - uninstll nvidia driver
   - uninstll nvidia docker
   - uninstll yarn container-executor
   - uninstll submarine autorun script

8. start component

   - start etcd
   - start docker
   - start calico network

9. stop component

   - stop etcd
   - stop docker
   - stop calico network

10. start download server

