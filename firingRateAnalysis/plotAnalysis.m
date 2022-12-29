% Created by Tian Wang on Dec.29th 2022: plot analysis of pmdPCA.m;
% regressionRT.m and predictChoice.m together 

% aligned to checkerboard
clear all; close all; clc

% On linux work station (for checkerPmd)

% addpath('/net/derived/tianwang/LabCode');
% 

% vanilla RNN
% temp = load("/net/derived/tianwang/psychRNNArchive/stateActivity/vanilla2022.mat").temp;
% checker = readtable("~/code/behaviorRNN/PsychRNN/checkerPmdBasic.csv");

% RNN with g0 additive
% temp = load("/net/derived/tianwang/psychRNNArchive/stateActivity/gain3.mat").temp;
% checker = readtable("~/Downloads/PsychRNN/checkerPmdGain3Additive.csv");

% temp = load("/net/derived/tianwang/psychRNNArchive/stateActivity/gainA2022.mat").temp;
% checker = readtable("~/code/behaviorRNN/PsychRNN/checkerPmdGain3Additive.csv");


% % RNN with multiplicative gain
temp = load("/net/derived/tianwang/psychRNNArchive/stateActivity/gainM2022.mat").temp;
checker = readtable("~/code/behaviorRNN/PsychRNN/checkerPmdGain4Multiply.csv");


% initial bias
% temp = load("/net/derived/tianwang/psychRNNArchive/stateActivity/init2022.mat").temp;
% checker = readtable("/home/tianwang/code/behaviorRNN/PsychRNN/checkerPmdInit.csv");

% delay
% temp = load("/net/derived/tianwang/psychRNNArchive/stateActivity/delayCorr.mat").temp;
% checker = readtable("~/code/behaviorRNN/PsychRNN/checkerPmdDelayCorr.csv");

% On Tian's PC (for checkerPmd)

% RNN with g0 additive
% temp = load("D:\BU\ChandLab\PsychRNNArchive\stateActivity\gainA2022.mat").temp;
% checker = readtable("D:\BU\ChandLab\PsychRNN\checkerPmdGain3Additive.csv");


% RNN with multiplicative gain
% temp = load("D:\BU\ChandLab\PsychRNNArchive\stateActivity\gainM2022.mat").temp;
% checker = readtable("D:/BU/chandLab/PsychRNN/checkerPmdGain4Multiply.csv");

% initial bias
% temp = load("D:\BU\ChandLab\PsychRNN\temp.mat").temp;
% checker = readtable("D:/BU/chandLab/PsychRNN/checkerPmdInit.csv");

% delay
% temp = load("D:\BU\ChandLab\PsychRNNArchive\stateActivity\delay.mat").temp;
% checker = readtable("D:/BU/chandLab/PsychRNN/resultData/checkerPmdDelay.csv");

%% only choose trials with 95% RT
sortRT = sort(checker.decision_time);
disp("95% RT threshold is: " + num2str(sortRT(5000*0.95)))
% rtThresh = checker.decision_time <= sortRT(5000*0.95);
rtThresh = checker.decision_time >= 0 & checker.decision_time < sortRT(size(checker,1)*0.95);
checker = checker(rtThresh, :);
temp = temp(:,:,rtThresh);

[a, b, c] = size(temp);

%% align data to checkerboard onset (target onset)

% reaction time; targetOn time and checkerOn time
RT = checker.decision_time;
targetOn = checker.target_onset;
checkerOn = checker.checker_onset;

% real RT, targetOn and checkerOn round to 10's digit
RTR = round(RT, -1);
targetOnR = round(targetOn,-1);
checkerOnR = round(checkerOn + targetOn, -1);


% % left & right trials
% right = checker.decision == 1;
% left = checker.decision == 0;
% 
% coh = checker.coherence;

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

%% plot pca plots: 

figure;
set(gcf,'position',[1000,1000,2000,600])



options.handle = subplot(1,3,1);
options.span = [-before, after];
options.type = 'RT';
options.rtBin = 50:50:400;
options.rtThreshold = 200;
% options.thresholdSide = 'less';
% figure handle; before & after; switch between coh and RT pca; RT bins
generatePCA(alignState, checker, options);


