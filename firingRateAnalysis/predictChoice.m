%% created by Tian Wang
% predict choice based on state activity of RNN 


clear all; close all; clc
% addpath('/net/derived/tianwang/LabCode');

% On linux work station (for checkerPmd)

% vanilla RNN
% temp = load("/net/derived/tianwang/psychRNNArchive/stateActivity/vanilla2022.mat").temp;
% checker = readtable("~/code/behaviorRNN/PsychRNN/checkerPmdBasic.csv");

% RNN with g0 & gSlope additive
% temp = load("/net/derived/tianwang/psychRNNArchive/stateActivity/gainA.mat").temp;
% checker = readtable("~/code/behaviorRNN/PsychRNN/resultData/checkerPmdGain3Additive.csv");

% RNN with g0 additive
% temp = load("/net/derived/tianwang/psychRNNArchive/stateActivity/gainAg0.mat").temp;
% checker = readtable("~/code/behaviorRNN/PsychRNN/resultData/checkerPmdGain3g0.csv");


% RNN with multiplicative gain
% temp = load("/net/derived/tianwang/psychRNNArchive/stateActivity/gainM.mat").temp;
% checker = readtable("~/code/behaviorRNN/PsychRNN/resultData/checkerPmdGain4Multiply.csv");

% temp = load("/net/derived/tianwang/psychRNNArchive/stateActivity/gainM2022.mat").temp;
% checker = readtable("~/code/behaviorRNN/PsychRNN/checkerPmdGain4Multiply.csv");


% initial bias
% temp = load("/net/derived/tianwang/psychRNNArchive/stateActivity/init.mat").temp;
% checker = readtable("~/code/behaviorRNN/PsychRNN/resultData/checkerPmdInit.csv");

% delay
temp = load("/net/derived/tianwang/psychRNNArchive/stateActivity/delayCorr.mat").temp;
checker = readtable("~/code/behaviorRNN/PsychRNN/checkerPmdDelayCorr.csv");


% On Tian's PC (for checkerPmd)

% vanilla RNN
% temp = load("D:\BU\ChandLab\PsychRNNArchive\stateActivity\temp.mat").temp;
% checker = readtable("D:/BU/chandLab/PsychRNN/resultData/checkerPmdBasic2InputNoise0.75.csv");

% RNN with g0 & gSlope additive
% temp = load("D:\BU\ChandLab\PsychRNNArchive\stateActivity\gainA.mat").temp;
% checker = readtable("D:/BU/chandLab/PsychRNN/resultData/checkerPmdGain3Additive.csv");

% RNN with g0 additive
% temp = load("D:\BU\ChandLab\PsychRNNArchive\stateActivity\gainAg0.mat").temp;
% checker = readtable("D:\BU\ChandLab\PsychRNN\resultData\checkerPmdGain3g0.csv");

% RNN with multiplicative gain
% temp = load("D:\BU\ChandLab\PsychRNNArchive\stateActivity\gainM.mat").temp;
% checker = readtable("D:/BU/chandLab/PsychRNN/resultData/checkerPmdGain4Multiply.csv");

% initial bias
% temp = load("D:\BU\ChandLab\PsychRNNArchive\stateActivity\init.mat").temp;
% checker = readtable("D:/BU/chandLab/PsychRNN/resultData/checkerPmdInit.csv");

% delay
% temp = load("D:\BU\ChandLab\PsychRNNArchive\stateActivity\delay.mat").temp;
% checker = readtable("D:/BU/chandLab/PsychRNN/resultData/checkerPmdDelay.csv");

%% only choose trials with 95% RT
sortRT = sort(checker.decision_time);
disp("95% RT threshold is: " + num2str(sortRT(5000*0.95)))
% rtThresh = checker.decision_time <= sortRT(5000*0.95);
rtThresh = checker.decision_time >= 100;

checker = checker(rtThresh, :);
temp = temp(:,:,rtThresh);

[a, b, c] = size(temp);

%% align data to checkerboard onset (target onset)
RT = checker.decision_time;
targetOn = checker.target_onset;
checkerOn = checker.checker_onset;
targetOnR = round(targetOn,-1);
checkerOnR = round(checkerOn + targetOn, -1);

left = checker.decision == 0;
right = checker.decision == 1;
coh = checker.coherence;

% state activity alignes to checkerboard onset, with 200ms before and 800
% ms after
before = 200;
after = 800;

alignState = [];
for ii = 1 : c
    zeroPt = checkerOnR(ii)./10 + 1;
    alignState(:,:,ii) = temp(:,zeroPt - before/10+1:zeroPt + after/10, ii);
end

[a, b, c] = size(alignState);

%% 

% decoder to predict choice
accuracy = zeros(b, 1);

% equalize left and right trials
c1Trials = find(checker.decision == 0);
c2Trials = find(checker.decision == 1);
num = min(length(c1Trials), length(c2Trials));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% debug use: print length of each choice 
%     disp(['trial # ' num2str(id)])
%     length(c1Trials)
%     length(c2Trials)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% randomly select 50% total data
index1 = randperm(length(c1Trials));
extract1 = sort(index1(1:num));    
index2 = randperm(length(c2Trials));
extract2 = sort(index2(1:num)); 

% extract trials feed into classifier
extract = [c1Trials(extract1); c2Trials(extract2)];


train_x = alignState(:, :, extract);
train_y = checker.decision(extract) - 1;

for ii = 1 : size(train_x,2)
    fprintf('%d.\n',ii);
    t1 = [squeeze(train_x(:,ii,:))'];

    md1 = fitclinear(t1, train_y, 'learner', 'logistic', 'KFold', 5);

    error = kfoldLoss(md1);
    accuracy(ii) = 1 - error;    
end

%% plot classifier results 

t = linspace(-before, after, length(accuracy));

figure; hold on
plot(t, accuracy,'linewidth', 3)
yline(0.5, 'k--')
xlabel('Time (ms)')
ylabel('Accuracy')
title('Prediction accuracy')


yLower = 0.4;
yUpper = 1;

xline(0, 'color', [0.5 0.5 0.5], 'linestyle', '--')
xpatch = [yLower yLower -before -before];
ypatch = [yLower yUpper yUpper yLower];
p1 = patch(xpatch, ypatch, 'cyan');
p1.FaceAlpha = 0.2;
p1.EdgeAlpha = 0;




% cosmetic code
hLimits = [-before,after];
hTickLocations = -before:200:after;
hLabOffset = 0.05;
hAxisOffset =  yLower - 0.01;
hLabel = "Time: ms"; 


vLimits = [yLower,yUpper];
vTickLocations = [yLower (yLower + yUpper)/2 yUpper];


vLabOffset = 150;
vAxisOffset = -220;
vLabel = "Accuracy"; 

plotAxis = [1 1];

[hp,vp] = getAxesP(hLimits,...
    hTickLocations,...
    hLabOffset,...
    hAxisOffset,...
    hLabel,...
    vLimits,...
    vTickLocations,...
    vLabOffset,...
    vAxisOffset,...
    vLabel, plotAxis);

set(gcf, 'Color', 'w');
axis off; 
axis square;
axis tight;

% print('-painters','-depsc',['~/Desktop/', 'DecoderdelayC','.eps'], '-r300');
