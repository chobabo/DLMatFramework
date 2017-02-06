%% Test the creation/training of a 2 layer 2 class(not binary) classifier
% Follow tensorflow tutorial
% https://www.tensorflow.org/tutorials/mnist/pros/
% https://github.com/aymericdamien/TensorFlow-Examples/blob/master/notebooks/3_NeuralNetworks/convolutional_network.ipynb
% https://github.com/aymericdamien/TensorFlow-Examples/blob/master/examples/3_NeuralNetworks/convolutional_network.py

clear all;

% Reset random number generator state, this is needed in order to make the
% weight initialization go work
rng(0,'v5uniform');

%% Load data
load mnist_oficial;
data = Dataset(input_train, output_train_labels,28,28,1,1,true);
data.AddValidation(input_test,output_test_labels,28,28,1,1,true);

%% Create network
layers = LayerContainer();    
layers <= struct('name','ImageIn','type','input','rows',28,'cols',28,'depth',1, 'batchsize',1);
layers <= struct('name','CONV1','type','conv', 'num_output',200); % K:5 Input:1 Output:32 stride:1 pad 2
layers <= struct('name','Relu_1','type','relu');
layers <= struct('name','MP1','type','maxpool'); % K:2 stride:2
layers <= struct('name','CONV2','type','fc', 'num_output',100); % K:5 Input:32 Output:64 stride:1 pad 2
layers <= struct('name','Relu_2','type','relu');
layers <= struct('name','MP2','type','maxpool'); % K:2 stride:2
layers <= struct('name','FC_3','type','fc', 'num_output',1024);
layers <= struct('name','Relu_3','type','relu');
layers <= struct('name','DRP_1','type','dropout','prob',0.5);
layers <= struct('name','FC_4','type','fc','num_output',data.GetNumClasses());
layers <= struct('name','Softmax','type','softmax');

% Create DeepLearningModel instance
net = DeepLearningModel(layers, LossFactory.GetLoss('multi_class_cross_entropy'));


%% Create solver and train
solver = Solver(net, data, 'sgd',containers.Map({'learning_rate', 'L2_reg'}, {0.01, 0}));
solver.SetBatchSize(200);
solver.SetEpochs(60);
solver.Train();

%% Test
testBatchSize = size(input_test,1);
figure(2);
batchValidation = data.GetValidationBatch(testBatchSize);
batchImg = gather(batchValidation.X(:,:,:,1:20));
display_MNIST_Data(reshape_row_major(batchImg,[20,784]));
title('Images on validation');
errorCount = 0;

% Predict the batch
scores = net.Predict(batchValidation.X);
[~, idxScoresMax] = max(scores,[],2);
[~, idxCorrect] = max(batchValidation.Y,[],2);
% Subtract one (First class )
idxScoresMax = idxScoresMax - 1;
idxCorrect = idxCorrect - 1;

% Compare scores with target
for idx=1:testBatchSize    
    if idxScoresMax(idx) ~= idxCorrect(idx)
        errorCount = errorCount + 1;
        fprintf('Predicted %d and should be %d\n',idxScoresMax(idx),idxCorrect(idx));
    end    
end
errorPercentage = (errorCount*100) / testBatchSize;
fprintf('Validation Accuracy is %d percent \n',round((100-errorPercentage)));
figure;
plot(solver.GetLossHistory)