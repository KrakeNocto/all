#!/bin/bash

min_am=600
max_am=61200
random_am=$(shuf -i $min_am-$max_am -n 1)

echo "Updating Allora worker after $random_am seconds"

sleep $random_am

cd basic-coin-prediction-node/

sed -i '/"wallet": {/a\ \ \ \ "gas": "auto",\n\ \ \ \ "gasAdjustment": 2,\n\ \ \ \ "gasPrices": "10",\n\ \ \ \ "maxFees": 25000000,\n\ \ \ \ "maxRetries": 5,' /root/basic-coin-prediction-node/config.json
sed -i 's/"inferenceEntrypointName": "api-worker-reputer"/"inferenceEntrypointName": "apiAdapter"/' /root/basic-coin-prediction-node/config.json
sed -i '/"wallet": {/a \
  "retryDelay": 3,\n\
  "accountSequenceRetryDelay": 5,\n\
  "blockDurationEstimated": 10,\n\
  "windowCorrectionFactor": 0.8,' /root/basic-coin-prediction-node/config.json
sed -i 's/v0.5.1/v0.7.0/g' /root/basic-coin-prediction-node/docker-compose.yml
sed -i 's/"nodeRpc": "[^"]*"/"nodeRpc": "https:\/\/rpc.ankr.com\/allora_testnet"/' /root/basic-coin-prediction-node/config.json
./init.config

rm worker_upd.sh

docker compose down
docker compose pull
docker compose up -d && docker logs -f worker --tail 50
