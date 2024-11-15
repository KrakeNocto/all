#!/bin/bash

min_am=600
max_am=86400
random_am=$(shuf -i $min_am-$max_am -n 1)

echo "Updating Allora worker after $random_am seconds"

sleep $random_am

cd basic-coin-prediction-node/

sed -i '/"wallet": {/a\ \ \ \ "gas": "auto",\n\ \ \ \ "gasAdjustment": 1.5,\n\ \ \ \ "gasPrices": 0.08,\n\ \ \ \ "maxFees": 200000,\n\ \ \ \ "maxRetries": 5,' /root/basic-coin-prediction-node/config.example.json
sed -i 's/latest/v0.5.1/g' /root/basic-coin-prediction-node/docker-compose.yml
./init.config

rm worker_upd.sh

docker compose down
docker compose pull
docker compose build
docker compose up -d && docker logs -f worker --tail 50
