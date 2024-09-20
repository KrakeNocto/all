#!/bin/bash

systemctl stop allora

wget https://github.com/allora-network/allora-chain/releases/download/v0.5.0/allorad_linux_amd64

rm /root/.allorad/cosmovisor/upgrades/v0.4.0/bin/allorad

mv allorad_linux_amd64 /root/.allorad/cosmovisor/upgrades/v0.4.0/bin/allorad

chmod +x /root/.allorad/cosmovisor/upgrades/v0.4.0/bin/allorad

systemctl restart allora && journalctl -fu allora
