import torch
import torch.nn as nn
import torch.optim as optim
from tqdm import tqdm
from sklearn.metrics import mean_squared_error

def train_model(model, X_train, y_train, X_val, y_val, X_test, y_test, learning_rate, batch_size, num_epochs, device):
    # Define loss function and optimizer
    criterion = nn.MSELoss()
    optimizer = optim.Adam(model.parameters(), lr=learning_rate)
    train_losses = []
    val_losses = []
    test_losses = []
    progress_bar = tqdm(range(num_epochs), desc='Training Progress')

    for epoch in progress_bar:
        # Initialize loss accumulators
        total_train_loss = 0.0
        total_val_loss = 0.0
        total_test_loss = 0.0

        num_train_batches = 0
        num_val_batches = 0
        num_test_batches = 0

        indices = torch.randperm(X_train.size(0))
        X_shuffled = X_train[indices]
        y_shuffled = y_train[indices]

        # Batch training
        for i in range(0, len(X_shuffled), batch_size):
            inputs = X_shuffled[i:i + batch_size].clone().detach().requires_grad_(True)
            targets = y_shuffled[i:i + batch_size].clone().detach().requires_grad_(True)
            inputs = inputs.to(device)
            targets = targets.to(device)

            # Forward propagation
            outputs = model(inputs)
            train_loss = criterion(outputs.squeeze(), targets)

            # Backpropagation and optimization
            optimizer.zero_grad()
            train_loss.backward()
            optimizer.step()
            total_train_loss += train_loss.item()
            num_train_batches += 1

        # Calculate validation loss
        with torch.no_grad():
            inputs = X_val.to(device)
            targets = y_val.to(device)
            outputs = model(inputs)
            val_loss = criterion(outputs.squeeze(), targets)
            total_val_loss += val_loss.item()
            num_val_batches += 1
        # average_train_loss = total_train_loss / num_train_batches
        # average_val_loss = total_val_loss / num_val_batches
        # train_losses.append(average_train_loss)
        # val_losses.append(average_val_loss)

        # Calculate test loss
        with torch.no_grad():
            inputs = X_test.to(device)
            targets = y_test.to(device)
            outputs = model(inputs)
            test_loss = criterion(outputs.squeeze(), targets)
            total_test_loss += test_loss.item()
            num_test_batches += 1

        # Calculate average losses
        average_train_loss = total_train_loss / num_train_batches
        average_val_loss = total_val_loss / num_val_batches
        average_test_loss = total_test_loss / num_test_batches

        # Append to loss lists
        train_losses.append(average_train_loss)
        val_losses.append(average_val_loss)
        test_losses.append(average_test_loss)

        progress_bar.set_postfix({'Train Loss': average_train_loss, 'Val Loss': average_val_loss, 'Test Loss': average_test_loss})
        # Save the model after each epoch
        torch.save(model, 'model.pth')

    progress_bar.close()
    return train_losses, val_losses, test_losses
