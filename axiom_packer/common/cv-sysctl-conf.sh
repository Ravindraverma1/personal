#!/bin/bash
set +e

# keepalives and retries2 were modified here @1.38 due to OCI database connectivity issues.
echo "Modifying sysctl.conf keepalives and retries2 for cv instance."
cat <<EOT >> /etc/sysctl.conf
net.ipv4.tcp_retries2=5
net.ipv4.tcp_keepalive_time=30
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_keepalive_intvl=3
EOT

exit 0