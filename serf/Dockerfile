FROM alpine:latest AS builder
RUN apk add --no-cache wget unzip \
    && wget https://releases.hashicorp.com/serf/0.8.2/serf_0.8.2_linux_amd64.zip \
    && unzip serf_0.8.2_linux_amd64.zip -d /usr/local/bin

FROM alpine:latest

RUN apk add --no-cache jq

WORKDIR /usr/share/serf
COPY --from=builder /usr/local/bin/serf /usr/local/bin/serf
COPY ./event-handler.sh /usr/local/bin/event-handler.sh
RUN chmod +x /usr/local/bin/event-handler.sh
ENTRYPOINT ["/usr/local/bin/serf"]