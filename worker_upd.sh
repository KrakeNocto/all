#!/bin/bash

sed -i '/"wallet": {/a\ \ \ \ "gas": "auto",\n\ \ \ \ "gasAdjustment": 1.5,\n\ \ \ \ "gasPrices": 0.08,\n\ \ \ \ "maxFees": 200000,\n\ \ \ \ "maxRetries": 5,' /root/basic-coin-prediction-node/config.example.json
./init.config

rm worker_upd.sh

docker compose up -d && docker logs -f worker --tail 50
