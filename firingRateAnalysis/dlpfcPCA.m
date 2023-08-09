clear all; close all; clc

temp = load("~/code/behaviorRNN/PsychRNN/temp.mat").temp;
checker = readtable("~/code/behaviorRNN/PsychRNN/checkerDLPFC3Test.csv");

% temp = load("D:\BU\ChandLab\PsychRNN\2Areas.mat").temp;
% checker = readtable("D:\BU\ChandLab\PsychRNN\checkerDLPFC32Areas.csv");

%% only choose trials with 95% RT
th = 0.8;

sortRT = sort(checker.decision_time);
disp("95% RT threshold is: " + num2str(sortRT(5000*th)))
% rtThresh = checker.decision_time <= sortRT(5000*0.95);
rtThresh = checker.decision_time >= 0 & checker.decision_time < sortRT(size(checker,1)*th);
checker = checker(rtThresh, :);
temp = temp(:,:,rtThresh);

[a, b, c] = size(temp);

%% align data to target onset

% reaction time; targetOn time and checkerOn time
RT = checker.decision_time;
targetOn = checker.target_onset;
checkerOn = checker.checker_onset;

% real RT, targetOn and checkerOn round to 10's digit
RTR = round(RT, -1);
targetOnR = round(targetOn,-1);
checkerOnR = round(checkerOn + targetOn, -1);


% state activity alignes to targets onset, with 100ms before and 1500
% ms after
before = 100;
after = 1500;

alignState = [];
for ii = 1 : c
    zeroPt = targetOnR(ii)./10 + 1;
    alignState(:,:,ii) = temp(:,zeroPt - before/10:zeroPt + after/10, ii);
end

[a, b, c] = size(alignState);

%% 

% left & right trials
% left decision: 0; right decision: 1
right = checker.decision == 1;
left = checker.decision == 0;

% chosen color
% red: 1; green: 0
RL = left & checker.chosen_color == 1;
RR = right & checker.chosen_color == 1;
GL = left & checker.chosen_color == 0;
GR = right & checker.chosen_color == 0;

firingRateAverage(:,1,1,:) = mean(alignState(:,:,RL),3);
firingRateAverage(:,1,2,:) = mean(alignState(:,:,RR),3);
firingRateAverage(:,2,1,:) = mean(alignState(:,:,GL),3);
firingRateAverage(:,2,2,:) = mean(alignState(:,:,GR),3);

% for ii = 1:size(firingRateAverage, 1)
%     temp = squeeze(firingRateAverage(ii,:,:,:));
%     
%     temp2 = [];
%     for jj = 1:2
%         for kk = 1:2
%             temp2 = [temp2 squeeze(temp(jj,kk,:))'];
%         end
%     end
%     processedFR(ii,:)= temp2;
% end

% remove condition independent signal
for ii = 1:size(firingRateAverage, 1)
    temp = squeeze(firingRateAverage(ii,:,:,:));
    
    %%%%%%%%%%%%%%%%% normalize the data
    normFactor = prctile(temp(:),99) + 2;
    temp = temp./sqrt(normFactor);
    %%%%%%%%%%%%%%%%%   
    
    average = mean(mean(temp));
    
    temp2 = [];
    for jj = 1:2
        for kk = 1:2
            temp2 = [temp2 squeeze(temp(jj,kk,:) - average)'];
            
        end
    end
    processedFR(ii,:)= temp2;
end

test = processedFR';
[coeff, score, latent] = pca(test);
m = 4;
t = size(firingRateAverage,4);
orthF = [];
for thi = 1:m
    orthF(:,:,thi) = (score((1:t) + (thi-1)*t,:))';
end

% specifiy the dimensions to plot
traj = orthF([1,2,3], :, :);
RLTraj = traj(:,:,1);
RRTraj = traj(:,:,2);
GLTraj = traj(:,:,3);
GRTraj = traj(:,:,4);


%% plot pca 
figure; 
plot3(RLTraj(1,:), RLTraj(2,:), RLTraj(3,:), 'r');
hold on
plot3(RRTraj(1,:), RRTraj(2,:), RRTraj(3,:), 'r--');
hold on
plot3(GLTraj(1,:), GLTraj(2,:), GLTraj(3,:), 'g');
plot3(GRTraj(1,:), GRTraj(2,:), GRTraj(3,:), 'g--');

plot3(RLTraj(1,before/10), RLTraj(2,before/10), RLTraj(3,before/10), 'k.', 'markersize', 50);

che = round(500/10);

plot3(RLTraj(1,che), RLTraj(2,che), RLTraj(3,che), 'm.', 'markersize', 30);
plot3(RRTraj(1,che), RRTraj(2,che), RRTraj(3,che), 'm.', 'markersize', 30);
plot3(GLTraj(1,che), GLTraj(2,che), GLTraj(3,che), 'm.', 'markersize', 30);
plot3(GRTraj(1,che), GRTraj(2,che), GRTraj(3,che), 'm.', 'markersize', 30);

%% plot psth 
time = (-before:10: after);
for id = 1:size(firingRateAverage,1)
   figure; hold on
   
   plot(time, squeeze(firingRateAverage(id,1,1,:)), 'r-')
   plot(time, squeeze(firingRateAverage(id,1,2,:)), 'r--')
   plot(time, squeeze(firingRateAverage(id,2,1,:)), 'g-')
   plot(time, squeeze(firingRateAverage(id,2,2,:)), 'g--')
   title(['unit: ' num2str(id-1)]) 
   pause();
end

%% 
time = (-before:10: after);
for id = 81:size(firingRateAverage,1)
   figure; hold on
   
   plot(time, squeeze(firingRateAverage(id,1,1,:)), 'r-')
   plot(time, squeeze(firingRateAverage(id,1,2,:)), 'r--')
   plot(time, squeeze(firingRateAverage(id,2,1,:)), 'g-')
   plot(time, squeeze(firingRateAverage(id,2,2,:)), 'g--')
   title(['unit: ' num2str(id-1)]) 
   pause();
end
