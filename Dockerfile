from ubuntu:jammy as builder
RUN apt-get update && \
    apt-get install -y git wget ca-certificates build-essential && \
    wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz && \
    export PATH=$PATH:/usr/local/go/bin && \
    go version && \
    gcc --version && \
    git clone https://github.com/harness/gitness /gitness && \
    cd /gitness/ && \
    git checkout drone && \
    go build -tags "nolimit" github.com/drone/drone/cmd/drone-server

FROM ubuntu:jammy
EXPOSE 80 443
VOLUME /data

RUN if [[ ! -e /etc/nsswitch.conf ]] ; then echo 'hosts: files dns' > /etc/nsswitch.conf ; fi

ENV GODEBUG netdns=go
ENV XDG_CACHE_HOME /data
ENV DRONE_DATABASE_DRIVER sqlite3
ENV DRONE_DATABASE_DATASOURCE /data/database.sqlite
ENV DRONE_RUNNER_OS=linux
ENV DRONE_RUNNER_ARCH=amd64
ENV DRONE_SERVER_PORT=:80
ENV DRONE_SERVER_HOST=localhost
ENV DRONE_DATADOG_ENABLED=false
ENV DRONE_DATADOG_ENDPOINT=https://stats.drone.ci/api/v1/series

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /gitness/drone-server /bin/drone-server

ENTRYPOINT ["/bin/drone-server"]
