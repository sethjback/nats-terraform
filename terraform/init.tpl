#!/usr/bin/env bash

for srv in $(aws ec2 describe-instances --region ${SERVER_REGION} --filter Name=tag:TF_DEPLOYED_NATS,Values=nats* --query 'Reservations[*].Instances[*].{"dns":PublicDnsName}' | jq -r '.[][].dns'); do
    CLUSTER_ROUTES=$(cat <<EOL
        $${CLUSTER_ROUTES}
        nats-route://$${srv}:4248
EOL
)
done

cat > /tmp/nats.config <<EOL
port: 4222
http_port: 8222
server_name: nats-server${SERVER_INDEX}

jetstream {
    store_dir: /mnt/data
    max_mem: 0
    max_file: 100G
}

cluster {
    name: test
    port: 4248
    routes: [
        $${CLUSTER_ROUTES}
    ]
}
EOL

cp /tmp/nats.config /opt/nats/nats.config
systemctl enable nats-server
systemctl start nats-server