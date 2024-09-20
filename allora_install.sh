sudo rm -rvf /usr/local/go/
wget https://golang.org/dl/go1.22.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
rm go1.22.4.linux-amd64.tar.gz

export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0

git clone https://github.com/allora-network/allora-chain allora
cd allora
git checkout v0.4.0
make install

echo "Enter MONIKER:"
read -r MONIKER

allorad init $MONIKER --chain-id allora-testnet-1

wget -O genesis.json https://snapshots.polkachu.com/testnet-genesis/allora/genesis.json --inet4-only
mv genesis.json ~/.allorad/config

sudo tee /etc/systemd/system/allora.service >/dev/null <<EOF
[Unit]
Description="allora node"
After=network-online.target

[Service]
User=root
ExecStart=/root/go/bin/cosmovisor start
Restart=always
RestartSec=3
LimitNOFILE=4096
Environment="DAEMON_NAME=allorad"
Environment="DAEMON_HOME=/root/.allorad"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"

[Install]
WantedBy=multi-user.target

[Install]
WantedBy=multi-user.target
EOF

sed -ie 's|laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|'  /root/.allorad/config/config.toml
sed -ie 's|persistent_peers = ""|persistent_peers = "850c593cad39a391031b4795ca9d82f41618b590@167.235.178.134:26756,4870bafe0cc669b2251cc72cc6b725a48d9b1e85@95.216.248.99:46656,0f6b64fcd38872d18a78d89e090a5e6928883d52@8.209.116.116:26656,79af04335a0ac10073ef9342edba78e8fb08f9fc@89.58.0.245:37778,cc76fac947e64f1d81083efea62c1245f338254c@185.232.71.181:26656,7986eb91ab2d81b5ae77298e5fd07fdfab4e9600@38.242.240.25:26656,335975741b3c218a09de4795edce7d8d28dba24d@159.69.181.252:26656,ad3a6b49bf0c3e082be5ab2b116e622b795b1f1e@188.40.66.173:26756,2eb9f5f80d721be2d37ab72c10a7be6aaf7897a4@15.204.101.92:26656,4955d51613a243b6e03d26f2982c7aa4b202d8a6@104.244.208.243:26756,66ea64ffa2628643124905de9a38f3091f57a975@94.16.111.200:26656,50141585529ebd83539cfb335b2912dc9220b583@202.61.200.170:26656,720d83b52611c64d119adfc4d08d2e85885d8c74@142.132.253.112:27656,e40801e60d93cda37ca5e163d036231cde0fe924@88.198.52.46:26756,2bb0dcd34af655ea1c3176047df952004d1127dc@65.108.232.20:26656,7bd99d499cd6c0cea4621a542dd3df0d1a7b1c48@194.164.77.63:26656,d4c232403f9d87c62e941cf28187eb949e63b9c8@162.55.65.137:26756,02653420f36364d15325966e5e641281a25c789d@188.27.225.103:26656,78be7cee13de1ac03a7368eecf86c0a3cbd231c3@35.217.49.11:26656,466e981d26db4a797299f6d626d2b8147fc04a2b@192.145.46.171:26656,8e81ed8901ea006ea77b9145cca62b73dc0463e9@5.189.146.38:26666,debd000d74728751034ad24cdae1dcad0d10d5ef@62.171.189.214:26666,870d2d7c6235b1bb3603dfd6069e90a8204318f3@95.217.196.224:26656,18fbf5f16f73e216f93304d94e8b79bf5acd7578@15.204.101.152:26656,41a67b6778fe1789825ea707c9dc6ef2b6c8e37e@185.211.4.175:26656,336b6d5846c23cd8d8f33ceb7206c4eb4acb58d1@168.119.137.241:26656,04449adf1c41cb8ee598b22e1a53977e43bce3f5@35.228.206.197:26656,2ca97962beb954ae7e824f4b17369e717d4a9fcc@198.7.120.112:26666,2bd135ae4cc0362ac2b62891947f4edf1be45edb@15.204.101.153:26656,b91e41cf5340d418969f25702de42ba31b381710@15.204.101.154:26656,ed0e6f02831ccdc09dfb4e4e9f703d373486bc82@43.157.20.64:26656,d6f594b59b6a6a47a40e5720368094cebe7cdcf0@5.189.188.99:26666,c13dcf555ef6f71a8982bc38be0762d6d41e6e00@108.209.102.187:26643,e4f87c7fd5fac03a4bbea9e334a7d14079d764f0@62.171.168.129:26666"|'  /root/.allorad/config/config.toml

sed -ie 's|pruning = "default"|pruning = "custom"|'  /root/.allorad/config/app.toml
sed -ie 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|'  /root/.allorad/config/app.toml
sed -ie 's|pruning-interval = "0"|pruning-interval = "10"|'  /root/.allorad/config/app.toml

min_am=10
max_am=63
random_am=$(shuf -i $min_am-$max_am -n 1)
echo $random_am

sed -ie 's|laddr = "tcp://0.0.0.0:26657"|laddr = "tcp://0.0.0.0:'$random_am'657"|'  /root/.allorad/config/config.toml
sed -ie 's|laddr = "tcp://0.0.0.0:26656"|laddr = "tcp://0.0.0.0:'$random_am'656"|'  /root/.allorad/config/config.toml

cd

rm -rf /root/.allorad/data
wget -O allora_1291122.tar.lz4 https://snapshots.polkachu.com/testnet-snapshots/allora/allora_1291122.tar.lz4 --inet4-only

lz4 -c -d allora_1291122.tar.lz4| tar -x -C $HOME/.allorad

rm -v allora_1291122.tar.lz4

mkdir -p ~/.allorad/cosmovisor/genesis/bin
cp ~/go/bin/allorad ~/.allorad/cosmovisor/genesis/bin


wget https://github.com/allora-network/allora-chain/releases/download/v0.4.0/allorad_linux_amd64

chmod +x allorad_linux_amd64

mkdir -p .allorad/cosmovisor/upgrades/v0.4.0/bin/

mv allorad_linux_amd64 .allorad/cosmovisor/upgrades/v0.4.0/bin/allorad

 
sudo systemctl enable allora.service
sudo service allora start
sudo journalctl -fu allora
