# Setup the configuration
#consul conf
hostname=$$(hostname)
ip_address=$$(ifconfig eth0 | grep "inet addr" | awk '{ print substr($2,6) }')

cat << EOF > /etc/consul.d/consul-join.hcl
{
    "retry_join": ["provider=aws tag_key=ConsulServer tag_value=${env}"]
}
EOF

cat << EOF > /etc/consul.d/consul-type.json
{
    "server": true
}
EOF

cat << EOF > /etc/consul.d/consul-node.json
{
    "advertise_addr": "$${ip_address}",
    "node_name": "$${hostname}",
    "datacenter": "${datacenter}"
}
EOF

export CONSUL_UI_BETA=true
service consul restart