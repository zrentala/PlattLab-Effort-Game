%% Staggered effort task
% choose between effort with variable reward and no effort for $1
% treadlab @ emory university 

%% Environment & Set-up
% clean up
clear all 
addpath(genpath('/Applications/Psychtoolbox'))
fclose('all'); 
sca


% PTB basics
AddPsychJavaPath;
LoadPsychHID;
PsychJavaTrouble;

% function handles

HomeDir = 'C:\Users\zrent\Documents\PlattLab\Summer\Staggered_EBDM_Experiment\eefrt_staggeredv2'; % UPDATE this path
DataDir = 'DATA';
cd(HomeDir);


%Prompt subject number
subjectID = input('Please input the subject ID number: ','s');

%% Set up maxeffort
%maxeffort = input('Please input subject''s avg. max. effort: ');
practiceDir = 'C:\Users\zrent\Documents\PlattLab\Summer\Staggered_EBDM_Experiment\eefrt_scanner_practice\logfiles\DATA_practice'; %change dir
practiceFile = fullfile(practiceDir,num2str(subjectID),strcat(num2str(subjectID),'.csv'));
if exist(practiceFile) == 0 
        error(['Average max effort does not exist for this subject '...
            'Please enter a new subject/run combination or run the practice module'])
end  
maxeffortMat = readmatrix(practiceFile);
maxeffort = maxeffortMat(1,9);


%%
%%%%%%%%%%%%
% ZACH
%%%%%%%%%%%%
% Each condition will begin with a screen
% that tells the participant whether they're engaging in competitive or
% cooperative gameplay.
% Each screen should display for 30 seconds, but will take a "press any key
% to begin" type cue to move on to the task

% CONDITION 1 (case 1 and 3): COOPERATIVE
% “You have been paired with one other person in this room. You are on the 
% same team. You will not learn this person’s identity, but you will both 
% see one anothers’ choices, actions, and results. The choices you both 
% make will result in real money being added to a shared bank. At the end 
% of the game, that amount will be split evenly among you.”
%
% "Press the 't' key to move forward."

% CONDITION 2 (case 2 and 4): COMPETITIVE
% “You have been paired with one other person in this room. 
%Your goal is to beat them. You will not learn this person’s identity, 
% but you will both see one another’s choices, actions, and results. The 
% choices you make will result in real money being added to your bank. 
% At the end of the game, that amount will given to the winner. The loser wins nothing.”

% "Press the 't' key to move forward."

%% Set up handedness

%Prompt experimenter for trial run
Screen('Preference', 'SkipSyncTests', 1);  %CHANGE
runFileSelect = input('Please input trial number (1-4): ');
switch(runFileSelect)
    case 1
        filename = [HomeDir '/runOrdersV2/Cases1_4_Cooperative_params.csv']; 
        sideOrderQ = 1;
        run = 1;
    case 2
        filename = [HomeDir '/runOrdersV2/Cases2_3_Competitive_params.csv'];
        sideOrderQ = 1;
        run = 2;
    case 3
        filename = [HomeDir '/runOrdersV2/Cases2_3_Competitive_params.csv'];
        sideOrderQ = 2;
         run = 3;
    case 4
        filename = [HomeDir '/runOrdersV2/Cases1_4_Cooperative_params.csv'];
        sideOrderQ = 2;
        run = 4;
end


effortDelay = 0;
%Prompt experimenter for subject's handedness
handednessinput = input('Please enter subject''s handedness (r/l): ','s');
switch(handednessinput)
    case 'r'
        handedness = 1;
    case 'R'
        handedness = 1;
    case 'l'
        handedness = 2;
    case 'L'
        handedness = 2;
end

%% Import data from text file.
delimiter = ',';
formatSpec = '%s%s%s%s%s%s%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
fclose(fileID);


raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,3,4,5]
    rawData = dataArray{col};
    for row=1:size(rawData, 1)
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;
            
            invalidThousandsSeparator = false;
            if any(numbers==',')
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(thousandsRegExp, ',', 'once'))
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            if ~invalidThousandsSeparator
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end

% Split data into numeric and cell columns.
rawNumericColumns = raw(:, [1,3,4,5]);
rawCellColumns = raw(:, [2]);

%% Allocate imported array to column variable names
cueCard = [rawCellColumns(:, 1)];
orderVec = cell2mat(rawNumericColumns(:, 1));
rewardVecBin = cell2mat(rawNumericColumns(:, 2));
rewardVec = cell2mat(rawNumericColumns(:, 3));
effortVec = cell2mat(rawNumericColumns(:, 4));

%Clear temporary variables
clearvars filename delimiter formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me rawNumericColumns rawCellColumns;


%% Set Output File
mkdir(fullfile(HomeDir,DataDir,subjectID));

