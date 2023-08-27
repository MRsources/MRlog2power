% Split data
trainFcn = 'trainlm';  % Levenberg-Marquardt backpropagation.
trainFcn = 'trainbr';  % Levenberg-Marquardt backpropagation.
hiddenLayerSize = [10 20 10];
net = fitnet(hiddenLayerSize, trainFcn);
% net = feedforwardnet(hiddenSizes,trainFcn)

% Choose Input and Output Pre/Post-Processing Functions
% net.input.processFcns = {'removeconstantrows','mapminmax'};
% net.output.processFcns = {'removeconstantrows','mapminmax'};

net.input.processFcns = {'mapminmax'};
net.output.processFcns = {'mapminmax'};

net.trainParam.max_fail=600;
net.trainParam.epochs=3000;
% Split Data for Training, Validation, Testing
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 15/100;
net.divideParam.testRatio = 15/100;

[net,tr] = train(net,LOGEVENT_train,ENERGY_train,'useParallel','yes','showResources','yes');

% E = net(LOGEVENT(:,3000))
% E = lay4(LOGEVENT(:,3000))

dt_sel_shifted(3000)


