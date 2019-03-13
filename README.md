# Docker for pinpoint  

# windows Tomcat  
set "CATALINA_OPTS=%CATALINA_OPTS% -javaagent:$AGENT_PATH/pinpoint-bootstrap-$VERSION.jar"  
set "CATALINA_OPTS=%CATALINA_OPTS% -Dpinpoint.agentId=$AGENT_ID"  
set "CATALINA_OPTS=%CATALINA_OPTS% -Dpinpoint.applicationName=$APPLICATION_NAME"  

# Linux Tomcat  
CATALINA_OPTS="$CATALINA_OPTS -javaagent:$AGENT_PATH/pinpoint-bootstrap-$VERSION.jar"  
CATALINA_OPTS="$CATALINA_OPTS -Dpinpoint.agentId=$AGENT_ID"  
CATALINA_OPTS="$CATALINA_OPTS -Dpinpoint.applicationName=$APPLICATION_NAME"

# SpringBoot  
java -jar -javaagent:$AGENT_PATH\\pinpoint-bootstrap-$VERSION.jar -Dpinpoint.agentId=$AGENT_ID -Dpinpoint.applicationName=$APPLICATION_NAME $SPRINGBOOT_PATH\\$APPLICATION_NAME.jar

# Docker Run  
docker run -d -p 10022:22/tcp -p 16010:16010/tcp -p 18080:18080/tcp -p 28080:28080/tcp -p 9994:9994/tcp -p 9995:9995/udp -p 9996:9996/udp --name $name $image:tag
