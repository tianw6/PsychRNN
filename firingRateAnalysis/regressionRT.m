clear all; close all; clc

% data:
% temp: checkerPmd recNoise = 0.5
% temp2: checkerPmd recNoise = 0
% gain: checkerPmd with gain recNoise = 0.5
% for linux work station 

% temp = load("/home/tianwang/code/behaviorRNN/PsychRNNArchive/stateActivity/gain.mat").temp;
% checker = readtable("/home/tianwang/code/behaviorRNN/PsychRNN/resultData/checkerPmdGain3Additive.csv");

% for Tian's PC
% temp = load("D:\BU\ChandLab\PsychRNNArchive\stateActivity\temp.mat").temp;
% checker = readtable("D:/BU/chandLab/PsychRNN/resultData/basic2InputNoise0.5.csv");

% for checkerPmd
temp = load("D:\BU\ChandLab\PsychRNNArchive\stateActivity\gain.mat").temp;
checker = readtable("D:/BU/chandLab/PsychRNN/resultData/checkerPmdGain3Additive.csv");


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
% state activity alignes to checkerboard onset, with 500ms before and 2000
% ms after
alignState = [];
for ii = 1 : c
    zeroPt = checkerOnR(ii)./10 + 1;
    alignState(:,:,ii) = temp(:,zeroPt - 50:zeroPt + 200, ii);
end

[a, b, c] = size(alignState);

%%

trials1 = alignState(:,:,left);
trials2 = alignState(:,:,right);

% decoder to predict RT on choice 1 (without using predictRT function)
r2 = zeros(size(trials1,2), 1);

train_x = trials1;
train_y = RT(left);

for ii = 1 : size(train_x,2)
%     t1 = [squeeze(train_x(:,ii,:))', coh(left)];
    t1 = [squeeze(train_x(:,ii,:))'];
    
    md1 = fitrlinear(t1, train_y, 'learner', 'leastsquares');

    label = predict(md1, t1);
    R = corrcoef(label, train_y);
    R2 = R(1,2).^2;
    r2(ii) = R2;
end


tic
% shuffled r2 of choice 1    
shuffled_r2 = zeros(100, size(trials1,2));

for sIdx = 1 : 100

    R = randperm(size(trials1,3));
    train_x = trials1;
    temp = RT(left);
    train_yS = temp(R);
    
    for ii = 1 : size(train_x,2)

%         t1 = [squeeze(train_x(:,ii,:))', coh(left)];
        t1 = [squeeze(train_x(:,ii,:))'];
        md1 = fitrlinear(t1, train_yS, 'learner', 'leastsquares');

        label = predict(md1, t1);
        R = corrcoef(label, train_yS);
        R2 = R(1,2).^2;
        shuffled_r2(sIdx, ii) = R2;    
    end 

end
    
% calculate bound accuarcy
bounds = zeros(2, size(trials1,2));
percentile = 100/size(shuffled_r2,1);
bounds(1,:) = prctile(shuffled_r2, percentile, 1);
bounds(2,:) = prctile(shuffled_r2, 100 - percentile, 1);

toc

%%

figure;
plot(bounds', '--');
hold on
plot(r2)
xlabel('Bin number')
ylabel('Variance explained')
title('Choice 1 Variance explained of binned spike counts')
xline(50, 'color', [0.5 0.5 0.5], 'linestyle', '--')
xpatch = [0 0 50 50];
ypatch = [0 1 1 0];
p1 = patch(xpatch, ypatch, 'cyan');
p1.FaceAlpha = 0.2;
p1.EdgeAlpha = 0;
xlim([1,250])
ylim([-0.02,1])

%%

% decoder to predict RT on choice 2

 [r2, shuffled_r2, bounds] = predictRT(trials2, RT(right), coh(right));

%% decoder to predict RT on choice 2 (without using predictRT function)


figure;
plot(bounds', '--');
hold on
plot(r2)
xlabel('Bin number')
ylabel('Variance explained')
title('Choice 2 Variance explained of binned spike counts')
xline(50, 'color', [0.5 0.5 0.5], 'linestyle', '--')
xpatch = [0 0 50 50];
ypatch = [0 1 1 0];
p1 = patch(xpatch, ypatch, 'cyan');
p1.FaceAlpha = 0.2;
p1.EdgeAlpha = 0;
xlim([1,250])
ylim([-0.02,1])


%% pre
 r2 = zeros(size(trials2,2), 1);

train_x = trials2;
train_y = RT(right);

for ii = 1 : size(train_x,2)
    t1 = [squeeze(train_x(:,ii,:))', coh(right)];
    md1 = fitrlinear(t1, train_y, 'learner', 'leastsquares');

    label = predict(md1, t1);
    R = corrcoef(label, train_y);
    R2 = R(1,2).^2;
    r2(ii) = R2;
end



% shuffled r2 of choice2    
shuffled_r2 = zeros(100, size(trials2,2));

for sIdx = 1 : 100

    R = randperm(size(trials2,3));
    train_x = trials2;
    temp = RT(right);
    train_yS = temp(R);
    
    for ii = 1 : size(train_x,2)

        t1 = [squeeze(train_x(:,ii,:))', coh(right)];
        md1 = fitrlinear(t1, train_yS, 'learner', 'leastsquares');

        label = predict(md1, t1);
        R = corrcoef(label, train_yS);
        R2 = R(1,2).^2;
        shuffled_r2(sIdx, ii) = R2;    
    end 

end
    
% calculate bound accuarcy
bounds = zeros(2, size(trials1,2));
percentile = 100/size(shuffled_r2,1);
bounds(1,:) = prctile(shuffled_r2, percentile, 1);
bounds(2,:) = prctile(shuffled_r2, 100 - percentile, 1);