%% plot RT regression


% figure handle; 
[r2, r2_coh] = predictRT(alignState, checker);

subplot(1,3,2); hold on

t = linspace(-before+20, after, length(r2));

ylimit = 0.7;
xpatch = [-before -before 0 0];
ypatch = [ylimit 0 0 ylimit];
p1 = patch(xpatch, ypatch, 'cyan');
p1.FaceAlpha = 0.2;
p1.EdgeAlpha = 0;

% plot(t, bounds', '--', 'linewidth', 5);
plot(t, r2, 'linewidth', 5, 'color', [236 112  22]./255)
yline(r2_coh)

plot([0,0], [ylimit,0], 'color', [0.5 0.5 0.5], 'linestyle', '--', 'linewidth',5)
title('Regression on RT', 'fontsize', 30)

% 
% % cosmetic code
% hLimits = [-before,after];
% hTickLocations = -before:200:after;
% hLabOffset = 0.05;
% hAxisOffset =  -0.011;
% hLabel = "Time: ms"; 
% 
% vLimits = [0,ylimit];
% vTickLocations = [0 ylimit/2 ylimit];
% vLabOffset = 150;
% vAxisOffset = -220;
% vLabel = "R^{2}"; 
% 
% plotAxis = [1 1];
% 
% [hp,vp] = getAxesP(hLimits,...
%     hTickLocations,...
%     hLabOffset,...
%     hAxisOffset,...
%     hLabel,...
%     vLimits,...
%     vTickLocations,...
%     vLabOffset,...
%     vAxisOffset,...
%     vLabel, plotAxis);
% 
% set(gcf, 'Color', 'w');
% axis off; 
% axis square;
% axis tight;

% 
% save('./resultData/boundAr.mat', 'bounds');
% save('./resultData/r2Ar.mat', 'r2');
% print('-painters','-depsc',['~/Desktop/', 'RTdelayC','.eps'], '-r300');


%% plot decoder results

% figure handle;fast or slow
accuracy = predictChoice(alignState, checker, options, 'less');

t = linspace(-before+20, after, length(accuracy));

subplot(1,3,3); hold on
plot(t, accuracy,'linewidth', 3)
yline(0.5, 'k--')
xlabel('Time (ms)')
ylabel('Accuracy')
title('Prediction accuracy')


accuracy = predictChoice(alignState, checker, options, 'greater');
subplot(1,3,3); hold on
plot(t, accuracy,'linewidth', 3)
yline(0.5, 'k--')
xlabel('Time (ms)')
ylabel('Accuracy')
title('Prediction accuracy')

% yLower = 0.4;
% yUpper = 1;
% 
% xline(0, 'color', [0.5 0.5 0.5], 'linestyle', '--')
% xpatch = [yLower yLower -before -before];
% ypatch = [yLower yUpper yUpper yLower];
% p1 = patch(xpatch, ypatch, 'cyan');
% p1.FaceAlpha = 0.2;
% p1.EdgeAlpha = 0;


% 
% 
% % cosmetic code
% hLimits = [-before,after];
% hTickLocations = -before:200:after;
% hLabOffset = 0.05;
% hAxisOffset =  yLower - 0.01;
% hLabel = "Time: ms"; 
% 
% 
% vLimits = [yLower,yUpper];
% vTickLocations = [yLower (yLower + yUpper)/2 yUpper];
% 
% 
% vLabOffset = 150;
% vAxisOffset = -220;
% vLabel = "Accuracy"; 
% 
% plotAxis = [1 1];
% 
% [hp,vp] = getAxesP(hLimits,...
%     hTickLocations,...
%     hLabOffset,...
%     hAxisOffset,...
%     hLabel,...
%     vLimits,...
%     vTickLocations,...
%     vLabOffset,...
%     vAxisOffset,...
%     vLabel, plotAxis);
% 
% set(gcf, 'Color', 'w');
% axis off; 
% axis square;
% axis tight;

% print('-painters','-depsc',['~/Desktop/', 'DecoderdelayC','.eps'], '-r300');












