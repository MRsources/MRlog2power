import pandas as pd
import re
import numpy as np
import matplotlib.pyplot as plt
from datetime import datetime
import torch
from model import NeuralNet
from sklearn.preprocessing import OneHotEncoder, StandardScaler

# # read selected log data set
df1 = pd.read_csv('mr3_log_selected.txt',  header=None, usecols=[0, 1, 3,4], names=['t_sel', 'ID_sel', 'log_sel', 'seq_sel'])
df1['t_sel'] = pd.to_datetime(df1['t_sel'], format='%Y%m%d%H%M%S', errors='coerce')
df1['pro_sel'] = df1['log_sel'].astype(str).apply(lambda x: re.search(r'Protocol: ([^,]*)', x).group(1) if re.search(r'Protocol: ([^,]*)', x) else None)
df1['seq_sel'] = df1['seq_sel'].astype(str).apply(lambda x: re.search(r'Sequence: ([^\)]*)', x).group(1) if re.search(r'Sequence: ([^\)]*)', x) else None)

# Create a dictionary to map the old IDs to the new ones
id_mapping = {
    1: 7.9,
    35: 8,
    56: 8.1,
    34: 14.13,
    103: 50,
    104: 15.3
}
# This will replace each old ID with the corresponding new ID in the 'ID_sel' column
df1['ID_sel'] = df1['ID_sel'].map(lambda x: id_mapping.get(x, x))

t_sel = df1['t_sel']
seq_sel = df1['seq_sel']
ID_sel = df1['ID_sel']
#
# # Drop rows where 'seq_sel' is NaN
# #df_filtered.dropna(subset=['seq_sel'], inplace=True)
dt_sel = t_sel.dt.strftime('%Y%m%d%H%M%S')
dt_sel_shifted = t_sel - pd.Timedelta(minutes=2.3)

# Find unique sequence types and encode them with an ID
seq_sel_filled = seq_sel.fillna('none')
uniqueSeq, seqIDs = np.unique(seq_sel_filled, return_inverse=True)

LOGEVENT = pd.DataFrame({
    'ID_sel': ID_sel.values,
    'seqIDs': seqIDs,
    'duration': t_sel.diff().dt.total_seconds().div(3600).shift(-1).fillna(0)
})

# 1. One-Hot Encoding for ID_sel and seqIDs
onehot_encoder = OneHotEncoder(sparse=False)
onehot_encoded = onehot_encoder.fit_transform(LOGEVENT[['ID_sel', 'seqIDs']])

# 2. Standardization for duration
scaler = StandardScaler()
duration_scaled = scaler.fit_transform(LOGEVENT[['duration']])

# Combine processed features
processed_features = np.concatenate([onehot_encoded, duration_scaled], axis=1)

# Load the trained model, scaler, and encoder
model = torch.load('model.pth')
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = model.to(device)
with torch.no_grad():
    X_test_tensor = torch.tensor(processed_features, dtype=torch.float32).to(device)
    predictions = model(X_test_tensor).cpu().numpy()

# plot the result
fig, ax = plt.subplots(figsize=(16, 8))
#ax.step(dT, KW_raw, where='pre', linestyle='-', label="original energy", color='blue')
#ax.step(dt_sel_shifted, ENERGY , where='post', linestyle='-', label="average energy", color='red')
ax.step(dt_sel_shifted, predictions , where='post', linestyle='-', label="predicited energy", color='green', picker=True)
ax.set_xlabel('Timestamp')
ax.set_ylabel('Energy')
ax.legend()
plt.tight_layout()
plt.show()