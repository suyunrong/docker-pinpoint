FROM ubuntu:16.04
LABEL authors=suyunrong

#================================================
# 配置apt-get源
#================================================
RUN  echo "deb http://archive.ubuntu.com/ubuntu xenial main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu xenial-updates main universe\n" >> /etc/apt/sources.list \
  && echo "deb http://security.ubuntu.com/ubuntu xenial-security main universe\n" >> /etc/apt/sources.list

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

#========================
# 安装基础软件包
# 包括 jdk wget unzip ca-certificates tzdata...
#========================
RUN apt-get -qqy update \
  && apt-get -qqy --no-install-recommends install \
    bzip2 \
    ca-certificates \
    tzdata \
    sudo \
    unzip \
    wget \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#===================
# 设置Timezone
#===================
ENV TZ "Asia/Shanghai"
RUN echo "${TZ}" > /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata

#========================================
# JDK config
#========================================
RUN wget --no-check-certificate --no-cookies --header="Cookie: oraclelicense=accept-securebackup-cookie" --no-verbose -O /tmp/jdk-8u171-linux-x64.tar.gz  http://download.oracle.com/otn-pub/java/jdk/8u171-b11/512cd62ec5174c3487ac17c61aaa89e8/jdk-8u171-linux-x64.tar.gz \
  && wget --no-check-certificate --no-cookies --header="Cookie: oraclelicense=accept-securebackup-cookie" --no-verbose -O /tmp/jdk-7u80-linux-x64.tar.gz http://download.oracle.com/otn/java/jdk/7u80-b15/jdk-7u80-linux-x64.tar.gz \
  && wget --no-check-certificate --no-cookies --header="Cookie: oraclelicense=accept-securebackup-cookie" --no-verbose -O /tmp/jdk-6u45-linux-x64.bin http://download.oracle.com/otn/java/jdk/6u45-b06/jdk-6u45-linux-x64.bin \
  && tar -xzvf /tmp/jdk-8u171-linux-x64.tar.gz /usr/local/java/ \
  && tar -xzvf /tmp/jdk-7u80-linux-x64.tar.gz /usr/local/java \
  && chmod +x /tmp/jdk-6u45-linux-x64.bin \
  && /tmp/jdk-6u45-linux-x64.bin \
  && cp -r /tmp/jdk1.6.0_45 /usr/local/java \
  && echo "JAVA_6_HOME=\"/usr/local/java/jdk1.6.0_45\"" >> /etc/profile \
  && echo "JAVA_7_HOME=\"/usr/local/java/jdk1.7.0_80\"" >> /etc/profile \
  && echo "JAVA_HOME=\"/usr/local/java/jdk1.8.0_171\"" >> /etc/profile \
  && echo "export JAVA_HOME" >> /etc/profile \
  && echo "export PATH=\"$PATH:$JAVA_HOME/bin\"" >> /etc/profile \
  && rm -rf /tmp/jdk-8u171-linux-x64.tar.gz \
  && rm -rf /tmp/jdk-7u80-linux-x64.tar.gz \
  && rm -rf /tmp/jdk1.6.0_45

#========================================
# Tomcat config
# http://mirrors.hust.edu.cn/apache/tomcat/tomcat-8/v8.0.51/bin/apache-tomcat-8.0.51.tar.gz
#========================================
RUN wget --no-verbose -O /tmp/hbase-1.2.6-bin.tar.gz http://mirrors.hust.edu.cn/apache/tomcat/tomcat-8/v8.0.51/bin/apache-tomcat-8.0.51.tar.gz \
 && mkdir -p /www/tomcat/ \
 && tar

#========================================
# pinpoint config
# https://github.com/naver/pinpoint/releases/download/1.7.3/pinpoint-web-1.7.3.war
# https://github.com/naver/pinpoint/releases/download/1.7.3/pinpoint-collector-1.7.3.war
# http://archive.apache.org/dist/hbase/1.2.6/hbase-1.2.6-bin.tar.gz
#========================================
RUN wget --no-verbose -O /tmp/hbase-1.2.6-bin.tar.gz http://archive.apache.org/dist/hbase/1.2.6/hbase-1.2.6-bin.tar.gz \
  && wget --no-verbose -O /tmp/pinpoint-collector-1.7.3.war https://github.com/naver/pinpoint/releases/download/1.7.3/pinpoint-collector-1.7.3.war \
  && wget --no-verbose -O /tmp/pinpoint-web-1.7.3.war https://github.com/naver/pinpoint/releases/download/1.7.3/pinpoint-web-1.7.3.war \
  && 


#========================================
# 添加普通用户
#========================================
RUN useradd pinpoint \
         --shell /bin/bash  \
         --create-home \
  && usermod -a -G sudo pinpoint \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'pinpoint:pinpoint' | chpasswd



