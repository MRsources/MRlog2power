% Split data
trainFcn = 'trainlm';  % Levenberg-Marquardt backpropagation.
% trainFcn = 'trainbr';  % Levenberg-Marquardt backpropagation.
hiddenLayerSize = [20 20 20];
net = fitnet(hiddenLayerSize, trainFcn);
% net = feedforwardnet(hiddenSizes,trainFcn)

% Choose Input and Output Pre/Post-Processing Functions
% net.input.processFcns = {'removeconstantrows','mapminmax'};
% net.output.processFcns = {'removeconstantrows','mapminmax'};

net.trainParam.max_fail=600;
 
% Split Data for Training, Validation, Testing
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 15/100;
net.divideParam.testRatio = 15/100;

[net,tr] = train(net,LOGEVENT,ENERGY,'useParallel','yes','showResources','yes');

% E = net(LOGEVENT(:,3000))
% E = lay4(LOGEVENT(:,3000))

dt_sel_shifted(3000)

% Performance on test data
testPerformance = mse(net, y, yPred, tr.testMask);
disp(['MSE on Test Data: ', num2str(testPerformance)]);


figure, hold on
plot(x, y, 'b')
plot(x, yPred, 'r--')
legend('Actual','Predicted')
title('Feedforward Neural Network Prediction')
hold off

