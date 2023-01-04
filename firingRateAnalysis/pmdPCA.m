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
% temp = load("/home/tianwang/code/behaviorRNN/PsychRNN/temp.mat").temp;
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

%% get r from x
% % vanilla
% temp = max(temp, 0);

% additive
% gainThresh = round(checker.decision_time + checker.target_onset + checker.checker_onset, -1)/10;
% for id = 1 : size(temp, 3)
%     tempGain = checker.g0(id);
%     for idx = 1:gainThresh(id)
%         temp(:,idx,id) = temp(:, idx,id) + tempGain;
%     end
% end
% temp = max(temp, 0);

% multiplicative
% for id = 1 : size(temp, 3)
%     tempGain = checker.g0(id);
%     temp(:,:,id) = temp(:,:,id).*tempGain;
% end
% temp = max(temp, 0);

%% only choose trials with 95% RT
sortRT = sort(checker.decision_time);
disp("95% RT threshold is: " + num2str(sortRT(5000*0.95)))
% rtThresh = checker.decision_time <= sortRT(5000*0.95);
rtThresh = checker.decision_time >= 100 & checker.decision_time < sortRT(size(checker,1)*0.95);
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

% left & right trials
right = checker.decision == 1;
left = checker.decision == 0;

% state activity alignes to checkerboard onset, with 200ms before and 800
% ms after
before = 100;
after = 800;

alignState = [];
for ii = 1 : c
    zeroPt = checkerOnR(ii)./10 + 1;
    alignState(:,:,ii) = temp(:,zeroPt - before/10+1:zeroPt + after/10, ii);
end

[a, b, c] = size(alignState);

%% reshape data and do pca
test = reshape(alignState, [a, b*c])';

[coeff, score, latent] = pca(test);
orthF = [];
for thi = 1 : c
    orthF(:,:,thi) = (score( (1:b) + (thi-1)*b, :))';
end

%% based on coherence: 2 input-RNN
aveGain = [];
cc = jet(11);
figure();
coh = unique(checker.coherence_bin);
for ii  = 1 : ceil(length(coh)/2)-1
    selectedTrials = (checker.coherence_bin == coh(ii) | checker.coherence_bin == -coh(ii));

    leftSelect = selectedTrials & left;
    rightSelect = selectedTrials & right;
    leftTrajAve = mean(orthF([1 2 3],:,leftSelect), 3);
    rightTrajAve = mean(orthF([1 2 3],:,rightSelect), 3);
      
    % left and right average RT of each RT bin    
    leftAveRT = round(mean(RTR(leftSelect))./10) + before/10;
    rightAveRT = round(mean(RTR(rightSelect))./10) + before/10;
    
    
    % left & right select gains
%     aveGain(1,ii) = mean(checker.g0(leftSelect));
%     aveGain(2,ii) = mean(checker.g0(rightSelect));
    
    % plot left trajs
    plot3(leftTrajAve(1,1:leftAveRT), leftTrajAve(2,1:leftAveRT),leftTrajAve(3,1:leftAveRT), 'color', cc(ii,:), 'linestyle', '--', 'linewidth', 2);
    hold on
    % mark the checkerboard onset
    plot3(leftTrajAve(1,before/10), leftTrajAve(2,before/10),leftTrajAve(3,before/10), 'color', cc(ii,:), 'marker', 'd', 'markerfacecolor',cc(ii,:),'markersize', 10);
    % mark the RT (end time)
    plot3(leftTrajAve(1,leftAveRT), leftTrajAve(2,leftAveRT),leftTrajAve(3,leftAveRT), 'color', 'k', 'marker', '.', 'markersize', 25);
    
    % plot right trajs
    plot3(rightTrajAve(1,1:rightAveRT), rightTrajAve(2,1:rightAveRT),rightTrajAve(3,1:rightAveRT), 'color', cc(ii,:), 'linewidth', 2);
    hold on
    % mark the checkerboard onset
    plot3(rightTrajAve(1,before/10), rightTrajAve(2,before/10),rightTrajAve(3,before/10), 'color', cc(ii,:), 'marker', 'd', 'markerfacecolor',cc(ii,:), 'markersize', 10);
    % mark the RT (end time)
    plot3(rightTrajAve(1,rightAveRT), rightTrajAve(2,rightAveRT),rightTrajAve(3,rightAveRT), 'color', 'k', 'marker', '.', 'markersize', 25);
     
%     pause()
end

%% based on RT

% the trials definitely have more trials with fastere RT, so the long RT
% trajs are messy

% total data: 500ms before checkerboard onset to 2000ms after checkerboard
% onset. So max RT that can be plotted is 2000ms

rt = [100 250:50:700 1200];
rt = 100:100:800;

rt = [prctile(RTR,[20:10:90])];

% rt = [100 250 400 600 800];
% rt = [100:40:340 600];
% rt = [100 175 250:50:500 1200];