if effortDelay == 2
    fileName = fullfile(HomeDir,DataDir,subjectID,['EEfRT_' subjectID '_run' num2str(run) '.csv']);
    if exist(fileName) > 0
        error(['A data file for this subject/run already exists. '...
            'Please enter a new subject/run combination or delete the existing file to proceed.'])
    end  
    dataFile = fopen(fileName, 'a');
    % print column labels
        fprintf(dataFile1,[...
        'subject,'... % subject number
        'effortDelay,'...   % 1 = Effort in 30 days  |  0 = Effort after scan
        'run,'...           % run number
        'runStart,'...      % run Start
        'trial,'...         % trial number
        'Cue1_Onset,'...    % onset of first info
        'Cue2_Onset,'...    % onset of second info
        'CueAll_Onset,'...  % onset of both reward and effort info
        'CueAll_Offset,'... % offset of both reward and effort info (also the onset of "CHOOSE ONE"
        'response,'...      % choice (High effort vs/ No Effort)
        'Reward,'...        % reward
        'Effort,'...        % Effort
        'Order,'...         % 1 = Reward info first  |  2 = Effort info first
        'RT,'...            % reaction time
        'Trigger,' ...
        'ITI_Onset,' ...
        'ITI_Offset,' ...
        'CounterBalance_Order', ...
        '\n']);
else
    fileName = fullfile(HomeDir,DataDir,subjectID,['EEfRT_' subjectID '_run' num2str(run) '.csv']);
    if exist(fileName) > 0
        error(['A data file for this subject/run already exists. '...
            'Please enter a new subject/run combination or delete the existing file to proceed.'])
    end  
    dataFile = fopen(fileName, 'a');
    % print column labels
        fprintf(dataFile,[...
        'subject,'... % subject number
        'effortDelay,'...   % 1 = Effort in 30 days  |  0 = Effort after scan
        'run,'...           % run number
        'runStart,'...      % run Start
        'trial,'...         % trial number
        'Cue1_Onset,'...    % onset of first info
        'Cue2_Onset,'...    % onset of second info
        'CueAll_Onset,'...  % onset of both reward and effort info
        'CueAll_Offset,'... % offset of both reward and effort info (also the onset of "CHOOSE ONE"
        'response,'...      % choice (High effort vs/ No Effort)
        'Reward,'...        % reward
        'Effort,'...        % Effort
        'Order,'...         % 1 = Reward info first  |  2 = Effort info first
        'RT,'...            % reaction time
        'Completed,'... 
        'Trigger,' ...
        'ITI_Onset,' ...    % intervals
        'ITI_Offset,' ...
        'CounterBalance_Order,', ...
        'Epoch1_Press,', ...
        'Epoch1_PressRT,', ...
        'Epoch2_Press,', ...
        'Epoch2_PressRT,', ...
        'Handedness' ...    % Right = 1, Left = 2
        'Condition'...      % Cooperative = 0, Competitive = 1
        'TotalPresses'...
        'TrialTIme'...
        'MoneyTrial'...
        'MoneyCumu'...
        'OtherMoneyTrial'...
        'OtherMoneyCumu'...
        '\n']);
end

%% Prep PTB Screen and Inputs
%Screen('Preferences', 'SkipSyncTests', 1);
subj = str2num(subjectID);
clc
HideCursor;

[win, ScrRect] = Screen('OpenWindow', max(Screen('Screens')));
xCenter=ScrRect(3)/2;
yCenter=ScrRect(4)/2;
leftRect=[xCenter-400,yCenter-400,xCenter,yCenter+315]; %for projector
rightRect=[xCenter+200,yCenter-400,xCenter+600,yCenter+315]; %for projector
centerspot = 800;
fMRI = 1; %%%%%%CHANGE IF NEEEDED######################################################################
if max(Screen('Screens')) > 1
    fMRI = 1;
end

completionStatus = 0;
trialTime = 0;

%Set Fonts
Black = [0 0 0];
White = [255 255 255];
Red = [255 0 0];
Yellow = [255 255 0];
Green = [0 255 0];
FontName = 'Arial';
FontLg = 72;
FontSm = 18;
Xres = ScrRect(3);
Yres = ScrRect(4);
Dres = sqrt(Xres^2+Yres^2)/1500;
Screen('FillRect',win,Black);
Screen('TextFont',win,FontName);
Screen('TextSize',win,FontLg);
 
checkidx = 1;

%mean = 1.7 (from previous eefrt scanner version)... change?
% ITIdis = [0	0 1	1 4	1 1	1 0	2 1	3 1	1 0	1 3	1 3	0 2	2 1	2 1	2 3	2 1	0 1	2 0	4 2	1 3	5 3	2 1	0 1	2 2	1 5	4];
%mean = 3.6, poissrnd(3.5,[1,48])
ITIdis = [1,2,2,3,2,4,1,2,1,1.5,4,4,4,3,4,2,4,1.5,2,4,3,2,1.5,3,1.5,1,2,3,3,0,2,2,4,3,1.5,4,4,3,1.5,4,4,4,1.5,2,4,1,4,1.5];
ITI = Shuffle(ITIdis);

%mean = 4.02, max 8, min 2 ... poissrnd(4,[1,48]), swapped 1's for 2's
% PresentCue1ITIdis = [4,8,3,3,2,2,2,6,3,3,5,4,4,2,2,3,5,2,2,7,4,8,3,3,4,5,6,7,2,3,3,3,4,2,8,5,3,3,4,7,3,6,2,5,3,5,6,4];
% mean = 3.23, max 8, min 2 ... poissrnd(3,[1,48]), swapped 1's for 2's
PresentCue1ITIdis = [2,4,2,4,3,1.5,3,2,2,3,2,2,2,2,2,3,1.5,2,2,5,4,3,2,4,2,1.5,5,3,3,4,1.5,4,3,4,3,1.5,3,3,2,2,2,2,1.5,1.5,2,1.5,2,3];
PresentCue1ITI = Shuffle(PresentCue1ITIdis);  

%mean = 4.21, max 8, min 2 ... poissrnd(4,[1,48]), swapped 1's for 2's
% PresentCue2ITIdis = [5,7,4,8,5,5,2,7,2,6,2,2,2,3,2,7,8,6,3,4,3,6,2,4,7,5,2,7,2,4,4,4,6,2,7,2,3,4,4,3,3,5,5,2,4,2,5,5];
%mean = 2.9792, max 6, min 2 ... poissrnd(4,[1,48]), swapped 1's for 2's
PresentCue2ITIdis = [3,2,2,2,2,1.5,1.5,2,5,2,3,1.5,1.5,2,3,4,3,2,2,3,3,2,2,2,3,2,5,2,3,1.5,1.5,3,2,1.5,3,2,2,3,2,2,3,3,3,1.5,3,1.5,2,2];
PresentCue2ITI = Shuffle(PresentCue2ITIdis); 

%mean = 3.98, max8, min 2 ... poissrnd(4,[1,48]), swapped 1's for 2's
% PresentDecisionITIdis = [2,4,6,6,4,2,2,5,5,3,2,6,3,6,5,2,3,2,3,4,3,3,7,6,6,3,6,5,4,2,3,5,3,6,7,5,4,7,3,2,2,3,3,2,4,2,2,8];
%mean = 3.23, max8, min 2 ... poissrnd(4,[1,48]), swapped 1's for 2's
PresentDecisionITIdis = [1.5,4,1.5,3,4,2,2,1.5,2,2,2,3,2,1.5,1.5,2,2,4,1.5,2,2,1.5,2,2,2,1.5,1.5,2,2,4,1.5,2,3,2,1.5,4,1.5,2,2,2,2,2,1.5,1.5,3,3,2,1.5];
PresentDecisionITI = Shuffle(PresentDecisionITIdis); 

%Counterbalanced presentation side orders.
if sideOrderQ == 1
    sideOrder = [0,1,1,1,0,0,0,1,0,1,1,1,0,0,0,1,0,1,1,1,0,1,0,1,0,1,1,0,0,0,1,1,1,0,1,1,0,1,0,0,0,1,0,0,0,0,1,1];
elseif sideOrderQ == 2
    sideOrder = [1,1,0,0,0,0,1,0,0,0,1,0,1,1,0,1,1,1,0,0,0,1,1,0,1,0,1,0,1,1,1,0,1,0,0,0,1,1,1,0,1,0,0,0,1,1,1,0];
end

epoch1press = zeros(1,length(sideOrder));
epoch1pressRT = zeros(1,length(sideOrder));
epoch2press = zeros(1,length(sideOrder));
epoch2pressRT = zeros(1,length(sideOrder));

% button setup for scanner or behavioral - will need to update based on
% what trigger you scanner sends and what keys you have participants press
% on your scanner-compatible button box
KbName('UnifyKeyNames') %NEED FOR EMORY SYSTEM!!!
    TRIG  = KbName('t'); 
    LEFT  = KbName('y'); %TOP (blue) button on button box - hit with thumb HARD
    RIGHT = KbName('n'); %Next (yellow) button on button box EASY
    DONE  = KbName('q'); %Bottom (red) button on button box
    % button setup for scanner or behavioral
    if handedness == 1
        HARD = KbName('s'); %S
        EASY = KbName('g'); %L
    elseif handedness == 2
        HARD = KbName('k'); %S
        EASY = KbName('g'); %L
    end
    
device = max(GetKeyboardIndices);

%Obtain keyboard name85
[id,name] = GetKeyboardIndices; % get a list of all devices connected

%Create keylist containing trigger
keys=[TRIG LEFT RIGHT DONE];
keylist=zeros(1,256); %%create a list of 256 zeros

keylist(keys)=1; %%set keys you're interested in to 1
KbQueueCreate(device, keylist);  %23 = trig KEYCODE
KbQueueStart(device);

%% Wait for Initial Pulse        
% waits for trigger in scanner version
% if SUBID is odd get 1 and 3, if even get 2 and 4
switch(run)
    case 1 % cooperative
       Condition = 0;
        line1 = 'You have been paired with one other person in this room. You are on the ';
        line2 = 'same team. You will not learn this person’s identity, but you will both ';
        line3 = 'see one anothers’ choices, actions, and results. The choices you both ';
        line4 = 'make will result in real money being added to a shared bank. At the end';
        line5 = 'of the game, that amount will be split evenly among you.';
        line6 = '\n Press T to start, Press Q to quit if needed';
        DrawFormattedText(win, [line1 newline line2 newline line3 newline line4 newline line5 newline line6],'center','center',White);
    case 2 % competitive 
        Condition = 1;
        line1 = 'You have been paired with one other person in this room.';
        line2 = 'Your goal is to beat them. You will not learn this persons identity,';
        line3 = 'but you will both see one anothers choices, actions, and results. The';
        line4 = 'choices you make will result in real money being added to your bank';
        line5 = 'At the end of the game, that amount will given to the winner. The loser wins nothing.';
        line6 = '\n Press T to start, Press Q to quit if needed';
        DrawFormattedText(win,[line1 newline line2 newline line3 newline line4 newline line5 newline line6],'center','center',White);
    case 3 % competitive
        Condition = 1;
        line1 = 'You have been paired with one other person in this room.';
        line2 = 'Your goal is to beat them. You will not learn this persons identity,';
        line3 = 'but you will both see one anothers choices, actions, and results. The';
        line4 = 'choices you make will result in real money being added to your bank';
        line5 = 'At the end of the game, that amount will given to the winner. The loser wins nothing.';
        line6 = '\n Press T to start, Press Q to quit if needed';
        DrawFormattedText(win, [line1 newline line2 newline line3 newline line4 newline line5 newline line6],'center','center',White);
    case 4 % cooperative
        Condition = 0;
        line1 = 'You have been paired with one other person in this room. You are on the ';
        line2 = 'same team. You will not learn this person’s identity, but you will both ';
        line3 = 'see one anothers’ choices, actions, and results. The choices you both ';
        line4 = 'make will result in real money being added to a shared bank. At the end';
        line5 = 'of the game, that amount will be split evenly among you.';
        line6 = '\n Press T to start, Press Q to quit if needed';
        DrawFormattedText(win,[line1 newline line2 newline line3 newline line4 newline line5 newline line6],'center','center',White);
end
FontLg = 90;%  reset font sizes
FontSm = 30;
Screen('Flip',win);
if fMRI == 1
    pressed=0;
    while (1)
        [pressed, firstpress, x2, keyCode, x3] = KbQueueCheck(device); %check response
        if pressed && keyCode(DONE) 
                    sca;
         elseif pressed && keyCode(TRIG)
            runStart = GetSecs;
            break;
        end
    end
else
    runStart = GetSecs;
end
Screen('TextSize',win, FontLg);
totalPresses = 0;
otherMoneyCumu = 0;
otherMoneyTrial = 0;
moneyTrial = 0;
moneyCumu = 0;
%% Begin Trial Loop
for i = 1:length(rewardVec) %BEGIN TRIALS
% for i = 1:1
    fileName = fullfile(HomeDir,DataDir,subjectID,['EEfRT_' subjectID '_run' num2str(run) '.csv']);
    reward = rewardVec(i) + rewardVecBin(i);
    effort = effortVec(i);
    moneyTrial = 0;
    
        %% Present 1st Cue
        if orderVec(i) == 2  %effort first
            CueScreen1 = imread(['STIM/' cueCard{i,1}], 'png');
            Cue1Texture = Screen('MakeTexture',win,CueScreen1);
            if sideOrder(i) == 1
                Screen('DrawTexture',win,Cue1Texture, [],leftRect);
            elseif sideOrder(i) == 0
                Screen('DrawTexture',win,Cue1Texture, [],rightRect);
            end
        elseif orderVec(i) == 1  %reward first
            if sideOrder(i) == 1
                DrawFormattedText(win,['$' num2str(reward)],1250,'center',White); % change font size!!!
            elseif sideOrder(i) == 0
                DrawFormattedText(win,['$' num2str(reward)],600,'center',White);
            end
        end

        KbQueueFlush(device);
        if (effortDelay == 1 && orderVec(i) == 2) || (effortDelay == 2 && i == 1)
            DrawFormattedText(win,'EFFORT IN 30 DAYS',centerspot-200,900,White);
        end
        
        Screen(win, 'Flip');
        cue1Onset = GetSecs-runStart;
        
        %Epoch 1
        %Check for early button pressing and record the RT, only records
        %first press.
        KbQueueFlush(device);
        response = 0;
        rt = 0;
        pressed=0;
        keepchecking = 1;
        starttime = GetSecs;
        while keepchecking
            [pressed, firstpress, firstrelease, lastPress, lastRelease] = KbQueueCheck(device); %check response
            checktime = GetSecs;
            %no press and time is up
           if  lastPress(DONE)
               sca;
           elseif ((checktime - starttime) >= PresentCue1ITI(i)) 
                keepchecking = 0;
                epoch1press(i) = 999;
                break;
            %press and still waittime left
            elseif ((checktime - starttime) < PresentCue1ITI(i)) && (lastPress(LEFT) || lastPress(RIGHT))  %finish the wait
                if  lastPress(DONE)
               sca;
                elseif lastPress(LEFT) %chose hard
                    epoch1press(i) = 1;
                elseif lastPress(RIGHT) %chose easy
                    epoch1press(i) = 0;
                end
                epoch1pressRT(i) = GetSecs - starttime;
                WaitSecs(PresentCue1ITI(i) - (checktime-starttime));
                keepchecking = 0;
                break;
            elseif pressed == 0
            end
        end
        clear pressed firstpress firstrelease lastPress lastRelease starttime
        
        %% Present 2nd Cue and 1st Cue
        CueScreen1 = imread(['STIM/' cueCard{i,1}], 'png');
        Cue1Texture = Screen('MakeTexture',win,CueScreen1);
        if sideOrder(i) == 1
            Screen('DrawTexture',win,Cue1Texture, [],leftRect);
            DrawFormattedText(win,['$' num2str(reward)],1250,'center',White);
        elseif sideOrder(i) == 0
            Screen('DrawTexture',win,Cue1Texture, [],rightRect);
            DrawFormattedText(win,['$' num2str(reward)],600,'center',White);
        end
            
        KbQueueFlush(device);
        if (effortDelay == 1) || (effortDelay == 2 && i == 1)
            DrawFormattedText(win,'EFFORT IN 30 DAYS',centerspot-200,900,White);
        end
        
        Screen(win, 'Flip');
        cue2Onset = GetSecs-runStart;
       %Epoch 2
        %Check for early button pressing and record the RT, only records
        %first press.
        KbQueueFlush(device);
        response = 0;
        rt = 0;
        pressed=0;
        keepchecking = 1;
        starttime = GetSecs;
        while keepchecking
            [pressed, firstpress, firstrelease, lastPress, lastRelease] = KbQueueCheck(device); %check response
            checktime = GetSecs;
           
            %no press and time is up
            if  lastPress(DONE)
               sca;
            elseif ((checktime - starttime) >= PresentCue2ITI(i)) 
                keepchecking = 0;
                epoch2press(i) = 999;
                break;
            %press and still waittime left
            elseif ((checktime - starttime) < PresentCue2ITI(i)) && (lastPress(LEFT) || lastPress(RIGHT))  %finish the wait
                if lastPress(DONE) 
                    sca;
                elseif lastPress(LEFT) %chose hard
                    epoch2press(i) = 1;
                elseif lastPress(RIGHT) %chose easy
                    epoch2press(i) = 0;
                end
                epoch2pressRT(i) = GetSecs - starttime;
                WaitSecs(PresentCue2ITI(i) - (checktime-starttime));
                keepchecking = 0;
                break;
            elseif pressed == 0
            end
        end
        clear pressed firstpress firstrelease lastPress lastRelease starttime
        
        %% Present CHOOSE Screen
        KbQueueFlush(device);
        decisionOnset = GetSecs-runStart;
        response = 0;
        rt = 0;
        pressed=0;
        decisionDispRespTime = GetSecs;
        %Display Decision text
        if sideOrder(i) == 1
            Screen('DrawTexture',win,Cue1Texture, [],leftRect);
            DrawFormattedText(win,['$' num2str(reward)],1250,'center',White);
        elseif sideOrder(i) == 0
            Screen('DrawTexture',win,Cue1Texture, [],rightRect);
            DrawFormattedText(win,['$' num2str(reward)],600,'center',White);
        end
        DrawFormattedText(win,'CHOOSE',centerspot+100,100,White);
        DrawFormattedText(win,'ACCEPT: Y, REJECT: N','center',Yres-100,White);
        if effortDelay == 1
            DrawFormattedText(win,'EFFORT IN 30 DAYS',centerspot-200,900,White);
        end
        Screen(win, 'Flip');
        
        respTime = GetSecs;
        KbQueueFlush(device);
        %Check for Press
        while 1
            [pressed, firstpress, firstrelease, lastPress, lastRelease] = KbQueueCheck(device); %check response
            if pressed==1 && lastPress(DONE)
                sca;
            elseif pressed==1 && lastPress(LEFT)
                response = 1; %HARD OPTION
                rt = GetSecs-respTime;
                CueAllOffset = GetSecs - runStart;
                disprt = GetSecs-decisionDispRespTime;
                
                if sideOrder(i) == 1
                    Screen('DrawTexture',win,Cue1Texture, [],leftRect);
                    DrawFormattedText(win,['$' num2str(reward)],1250,'center',White);
                elseif sideOrder(i) == 0
                    Screen('DrawTexture',win,Cue1Texture, [],rightRect);
                    DrawFormattedText(win,['$' num2str(reward)],600,'center',White);
                end
                
                DrawFormattedText(win,'CHOOSE',centerspot+100,100,White);
                DrawFormattedText(win,'Accepted',centerspot+59,'center',Green);
%                 Screen('FrameOval', win, Green, [300; 150; 750; 750],6,6);  %[left,top,right,bottom]
                Screen(win, 'Flip');
%% Button Pressing task
            HardEffort = (effortVec * maxeffort); % Percentage of key presses order

            %Get Ready!
            DrawFormattedText(win,'Get ready to press!','center',100,White);
            Screen(win, 'Flip');  
            WaitSecs(1.5);
            pressrunStart = GetSecs;

            % Set up progress bar
            progressBarMatrix = ones(500,100);
            progressBarMatrix = progressBarMatrix*256;
            progressBarMatrix(1:2,:) = 0;
            progressBarMatrix(499:500,:) = 0;
            progressBarMatrix(:,1:2) = 0;
            progressBarMatrix(:,99:100) = 0;

            reactionTime = 0;
            goalReachedCount2 = 0;
            acceptingInput = 1; 
            currentTime = GetSecs;
            startTime = GetSecs;
            secs0=GetSecs;
            totalPresses = 0;

            currentEffort = effortVec(i) * maxeffort;
            timeDelta = 21;

            displayRows = round(499/(maxeffort)); %This is the number of pixel rows to "fill" dependent on the difficulty of the task.

            while (currentTime < startTime+timeDelta) && (goalReachedCount2 < ((currentEffort))) %While the time has not yet expired
                [pressed, secs, kbData] = KbCheck;
                if (pressed == 1) && (kbData(DONE) == 1) && (acceptingInput==1)
                    sca;
                elseif (pressed == 1) && (kbData(HARD) == 1) && (acceptingInput==1)
                    totalPresses = totalPresses + 1;
                    if round(499-goalReachedCount2*displayRows) < 0
                        goalReachedCount2 = currentEffort;
                    else
                        progressBarMatrix(round(499-goalReachedCount2*displayRows),:) = 0; % "Fills" the progress bar based on the task difficulty
                    end
                    goalReachedCount2 = goalReachedCount2 + 1; % Increment the number of key presses logged.
                    pause(0.1);
                    acceptingInput=0;
                end

                currentTime = GetSecs;
                Screen('TextSize',win, 30);
                Screen('DrawText', win, strcat('Time:', 32, 32,num2str((startTime+timeDelta)-currentTime)), 800,200, [255,255,255]); %Show remaining time
                if handedness == 1
                    Screen('DrawText', win, strcat('Push:', 32, 32 , KbName(HARD),' until bar is', 32, num2str((effortVec(i)*100)),'% full with your left pinky.'),600, 700, [255,255,255]); %Show reminder.
                elseif handedness == 2
                    Screen('DrawText', win, strcat('Push:', 32, 32 , KbName(HARD),' until bar is', 32, num2str((effortVec(i)*100)),'% full with your right pinky.'),600, 700, [255,255,255]); %Show reminder.
                end
                Screen(win,'PutImage',progressBarMatrix); % Display to window pointer
                Screen(win, 'Flip'); % Write framebuffer to display

                if pressed~=1
                    acceptingInput=1;
                end
            end    

            completionTime = currentTime - startTime;

            %Check for completion status 
            if goalReachedCount2 >= ((currentEffort))
                completionStatus = 1;
            else
                completionStatus = 0;
            end
            if completionStatus == 1
                    Screen('TextSize',win, FontLg);
                    Screen(win,'FillRect',0);
                    Screen(win, 'Flip');
%PArticipant Win Screen
                    if (response == 1) %hard
                        lotto = rand;
                        DrawFormattedText(win, ['You reached the assigned number of key presses!' newline 'You will now be entered into a lottery!'],'center',500, 255);
                        Screen(win, 'Flip');
                        WaitSecs(1)
                        if lotto >= 0.5
                            DrawFormattedText(win, ['You won $' num2str(reward) ' from the lottery!'], 'center', 'center');
                            moneyTrial = reward;
                        elseif lotto < 0.5
                            DrawFormattedText(win, ['You did not win the lottery!'], 'center', 'center');
                            end
                        Screen(win, 'Flip');
                         WaitSecs(3)
                    end
                    Screen(win, 'Flip');
            else
                    Screen('TextSize',win, 30);
                    Screen(win,'FillRect',0);
                    Screen(win, 'Flip');
                    DrawFormattedText(win, 'You did not reach the assigned number of key presses!','center',500, 255);
                    Screen(win, 'Flip');
            end 
            Screen('TextSize',win, FontLg);
            goalReachedCount = 0;
                break;
            elseif pressed==1 && lastPress(RIGHT)
                response = 0; %EASY OPTION
                rt = GetSecs-respTime;
                CueAllOffset = GetSecs - runStart;
                disprt = GetSecs-decisionDispRespTime;
                completionStatus = 0;
                totalPresses = 0;
                
                if sideOrder(i) == 1
                    Screen('DrawTexture',win,Cue1Texture, [],leftRect);
                    DrawFormattedText(win,['$' num2str(reward)],1250,'center',White);
                elseif sideOrder(i) == 0
                    Screen('DrawTexture',win,Cue1Texture, [],rightRect);
                    DrawFormattedText(win,['$' num2str(reward)],600,'center',White);
                end
                % Enters lottery
                reactionTime = 0;
                goalReachedCount2 = 0;
                currentTime = GetSecs;
                 startTime = GetSecs;
                 secs0=GetSecs;
                totalPresses = 0;

                currentEffort = effortVec(i) * maxeffort;
                timeDelta = 21;
    
                displayRows = round(499/(maxeffort)); %This is the number of pixel rows to "fill" dependent on the difficulty of the task.
    
               % while (currentTime < startTime+timeDelta) && (goalReachedCount2 < ((currentEffort))) %While the time has not yet expired
               %     [pressed, secs, kbData] = KbCheck;
               %     currentTime = GetSecs;
               %     Screen('TextSize',win, 90);
               %     Screen('DrawText', win, strcat('Time:', 32, 32,num2str((startTime+timeDelta)-currentTime)),800, 200, [255 255 255]); %Show remaining time
               %     Screen(win, 'Flip'); % Write framebuffer to display
    
              %  end    
                
                DrawFormattedText(win,'CHOOSE',centerspot+100,100,White); %Choose to win, Add screen for other player
                DrawFormattedText(win,'Rejected',centerspot+50,'center',Red); %change location
%                 Screen('FrameOval', win, Green, [725; 150; 1175; 750],8,8);  %[left,top,right,bottom]
                Screen(win, 'Flip');
                lotto = rand;
                DrawFormattedText(win, ['You will now be entered into a lottery!'],'center', 'center', White);
                Screen(win, 'Flip');
                WaitSecs(1)
                if lotto >= 0.5
                    DrawFormattedText(win, ['You won $1 from the lottery!'], 'center', 'center',White);
                    moneyTrial = 1;
                elseif lotto < 0.5
                    DrawFormattedText(win, ['You did not win the lottery!'], 'center', 'center',White);
                end
                Screen(win, 'Flip');
                WaitSecs(3)
                break;
            elseif pressed==0  
                if GetSecs-respTime > 5  %TIME OUT AT 5 SECONDS
                    response = 2; %TIMEOUT
                    rt = 0;
                    disprt = GetSecs-decisionDispRespTime;
                    completionStatus = 0;
                    
                    Screen(win, 'Flip');
                    CueAllOffset = GetSecs - runStart;
                    DrawFormattedText(win,'Please choose more quickly!','center','center',Red);
                    Screen(win, 'Flip');
                    WaitSecs(0.5);
                    break;
                end
            end    
        end
        WaitSecs(0.7);
        moneyCumu = moneyTrial + moneyCumu;
        
        %% Opponent/Teamate screen
         chooseChance = rand;
         compChance = rand;
         winChance = rand;
         payout = '0';
            if Condition == 0
                other = 'TEAMMATE';
            elseif Condition == 1
                other = 'OPPONENT';
            end
            % Chooses text
            if chooseChance >= 0.5 
                linea = [other ' CHOICE: EFFORT'];
                %win chance
                % complete text
                if compChance >= 0.5
                    
                    if winChance >= 0.5
                        payout = num2str(reward);
                        lineb = [other ' LOTTERY RESULT: WIN $' payout];
                    elseif winChance <0.5 
                        lineb = [other ' LOTTERY RESULT: LOST'];
                    end
                elseif compChance < 0.5
                    lineb = [other ' RESULT: FAILURE'];
                end 
            elseif chooseChance < 0.5 
                linea = [other ' CHOICE: NO EFFORT'];
                if winChance >=0.5
                        payout = '1';
                        lineb = [other ' LOTTERY RESULT: WIN $' payout];
                elseif winChance <0.5
                    lineb = [other ' LOTTERY RESULT: LOST'];
                end
                
            end
            DrawFormattedText(win,[linea newline lineb],'center','center',White); %['$' num2str(reward)]
         Screen(win, 'Flip'); 
         otherMoneyTrial = str2double(payout);
         otherMoneyCumu = otherMoneyTrial + otherMoneyCumu;
        WaitSecs(4);
        chooseChance = rand;
         compChance = rand;
         winChance = rand;
        %% ITI / Fixation
        DrawFormattedText(win,'+',centerspot+250,'center',White);
        Screen('Flip',win);
        Trigger=1;

        ITIOnset = GetSecs-runStart;
        WaitSecs(ITI(i));  
        ITIOffset = GetSecs-runStart;
       trialTime = cue1Onset + ITIOffset;
         if effortDelay == 2
         else
            % writes trial data to file
            fprintf(dataFile,'%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n',...
                subj,effortDelay,run,runStart,i,cue1Onset,cue2Onset, ... 
                decisionOnset,CueAllOffset,response,reward,effort,orderVec(i), ... 
                rt,completionStatus,Trigger,ITIOnset,ITIOffset,sideOrderQ, ... 
                epoch1press(i),epoch1pressRT(i),epoch2press(i),epoch2pressRT(i),handedness,Condition,totalPresses,trialTime,moneyTrial,moneyCumu,otherMoneyTrial,otherMoneyCumu);
         end
         
         %practice check
         if effortDelay == 2 && i ==2
             break;
         end
        
 %% 
    
    clear fileName
    fileName = fullfile(HomeDir,DataDir,subjectID,['EEfRT_' subjectID '_run' num2str(run) '.csv']);
    dataFile = fopen(fileName, 'a');
    FontLg = 90;
    FontSm = 30;
    Xres = ScrRect(3);
    Yres = ScrRect(4);
    Dres = sqrt(Xres^2+Yres^2)/1500;
    Screen('FillRect',win,Black);
    Screen('TextFont',win,FontName);
    Screen('TextSize',win,FontLg);
end

if effortDelay == 2
else
fclose(dataFile);
end

%% Win Screen
DrawFormattedText(win,'You have finished the game.','center','center',White);
Screen(win, 'Flip');
WaitSecs(2);

DrawFormattedText(win,['You have won $' num2str(moneyCumu)],'center','center',White);
Screen(win, 'Flip');
WaitSecs(2);
if Condition == 1
    bank = moneyCumu+otherMoneyCumu;
    DrawFormattedText(win,['Your teammate $' num2str(otherMoneyCumu) newline 'Your bank has $' bank ' in it.'],'center','center',White);
    Screen(win, 'Flip');
    WaitSecs(3);
    DrawFormattedText(win,['You will be rewarded ...'],'center','center',White); %need to figure out end 
    Screen(win, 'Flip');
else
    DrawFormattedText(win,['Your opponent won$' num2str(otherMoneyCumu)],'center','center',White);
    Screen(win, 'Flip');
    WaitSecs(3);
    if moneyCumu > otherMoneyCumu
        DrawFormattedText(win,['You won!' newline 'You will be rewarded ...'],'center','center',White); %need to figure out end 
        Screen(win, 'Flip');
        WaitSecs(3);
    else 
         DrawFormattedText(win,['You lost!' newline 'Your opponent will be rewarded with ...'],'center','center',White); %need to figure out end 
         Screen(win, 'Flip');
         WaitSecs(3);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Ratings
ratingQs = {'How unpleasant do you think the effortful task will be?', ...
            'How difficult do you think the effortful task will be?', ...
            'How much do you think the effort level influenced your decision?', ...
            'How much do you think the reward amount influenced your decision?', ...
            'How much are you looking forward to the money?'};
scale1Vec = {'Very Unpleasant', ...
             'Very Difficult', ...
             'Not At All', ...
             'Not At All', ...
             'Not At All',};
scale2Vec = {'Very Pleasant', ...
             'Not Difficult', ...
             'A Lot', ...
             'A Lot', ...
             'A Lot'};

for stimEval = 1:5 
    
    Screen('TextSize',win,FontSm);
    slack = Screen('GetFlipInterval', win); %/2
    vbl = Screen('Flip', win);

    commandwindow;
    baseRect = [0 0 10 30];
    LineX = xCenter-xshift; %960+-250
    LineY = yCenter;
    rectColor = [255 255 255];
    pixelsPerPress = 20;
    waitframes = 1;
    
    %Check for button press
    while KbCheck; end
    
    while true
    % [pressed, firstpress, firstrelease, lastPress, lastRelease] = KbQueueCheck(device); %check response
    [ keyIsDown, secs, keyCode ] = KbQueueCheck(device);
%     [ keyIsDown, secs, keyCode ] = KbCheck(device);
    pressedKeys = find(keyCode);
    if keyCode(LEFT)
        LineX = LineX - pixelsPerPress;
    elseif keyCode(RIGHT)
        LineX = LineX + pixelsPerPress;
    elseif pressedKeys == DONE
        StopPixel_M = (((LineX - xCenter-xshift) + 250)/5);
        break;
    elseif keyCode(DONE)
        StopPixel_M = (((LineX - xCenter-xshift) + 250)/5);
        break;
    end
    if LineX < (xCenter-250-xshift)
        LineX = (xCenter-250-xshift);
    elseif LineX > (xCenter+250-xshift) 
        LineX = (xCenter+250-xshift);
    end
    if LineY < 0
        LineY = 0;
    elseif LineY > (yCenter+10)
        LineY = (yCenter+10);
    end
    text_P = ratingQs{stimEval};
    centeredRect = CenterRectOnPointd(baseRect, LineX, LineY);
    DrawFormattedText(win, text_P ,xCenter-250-xshift, (yCenter-100), [255, 255, 255],...
        [],[],[],5)
    Screen('DrawLine', win, [255, 255, 255], (xCenter+250-xshift ), (yCenter), ...
        (xCenter-250-xshift), (yCenter), 1);
    Screen('DrawLine', win, [255, 255, 255], (xCenter+250-xshift ), (yCenter+10),...
        (xCenter+250-xshift), (yCenter-10), 1);
    Screen('DrawLine', win, [255, 255, 255], (xCenter-250-xshift ), (yCenter+10),...
        (xCenter- 250-xshift), (yCenter-10), 1); 
    Screen('DrawText', win,scale1Vec{stimEval}, (xCenter-300-xshift), (yCenter+25),...
        [255, 255, 255]);
%     Screen('DrawText', win,'Neutral', (xCenter-10), (yCenter+25),...
%         [255, 255, 255]);
    Screen('DrawText', win,scale2Vec{stimEval}, (xCenter+200-xshift), (yCenter+25),...
        [255, 255, 255]);
    Screen('FillRect', win, rectColor, centeredRect);
    vbl = Screen('Flip', win, vbl + (waitframes - 0.5) * slack);
    end

    vasResp(stimEval) = StopPixel_M; 
                          
    ShowCursor
    ListenChar(0);
    
    if effortDelay == 2
    else
    fileName = fullfile(HomeDir,DataDir,subjectID,['EEfRT_ratings_' subjectID '_run' num2str(run) '.csv']);
    dataFile = fopen(fileName, 'a');
    % print column labels
%     fprintf(dataFile,['subject,'... % subject number
%     'run,'...           % run number
%     'question,'...      % question text ...
%     'scaleResp (1-100),'...      % response to the scale ...
%     '\n']);
     fprintf(dataFile,'%f,%f,%f,%s,%s,%s,%f, \n',...
        subj, ...               % Subject number
        effortDelay, ...        % 1 = Effort in 30 days  |  0 = Effort after scanner
        run, ...                % Run number
        ratingQs{stimEval}, ... % Question asked to subject for rating
        scale1Vec{stimEval}, ...% Wording on lower end of scale 
        scale2Vec{stimEval}, ...% Wording higher end of scale
        vasResp(stimEval));     % 1-100 rating scale
    end
end

%% All Done

%clear screen
Screen('Flip',win);
if effortDelay == 2
else
fclose(dataFile);
end

%Close PTB Window
sca;


