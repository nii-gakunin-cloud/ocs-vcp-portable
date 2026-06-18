#/bin/bash

docker run -u root -d -p 24224:24224 -p 24224:24224/udp -v ./conf/:/fluentd/etc fluent/fluentd:v1.16-debian