#!/bin/bash

# 启动hbase
/www/hbase/bin/start-hbase.sh

sleep 5

# 初始化hbase表
#/www/hbase/bin/hbase shell /opt/bin/hbase-create.hbase

# 启动pp-col
/www/tomcat/pp-col-tomcat/bin/startup.sh

sleep 20

# 启动pp-web
/www/tomcat/pp-web-tomcat/bin/startup.sh && tail -f /www/tomcat/pp-web-tomcat/logs/catalina.out

