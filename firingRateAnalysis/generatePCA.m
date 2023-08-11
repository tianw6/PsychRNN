% Created by Tian Wang on Dec.29th 2022: plot pca trajectories


function trajs = generatePCA(alignState, checker, options)

% export source excel data
trajs = struct;

addpath('/net/derived/tianwang/LabCode');


handle = options.handle;
before = -options.span(1);
after = options.span(2);
% rt = options.rtBin;
type = options.type;
viewAngle = options.viewAngle;
orthDim = options.orthDim;

[a, b, c] = size(alignState);

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

coh = checker.coherence;








%% do pca

test = reshape(alignState, [a, b*c])';

[coeff, score, latent] = pca(test);
orthF = [];
for thi = 1 : c
    orthF(:,:,thi) = (score( (1:b) + (thi-1)*b, :))';
end

%% based on coherence: 2 input-RNN

if (strcmp(type, 'coh') == 1) 
    
    
    aveGain = [];
    cc = jet(11);
    %figure();
    handle;
    
    
    coh_bin = unique(checker.coherence_bin);
    for ii  = 1 : ceil(length(coh_bin)/2)-1
        selectedTrials = (checker.coherence_bin == coh_bin(ii) | checker.coherence_bin == -coh_bin(ii));

        leftSelect = selectedTrials & left;
        rightSelect = selectedTrials & right;
        leftTrajAve = mean(orthF(orthDim,:,leftSelect), 3);
        rightTrajAve = mean(orthF(orthDim,:,rightSelect), 3);

        % left and right average RT of each RT bin    
        leftAveRT = round(mean(RTR(leftSelect))./10) + before/10;
        rightAveRT = round(mean(RTR(rightSelect))./10) + before/10;


        % left & right select gains
    %     aveGain(1,ii) = mean(checker.g0(leftSelect));
    %     aveGain(2,ii) = mean(checker.g0(rightSelect));
        zeroV = before/10+1;
        
        % plot left trajs
        plot3(leftTrajAve(1,1:leftAveRT), leftTrajAve(2,1:leftAveRT),leftTrajAve(3,1:leftAveRT), 'color', cc(ii,:), 'linestyle', '--', 'linewidth', 2);
        hold on
        % mark the checkerboard onset
        plot3(leftTrajAve(1,zeroV), leftTrajAve(2,zeroV),leftTrajAve(3,zeroV), 'color', cc(ii,:), 'marker', 'd', 'markerfacecolor',cc(ii,:),'markersize', 10);
        % mark the RT (end time)
        plot3(leftTrajAve(1,leftAveRT), leftTrajAve(2,leftAveRT),leftTrajAve(3,leftAveRT), 'color', 'k', 'marker', '.', 'markersize', 25);

        % plot right trajs
        plot3(rightTrajAve(1,1:rightAveRT), rightTrajAve(2,1:rightAveRT),rightTrajAve(3,1:rightAveRT), 'color', cc(ii,:), 'linewidth', 2);
        hold on
        % mark the checkerboard onset
        plot3(rightTrajAve(1,zeroV), rightTrajAve(2,zeroV),rightTrajAve(3,zeroV), 'color', cc(ii,:), 'marker', 'd', 'markerfacecolor',cc(ii,:), 'markersize', 10);
        % mark the RT (end time)
        plot3(rightTrajAve(1,rightAveRT), rightTrajAve(2,rightAveRT),rightTrajAve(3,rightAveRT), 'color', 'k', 'marker', '.', 'markersize', 25);

        
       
    %     pause()
    end
    

end
%% based on RT





if (strcmp(type, 'RT') == 1)

    % the trials definitely have more trials with fastere RT, so the long RT
    % trajs are messy

    % total data: 500ms before checkerboard onset to 2000ms after checkerboard
    % onset. So max RT that can be plotted is 2000ms

    % rt = [100 250:50:700 1200];
    % rt = 100:100:800;
    % rt = [100:50:300 400 700];

    % rt = [100 250 400 600 800];
    % rt = [100:40:340 600];
    % rt = [100 175 250:50:500 1200];

    % cc = [
    %    0.6091    0.2826    0.7235
    % %     0.4279    0.3033    0.6875
    %     0.2588    0.3136    0.6353
    %     0.2510    0.4118    0.6980
    %     0.1765    0.6312    0.8588
    % %     0.1412    0.7450    0.8863
    %     0.3686    0.7490    0.5491
    % %     0.8941    0.7764    0.1530
    %     0.8980    0.6548    0.1686
    % %     0.8863    0.5295    0.1608
    %     0.8980    0.4155    0.1647
    % ]


    rt = [prctile(RTR,[0:12.5:100])];

    
    cc = [
       0.6091    0.2826    0.7235
        0.4279    0.3033    0.6875
%         0.2588    0.3136    0.6353
        0.2510    0.4118    0.6980
        0.1765    0.6312    0.8588
%         0.1412    0.7450    0.8863
        0.3686    0.7490    0.5491
        0.8941    0.7764    0.1530
%         0.8980    0.6548    0.1686
        0.8863    0.5295    0.1608
        0.8980    0.4155    0.1647
    ];


    % blue to red as RT increases
    % left: -; right: --
%     figure();
    handle;
    
    distV = [];
    nTrials = [];
    for ii  = 1:length(rt)-1
        selectedTrials = (rt(ii) < RTR & RTR < rt(ii + 1));

        leftSelect = selectedTrials & left;
        rightSelect = selectedTrials & right;
        leftTrajAve = mean(orthF(orthDim,:,leftSelect), 3);
        rightTrajAve = mean(orthF(orthDim,:,rightSelect), 3);

        nTrials(ii) = sum(leftSelect)

        % left and right average RT of each RT bin; plot until here or the
        % max bin size


        leftAveRT = min(round(min(RTR(leftSelect))./10) + before/10, b);
        rightAveRT = min(round(min(RTR(rightSelect))./10) + before/10, b);

        
        
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

    
        trajs(ii).leftTrajAve = leftTrajAve(1:3,1:leftAveRT)';
        trajs(ii).rightTrajAve = rightTrajAve(1:3,1:rightAveRT)';
        

    end
    
    set(gcf, 'Color', 'w');
    axis off; 
    axis square;
    axis tight;
    
    set(gca, 'LooseInset', [ 0 0 0 0 ]);
    xlabel('PC1');
    ylabel('PC2');
    zlabel('PC3');
    % title('PCA based on RT', 'fontsize', 30);
    axis vis3d;
    
    % vanilla: view: [-63 59]
    % multiplicative: view: [-93 -61]
    % additive: view: [110 -20]
    
    view(viewAngle)
    
    
    tv = ThreeVector(gca);
    tv.axisInset = [0.2 0.2]; % in cm [left bottom]
    tv.vectorLength = 2; % in cm
    tv.textVectorNormalizedPosition = 1.3; 
    tv.fontSize = 15; % font size used for axis labels
    tv.fontColor = 'k'; % font color used for axis labels
    tv.lineWidth = 3; % line width used for axis vectors
    tv.lineColor = 'k'; % line color used for axis vectors
    tv.update();
    rotate3d on;
    
    
    ax = gca;
    ax.SortMethod = 'childorder';
    % print('-painters','-depsc',['~/Desktop/', 'PCAdelayC','.eps'], '-r300');
    
%     axis equal

end


end

