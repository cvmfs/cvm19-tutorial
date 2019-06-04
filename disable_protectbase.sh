#!/bin/sh

cat << EOF > /etc/yum/pluginconf.d/protectbase.conf
[main]
enabled = 0
EOF

touch /tmp/protectbase_disabled