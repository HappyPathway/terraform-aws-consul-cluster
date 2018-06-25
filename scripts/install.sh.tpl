cat << EOF > /etc/consul.d/consul-join.hcl
{
    "retry_join": ["provider=aws tag_key=ConsulServer tag_value=${env}"]
}
EOF

export CONSUL_UI_BETA=true
service consul restart