cc = [
   0.6091    0.2826    0.7235
    0.4279    0.3033    0.6875
    0.2588    0.3136    0.6353
    0.2510    0.4118    0.6980
    0.1765    0.6312    0.8588
    0.1412    0.7450    0.8863
    0.3686    0.7490    0.5491
    0.8941    0.7764    0.1530
    0.8980    0.6548    0.1686
    0.8863    0.5295    0.1608
    0.8980    0.4155    0.1647
]


% cc = jet(length(rt));

% blue to red as RT increases
% left: -; right: --
figure(); 
distV = [];
nTrials = [];
for ii  = 1:length(rt)-1
    selectedTrials = (rt(ii) < RTR & RTR < rt(ii + 1));

    leftSelect = selectedTrials & left;
    rightSelect = selectedTrials & right;
    leftTrajAve = mean(orthF([1 2  3  ],:,leftSelect), 3);
    rightTrajAve = mean(orthF([1 2 3 ],:,rightSelect), 3);
    
    nTrials(ii) = sum(leftSelect)
  
    % left and right average RT of each RT bin
%     leftAveRT = round(mean(RTR(leftSelect))./10) + 50;
%     rightAveRT = round(mean(RTR(rightSelect))./10) + 50;

    leftAveRT = round(min(RTR(leftSelect))./10) + before/10;
    rightAveRT = round(min(RTR(rightSelect))./10) + before/10;
    
    
    %3D plot
    % plot left trajs
    plot3(leftTrajAve(1,1:leftAveRT), leftTrajAve(2,1:leftAveRT),leftTrajAve(3,1:leftAveRT), 'color', cc(ii,:), 'linewidth', 2);
    hold on
    % mark the checkerboard onset
    plot3(leftTrajAve(1,before/10), leftTrajAve(2,before/10),leftTrajAve(3,before/10), 'color', 'r', 'marker', '.', 'markersize', 25);
    % mark the RT (end time)
    plot3(leftTrajAve(1,leftAveRT), leftTrajAve(2,leftAveRT),leftTrajAve(3,leftAveRT), 'color', cc(ii,:), 'marker', 'd', 'markerfacecolor',cc(ii,:),'markersize', 10);
    
    % plot right trajs
    plot3(rightTrajAve(1,1:rightAveRT), rightTrajAve(2,1:rightAveRT),rightTrajAve(3,1:rightAveRT), 'color', cc(ii,:), 'linestyle', '--', 'linewidth', 2);
    hold on
    % mark the checkerboard onset
    plot3(rightTrajAve(1,before/10), rightTrajAve(2,before/10),rightTrajAve(3,before/10), 'color', 'r', 'marker', '.', 'markersize', 25);
    % mark the RT (end time)
    plot3(rightTrajAve(1,rightAveRT), rightTrajAve(2,rightAveRT),rightTrajAve(3,rightAveRT), 'color', cc(ii,:), 'marker', 'd', 'markerfacecolor',cc(ii,:),'markersize', 10);

    title("Left trials: " + sum(leftSelect) + " Right trials: " + sum(rightSelect));
    
%     iXl = find(leftSelect);
%     iXr = find(rightSelect);
%     Nl = randi(length(iXl),1,max(length(iXl),80));
%     Nr = randi(length(iXr),1,max(length(iXr),80));
%     
%     distV(ii,:) = (sum(abs(nanmean(abs(orthF(1:10,:,iXl(Nl))),3)-nanmean(abs(orthF(1:10,:,iXr(Nr))),3))));

    
end
% 
% set(gcf, 'Color', 'w');
% axis off; 
% axis square;
% axis tight;
% 
% set(gca, 'LooseInset', [ 0 0 0 0 ]);
% xlabel('PC1');
% ylabel('PC2');
% zlabel('PC3');
% title('PCA based on RT', 'fontsize', 30);
% axis vis3d;
% 
% % vanilla: view: [-63 59]
% % multiplicative: view: [-93 -61]
% % additive: view: [110 -20]
% 
% view([-154 41])
% tv = ThreeVector(gca);
% tv.axisInset = [0.2 0.2]; % in cm [left bottom]
% tv.vectorLength = 2; % in cm
% tv.textVectorNormalizedPosition = 1.3; 
% tv.fontSize = 15; % font size used for axis labels
% tv.fontColor = 'k'; % font color used for axis labels
% tv.lineWidth = 3; % line width used for axis vectors
% tv.lineColor = 'k'; % line color used for axis vectors
% tv.update();
% rotate3d on;
% 
% % print('-painters','-depsc',['~/Desktop/', 'PCAdelayC','.eps'], '-r300');
% 
% axis equal
%%

for condId = 1:size(distV,1)
    subplot(211);
    plot(distV(condId,:),'color',cc(condId,:));
    hold on;
    
    subplot(212)
    plot(abs(diff(distV(condId,1:5:end))),'color',cc(condId,:));
    hold on;
