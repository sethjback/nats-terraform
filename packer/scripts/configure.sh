#!/usr/bin/env bash

set -xe
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

yum update -y --security --skip-broken && yum install  -y jq

cd /opt

wget -q https://github.com/nats-io/nats-server/releases/download/v${NATS_VERSION}/nats-server-v${NATS_VERSION}-linux-amd64.tar.gz
tar -xzvf nats-server-v${NATS_VERSION}-linux-amd64.tar.gz
mv nats-server-v${NATS_VERSION}-linux-amd64 nats
rm nats-server-v${NATS_VERSION}-linux-amd64.tar.gz

groupadd nats
useradd -s /bin/bash -d /opt/nats -g nats nats

mkdir -p /mnt/data
chown nats:nats /mnt/data

cat > /etc/systemd/system/nats-server.service <<EOL
[Unit]
Description=NATS server
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
User=nats
Group=nats
ExecStart=/opt/nats/nats-server -c /opt/nats/nats.config
Restart=on-failure
SyslogIdentifier=nats-server

[Install]
WantedBy=multi-user.target
EOL

cat > /opt/nats/nats.config <<EOL
port: 4222
http_port: 8222


jetstream {
    store_dir: /mnt/data
}
EOL

chown -R nats:nats /opt/nats
systemctl enable nats-server

yum clean all