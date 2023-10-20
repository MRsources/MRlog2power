from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
from train_model import train_model
import torch
import numpy as np
import pandas as pd
from model import NeuralNet
import matplotlib.pyplot as plt

# Load the processed data
LOGEVENT = pd.read_csv('LOGEVENT.csv')
ENERGY = np.loadtxt('ENERGY.csv', delimiter=',')

# Tweak ENERGY values based on LOGEVENT
ENERGY[LOGEVENT['ID_sel'] == 15] = 15.3

# One-Hot Encoding for ID_sel and seqIDs
onehot_encoder = OneHotEncoder(sparse=False)
onehot_encoded = onehot_encoder.fit_transform(LOGEVENT[['ID_sel', 'seqIDs']])

# Standardization for duration
scaler = StandardScaler()
duration_scaled = scaler.fit_transform(LOGEVENT[['duration']])

# Combine processed features
processed_features = np.concatenate([onehot_encoded, duration_scaled], axis=1)
train = int(len(processed_features) - len(processed_features) / 10)
LOGEVENT = processed_features[:train][:5000]
ENERGY = ENERGY[:train][:5000]

# Step 1: First split to create a temporary set
X_temp, X_test, y_temp, y_test = train_test_split(LOGEVENT, ENERGY, test_size=0.15, random_state=42)

# Step 2: Further split the temporary set into training and validation sets
X_train, X_val, y_train, y_val = train_test_split(X_temp, y_temp, test_size=0.1765, random_state=42)

# Convert data to PyTorch tensors
X_train = torch.tensor(X_train, dtype=torch.float32)
y_train = torch.tensor(y_train, dtype=torch.float32)
X_val = torch.tensor(X_val, dtype=torch.float32)  # Convert validation set
y_val = torch.tensor(y_val, dtype=torch.float32)  # Convert validation set
X_test = torch.tensor(X_test, dtype=torch.float32)
y_test = torch.tensor(y_test, dtype=torch.float32)

# Device configuration
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# Number of input features
input_size = X_train.shape[1]

# Create a neural network model instance and move it to the device
model = NeuralNet(input_size=input_size)
model.to(device)

# Train the model
train_losses, val_losses, test_losses = train_model(
    model,
    X_train.to(device), y_train.to(device),
    X_val.to(device), y_val.to(device),  # Add validation set
    X_test.to(device), y_test.to(device),
    learning_rate=0.001,
    batch_size=32,
    num_epochs=2000,
    device=device
)
# Plot training and test losses
plt.plot(train_losses, label='Training Loss')
plt.plot(test_losses, label='Test Loss')
plt.plot(val_losses, label='Val Loss')
plt.legend()
plt.show()

# Evaluate the model on the test set
model.eval()
with torch.no_grad():
    y_pred_test = model(X_test.to(device)).cpu().numpy()

# Calculate Mean Squared Error on the test set
mse_test = mean_squared_error(y_test.cpu().numpy(), y_pred_test)
print('Test MSE:', mse_test)