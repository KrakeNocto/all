import os
from pathlib import Path
import torch
import torch.nn as nn
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
import requests
from flask import Flask, Response, json

app = Flask(__name__)


# Define the BiRNN model with the correct architecture
class BiRNNModel(nn.Module):
    def __init__(self, input_size, hidden_layer_size, output_size, num_layers, dropout):
        super(BiRNNModel, self).__init__()
        self.hidden_layer_size = hidden_layer_size
        self.num_layers = num_layers
        self.rnn = nn.RNN(input_size, hidden_layer_size, num_layers=num_layers, dropout=dropout, batch_first=True,
                          bidirectional=True)
        self.linear = nn.Linear(hidden_layer_size * 2, output_size)  # *2 because of bidirectional

    def forward(self, input_seq):
        h_0 = torch.zeros(self.num_layers * 2, input_seq.size(0), self.hidden_layer_size)  # *2 for bidirection
        rnn_out, _ = self.rnn(input_seq, h_0)
        predictions = self.linear(rnn_out[:, -1])
        return predictions


# Initialize the model with the same architecture as during training
model = BiRNNModel(input_size=1, hidden_layer_size=115, output_size=1, num_layers=2, dropout=0.3)
path = Path(os.path.dirname(__file__)) / "birnn_model_optimized.pth"
model.load_state_dict(torch.load(path, weights_only=True))
model.eval()


# Function to fetch historical data from Binance
def get_binance_url(symbol="ETHUSDT", interval="1m", limit=1000):
    return f"https://api.binance.com/api/v3/klines?symbol={symbol}&interval={interval}&limit={limit}"

@app.route("/healthcheck")
def healthcheck():
    return Response(json.dumps({"status": "ok"}), status=200, mimetype='application/json')

@app.route("/inference/<string:token>")
def get_inference(token):
    if model is None:
        return Response(json.dumps({"error": "Model is not available"}), status=500, mimetype='application/json')

    # symbols = ['DOGEUSDT', 'ORDIUSDT', 'BOMEUSDT', 'PEOPLEUSDT', 'MEMEUSDT', '1000SATSUSDT']

    symbol_map = {
        'DOGE': 'DOGEUSDT',
        'BOME': 'BOMEUSDT',
        'BONK': 'BONKUSDT',
        'MEME': 'MEMEUSDT',
        'ORDI': 'ORDIUSDT',
        'FLOKI': 'FLOKIUSDT',
        'PEOPLE': 'PEOPLEUSDT',
        'WIF': 'WIFUSDT',
        '1000SATS': '1000SATSUSDT',
        'DOGS':'DOGSUSDT',
        'BANANA':'BANANAUSDT',
        'SHIB':'SHIBUSDT',
        'AI':'AIUSDT',
        'FET':'FETUSDT',
        'GRT':'GRTUSDT',
        'NFP':'NFPUSDT',
        'PHB':'PHBUSDT',
        'OM':'OMUSDT',
        'RSR':'RSRUSDT',
        'ICP':'ICPUSDT',
        'PENDLE':'PENDLEUSDT',
        'SNX':'SNXUSDT',
        'RAY':'RAYUSDT',
        'RENDER':'RENDERUSDT',
        'IO':'IOUSDT',
        'FIDA':'FIDAUSDT',
        'DUSK':'DUSKUSDT',
        'WLD':'WLDUSDT',
        'THETA':'THETAUSDT',
        'POND':'PONDUSDT',
        'PHA':'PHAUSDT',
        'TNSR':'TNSRUSDT',
        'TURBO':'TURBOUSDT',
        'NEIRO':'NEIROUSDT',
        '1MBABYDOGE':'1MBABYDOGEUSDT',
        'JTO':'JTOUSDT',
        'JUP':'JUPUSDT',
        'W':'WUSDT',
        'TRU':'TRUUSDT',
        'POLYX':'POLYXUSDT',
        'MKR':'MKRUSDT',
        'GMT':'GMTUSDT',
        'PYTH':'PYTHUSDT',
        'AVAX':'AVAXUSDT',
        'CHR':'CHRUSDT',
        'HIFI':'HIFIUSDT',
        'LTO':'LTOUSDT',
        'ARPA':'ARPAUSDT',
        'ASTR':'ASTRUSDT',
        'ATOM':'ATOMUSDT',
        'AXL':'AXLUSDT',
        'BB':'BBUSDT',
        'CELO':'CELOUSDT',
        'CFX':'CFXUSDT',
        'CHZ':'CHZUSDT',
        'COMBO':'COMBOUSDT',
        'DCR':'DCRUSDT',
        'EGLD':'EGLDUSDT',
        'EOS':'EOSUSDT',
        'ACE':'ACEUSDT',
        'AEVO':'AEVOUSDT',
        'ALT':'ALTUSDT',
        'AXS':'AXSUSDT',
        'BAND':'BANDUSDT',
        'BAT':'BATUSDT',
        'BNX':'BNXUSDT',
        'C98':'C98USDT',
        'BURGE':'BURGEUSDT',
        'CHESS':'CHESSUSDT',
        'CITY':'CITYUSDT',
        'COTI':'COTIUSDT',
        'CVC':'CVCUSDT',
        'CVX':'CVXUSDT',
        'DASH':'DASHUSDT',
        'DGB':'DGBUSDT'
    }

    token = token.upper()
    if token in symbol_map:
        symbol = symbol_map[token]
    else:
        return Response(json.dumps({"error": "Unsupported token"}), status=400, mimetype='application/json')

    url = get_binance_url(symbol=symbol, interval="1h", limit=2000)
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        df = pd.DataFrame(data, columns=[
            "open_time", "open", "high", "low", "close", "volume",
            "close_time", "quote_asset_volume", "number_of_trades",
            "taker_buy_base_asset_volume", "taker_buy_quote_asset_volume", "ignore"
        ])
        df["close_time"] = pd.to_datetime(df["close_time"], unit='ms')
        df = df[["close_time", "close"]]
        df.columns = ["date", "price"]
        df["price"] = df["price"].astype(float)

        # Adjust the number of rows based on the symbol
        df = df.tail(20)  # Use last 20 minutes of data

        # Prepare data for the BiRNN model
        scaler = MinMaxScaler(feature_range=(-1, 1))
        scaled_data = scaler.fit_transform(df['price'].values.reshape(-1, 1))

        seq = torch.FloatTensor(scaled_data).view(1, -1, 1)

        # Make prediction
        with torch.no_grad():
            y_pred = model(seq)

        # Inverse transform the prediction to get the actual price
        predicted_price = scaler.inverse_transform(y_pred.numpy())

        # Round the predicted price to 2 decimal places
        rounded_price = round(predicted_price.item(), 2)

        # Return the rounded price as a string
        return Response(str(rounded_price), status=200, mimetype='application/json')
    else:
        return Response(json.dumps({"error": "Failed to retrieve data from Binance API", "details": response.text}),
                        status=response.status_code,
                        mimetype='application/json')


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8000)
