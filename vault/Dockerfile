FROM openbao/openbao:latest

COPY ./ /bao/
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/bin/sh", "/usr/local/bin/entrypoint.sh"]