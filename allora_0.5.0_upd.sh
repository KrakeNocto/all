#!/bin/bash

systemctl stop allora

wget https://github.com/allora-network/allora-chain/releases/download/v0.5.0/allorad_linux_amd64

mkdir -p /root/.allorad/cosmovisor/upgrades/v0.5.0/bin/

sed -ie 's|Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"|Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"|' /etc/systemd/system/allora.service

mv allorad_linux_amd64 /root/.allorad/cosmovisor/upgrades/v0.5.0/bin/allorad

chmod +x /root/.allorad/cosmovisor/upgrades/v0.5.0/bin/allorad

systemctl daemon-reload && systemctl restart allora && journalctl -fu allora