end




%% based on RT

% the trials definitely have more trials with fastere RT, so the long RT
% trajs are messay

% total data: 500ms before checkerboard onset to 2000ms after checkerboard
% onset. So max RT that can be plotted is 2000ms

% rt = [100 250:50:700 1200];
rt = 100:100:800;
% rt = 100:50:450

cc = jet(length(rt));

cc = [
   0.6091    0.2826    0.7235
%     0.4279    0.3033    0.6875
    0.2588    0.3136    0.6353
    0.2510    0.4118    0.6980
    0.1765    0.6312    0.8588
%     0.1412    0.7450    0.8863
    0.3686    0.7490    0.5491
%     0.8941    0.7764    0.1530
    0.8980    0.6548    0.1686
%     0.8863    0.5295    0.1608
    0.8980    0.4155    0.1647
]
% blue to red as RT increases
% left: --; right: -
figure();
distV = [];
nTrials = [];
for ii  = 1:length(rt)-1
    selectedTrials = (rt(ii) < RTR & RTR < rt(ii + 1));

    leftSelect = selectedTrials & left;
    rightSelect = selectedTrials & right;
    leftTrajAve = mean(orthF([1 2 3],:,leftSelect), 3);
    rightTrajAve = mean(orthF([1 2 3],:,rightSelect), 3);
    
    nTrials(ii) = sum(leftSelect)
  
    % left and right average RT of each RT bin
%     leftAveRT = round(mean(RTR(leftSelect))./10) + 50;
%     rightAveRT = round(mean(RTR(rightSelect))./10) + 50;

    leftAveRT = round(min(RTR(leftSelect))./10) + 50;
    rightAveRT = round(min(RTR(rightSelect))./10) + 50;
    
    
    %3D plot
    % plot left trajs
    plot3(leftTrajAve(1,1:leftAveRT), leftTrajAve(2,1:leftAveRT),leftTrajAve(3,1:leftAveRT), 'color', cc(ii,:), 'linewidth', 2);
    hold on
    % mark the checkerboard onset
    plot3(leftTrajAve(1,50), leftTrajAve(2,50),leftTrajAve(3,50), 'color', 'r', 'marker', '.', 'markersize', 25);
    % mark the RT (end time)
    plot3(leftTrajAve(1,leftAveRT), leftTrajAve(2,leftAveRT),leftTrajAve(3,leftAveRT), 'color', cc(ii,:), 'marker', 'd', 'markerfacecolor',cc(ii,:),'markersize', 10);
    
    % plot right trajs
    plot3(rightTrajAve(1,1:rightAveRT), rightTrajAve(2,1:rightAveRT),rightTrajAve(3,1:rightAveRT), 'color', cc(ii,:), 'linestyle', '--', 'linewidth', 2);
    hold on
    % mark the checkerboard onset
    plot3(rightTrajAve(1,50), rightTrajAve(2,50),rightTrajAve(3,50), 'color', 'r', 'marker', '.', 'markersize', 25);
    % mark the RT (end time)
    plot3(rightTrajAve(1,rightAveRT), rightTrajAve(2,rightAveRT),rightTrajAve(3,rightAveRT), 'color', cc(ii,:), 'marker', 'd', 'markerfacecolor',cc(ii,:),'markersize', 10);

    title("Left trials: " + sum(leftSelect) + " Right trials: " + sum(rightSelect));
    
    iXl = find(leftSelect);
    iXr = find(rightSelect);
    Nl = randi(length(iXl),1,max(length(iXl),80));
    Nr = randi(length(iXr),1,max(length(iXr),80));
    
    distV(ii,:) = (sum(abs(nanmean(abs(orthF(1:10,:,iXl(Nl))),3)-nanmean(abs(orthF(1:10,:,iXr(Nr))),3))));

end

set(gcf, 'Color', 'w');
axis off; 
axis square;
axis tight;

set(gca, 'LooseInset', [ 0 0 0 0 ]);
xlabel('PC1');
ylabel('PC2');
zlabel('PC3');
title('PCA based on RT', 'fontsize', 30);
axis vis3d;

% vanilla: view: [170 25]
% multiplicative: view: [128 -8]
% additive: view: [110 -20]

view([110,-20])
tv = ThreeVector(gca);
tv.axisInset = [0.2 0.2]; % in cm [left bottom]
tv.vectorLength = 2; % in cm
tv.textVectorNormalizedPosition = 1.8; 
tv.fontSize = 15; % font size used for axis labels
tv.fontColor = 'k'; % font color used for axis labels
tv.lineWidth = 3; % line width used for axis vectors
tv.lineColor = 'k'; % line color used for axis vectors
tv.update();
rotate3d on;

% print('-painters','-depsc',['./resultFigure/', 'PCAMr','.eps'], '-r300');