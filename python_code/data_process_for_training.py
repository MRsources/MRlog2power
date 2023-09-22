import pandas as pd
import re
import numpy as np
import matplotlib.pyplot as plt
from datetime import datetime

# read selected log data set
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
    100: 14,
    103: 50,
    104: 15
}
# This will replace each old ID with the corresponding new ID in the 'ID_sel' column
df1['ID_sel'] = df1['ID_sel'].map(lambda x: id_mapping.get(x, x))
t_sel = df1['t_sel']
seq_sel = df1['seq_sel']
ID_sel = df1['ID_sel']
dt_sel_shifted = t_sel - pd.Timedelta(minutes=2.3)

# Find unique sequence types and encode them with an ID
seq_sel_filled = seq_sel.fillna('none')
uniqueSeq, seqIDs = np.unique(seq_sel_filled, return_inverse=True)

LOGEVENT = pd.DataFrame({
    'ID_sel': ID_sel.values,
    'seqIDs': seqIDs,
    'duration': t_sel.diff().dt.total_seconds().div(3600).shift(-1).fillna(0)
})

# read the raw Time-Energy dataset
df2 = pd.read_csv('D:\\360MoveData\\Users\\DELL\\Desktop\\hiwi_work\\log_energy_1\\mr3-energy-2015-conv.txt', sep='\t', header=None, names=['T', 'KW_raw'])
df2['T'] = pd.to_datetime(df2['T'], format='%Y%m%d%H%M%S', errors='coerce')

# Reduce data for display (taking 1/10th of the data)
reduced_length = int(len(df2) / 10)
df2_reduced = df2.iloc[:reduced_length].copy()

# Calculate cumulative sum of KW_raw
KW_raw = df2_reduced['KW_raw']
KWH_raw = KW_raw.cumsum()

# Find the indices where dt_sel_shifted exists in df2_reduced['T']
dT = df2_reduced['T']
loc = dt_sel_shifted.isin(dT)

# Merge the two DataFrames on the timestamp columns and keep the index from df2_reduced
merged_data = pd.merge(dT.reset_index(), dt_sel_shifted, left_on='T', right_on='t_sel', how='inner')

# Extract the indices from the merged DataFrame
locb = merged_data['index']
locb = locb[locb != 0]
diff_time = np.diff(dT[locb].astype('datetime64'))

# Calculate lookup_E and KW_raw_sel
lookup_E_partial = np.diff(KWH_raw[locb]) / diff_time.astype('timedelta64[s]').astype(float)
lookup_E = np.append(lookup_E_partial, KW_raw.iloc[-1])
KW_raw_sel = KW_raw[locb]

# Replace NaN values in lookup_E with corresponding KW_raw_sel values
lookup_E[np.isnan(lookup_E)] = KW_raw_sel[np.isnan(lookup_E)]

# Extracting lookup_T
lookup_T = dT[locb]
lookup_T_reset = lookup_T.reset_index(drop=True)

ENERGY = []
for input_datetime in dt_sel_shifted:
    # Calculate the absolute difference between lookup_T and input_datetime
    diffs = abs((lookup_T_reset - pd.Timestamp(input_datetime)).dt.total_seconds())
    diffs = diffs.sort_values(ascending=False, key=lambda x: x.values)

    # Find the index of the minimum difference
    idx = diffs.idxmin()

    # Retrieve the energy from lookup_E using the index
    energy = lookup_E[idx]
    ENERGY.append(energy)

# Convert the list to a NumPy array for further processing
ENERGY = np.array(ENERGY)

# Save the processed data for training input and target
LOGEVENT.to_csv('LOGEVENT.csv', index=False)
np.savetxt('ENERGY.csv', ENERGY, delimiter=',')

fig, ax = plt.subplots(figsize=(16, 8))
ax.plot(dT, KW_raw, drawstyle='steps', linestyle='-', label="original energy", color='blue', picker=True)
ax.plot(dt_sel_shifted, lookup_E , drawstyle='steps', linestyle='-', label="average energy", color='red', picker=True)