# 拷贝必要文件
COPY jdk/jdk1.6.0_45 /usr/local/java/jdk1.6.0_45
COPY jdk/jdk1.7.0_80 /usr/local/java/jdk1.7.0_80
COPY jdk/jdk1.8.0_161 /usr/local/java/jdk1.8.0_161
COPY hbase/hbase /www/hbase
COPY hbase/hbase-create.hbase /www/
COPY pinpoint/pinpoint-collector-1.7.1.war /www/war/
COPY pinpoint/pinpoint-web-1.7.1.war /www/war/
COPY tomcat/pp-col-tomcat /www/tomcat/pp-col-tomcat
COPY tomcat/pp-web-tomcat /www/tomcat/pp-web-tomcat
COPY script/run.sh /www/script/

# 固化环境变量
ENV JAVA_HOME /usr/local/java/jdk1.8.0_161
ENV PATH $PATH:$JAVA_HOME/bin

# 配置ssh免密登录
# 配置时间
# java环境变量写入profile文件
# 解压war包
RUN yum install -y openssh-server openssh-clients  net-tools tzdata unzip \
 && sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config \
 && echo "root:123456" | chpasswd \
 && ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key \
 && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key \
 && sed -i 's/session    required     pam_loginuid.so/#session    required     pam_loginuid.so/g' /etc/pam.d/sshd \
 && mkdir /var/run/sshd \
 && sed -i 's|ZONE="Etc/UTC"|ZONE="Asia/Shanghai"|g' /etc/sysconfig/clock \
 && echo 'Asia/Shanghai' >> /etc/timezone \
 && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
 && echo "JAVA_HOME=\"/usr/local/java/jdk1.8.0_161\"" >> /etc/profile \
 && echo "export JAVA_HOME" >> /etc/profile \
 && echo "export PATH=\"$PATH:$JAVA_HOME/bin\"" >> /etc/profile \
 && rm -rf /www/tomcat/pp-col-tomcat/webapps/* \
 && unzip /www/war/pinpoint-collector-1.7.1.war -d /www/tomcat/pp-col-tomcat/webapps/ROOT \
 && rm -rf /www/tomcat/pp-web-tomcat/webapps/* \
 && unzip /www/war/pinpoint-web-1.7.1.war -d /www/tomcat/pp-web-tomcat/webapps/ROOT \
 && rm -rf /www/war \
 && yum clean all


# 配置Hbase、pinpoint
# 1、新建数据文件夹，并修改配置文件
# 2、修改pp-col-tomcat访问端口、pp-web-tomcat访问端口
# 3、赋脚本执行权限
RUN mkdir -p /www/data \
 && sed -i 's|# export JAVA_HOME=/usr/java/jdk1.6.0/|export JAVA_HOME=/usr/local/java/jdk1.8.0_161|g' /www/hbase/conf/hbase-env.sh \
 && sed -i 's|</configuration>|    <property>\r\n        <name>hbase.rootdir</name>\r\n        <value>file:///data/hbase</value>\r\n    </property>\r\n</configuration>|g' /www/hbase/conf/hbase-site.xml \
 && sed -i 's|export HBASE_MASTER_OPTS="$HBASE_MASTER_OPTS -XX:PermSize=128m -XX:MaxPermSize=128m"|#export HBASE_MASTER_OPTS="$HBASE_MASTER_OPTS -XX:PermSize=128m -XX:MaxPermSize=128m"|g' /www/hbase/conf/hbase-env.sh \
 && sed -i 's|export HBASE_REGIONSERVER_OPTS="$HBASE_REGIONSERVER_OPTS -XX:PermSize=128m -XX:MaxPermSize=128m"|#export HBASE_REGIONSERVER_OPTS="$HBASE_REGIONSERVER_OPTS -XX:PermSize=128m -XX:MaxPermSize=128m"|g' /www/hbase/conf/hbase-env.sh \
 && sed -i 's/port="8005"/port="18005"/g' /www/tomcat/pp-col-tomcat/conf/server.xml \
 && sed -i 's/port="8080"/port="18080"/g' /www/tomcat/pp-col-tomcat/conf/server.xml \
 && sed -i 's/port="8443"/port="18443"/g' /www/tomcat/pp-col-tomcat/conf/server.xml \
 && sed -i 's/port="8009"/port="18009"/g' /www/tomcat/pp-col-tomcat/conf/server.xml \
 && sed -i 's/redirectPort="8443"/redirectPort="18443"/g' /www/tomcat/pp-col-tomcat/conf/server.xml \
 && sed -i 's/port="8005"/port="28005"/g' /www/tomcat/pp-web-tomcat/conf/server.xml \
 && sed -i 's/port="8080"/port="28080"/g' /www/tomcat/pp-web-tomcat/conf/server.xml \
 && sed -i 's/port="8443"/port="28443"/g' /www/tomcat/pp-web-tomcat/conf/server.xml \
 && sed -i 's/port="8009"/port="28009"/g' /www/tomcat/pp-web-tomcat/conf/server.xml \
 && sed -i 's/redirectPort="8443"/redirectPort="28443"/g' /www/tomcat/pp-web-tomcat/conf/server.xml \
 && chmod u+x /www/script/run.sh

# 开放端口组，ssh(22)，hbase(16010)，pp-col(18080)，pp-web(28080)
EXPOSE 22 16010 18080 28080 9994 9995/udp 9996/udp

# 运行脚本，启动sshd服务
CMD ["/www/script/run.sh"]
