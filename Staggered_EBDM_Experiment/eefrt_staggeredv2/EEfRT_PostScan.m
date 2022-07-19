%% Environment & Set-up, clean up 
% contact treadlab @ emory 
addpath(genpath('/Applications/Psychtoolbox'))
fclose('all'); 
sca
clc

% PTB basic
AddPsychJavaPath;
LoadPsychHID;
PsychJavaTrouble;

Screen('Preference', 'SkipSyncTests', 15);

% function handles

HomeDir = 'C:\Users\zrent\Documents\PlattLab\Summer\Staggered_EBDM_Experiment\eefrt_staggeredv2'; % MUST BE MODIFIED
DataDir = '/DATA';
cd(HomeDir);


%Prompt subject number
subjectID = input('Please input the subject ID number: ','s');


%Prompt experimenter for trial run
runFileSelect = input('Please select run number (1-4): ');
switch(runFileSelect)
    case 1
        run = 1;
    case 2
        run = 2;
    case 3
        run = 3;
    case 4
        run = 4;
end


%Prompt experimenter for avg max effort
maxeffort = input('Please input subject''s avg. max. effort: ');


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

%Which order of sides will effort and reward be displayed on
sideOrderQ = input('Which order of Left/Right Prese5ntation? (1 or 2) ');


%_______________________________________________________________________________________
%%  Import Logfile from previous scan
    %filename = [HomeDir '/DATA/' subjectID '/EEfRT_' subjectID '_run' num2str(run) '.csv'];
    filename = 'C:\Users\zrent\Documents\PlattLab\Summer\Staggered_EBDM_Experiment\eefrt_staggeredv2\DATA_practice\516\516.csv';
    delimiter = ',';
    formatSpec = '%*s%*s%*s%*s%*s%*s%*s%*s%*s%s%[^\n\r]';

    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
    fclose(fileID);

    raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
    for col=1:length(dataArray)-1
        raw(1:length(dataArray{col}),col) = dataArray{col};
    end
    numericData = NaN(size(dataArray{1},1),size(dataArray,2));

    rawData = dataArray{1};
    for row=1:size(rawData, 1);
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;

            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(thousandsRegExp, ',', 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, 1) = numbers{1};
                raw{row, 1} = numbers{1};
            end
        catch me
        end
    end

    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
    raw(R) = {NaN}; % Replace non-numeric cells
    expraw = raw;

    %Create output variable
    responseVec = cell2mat(raw);
    responseVec = responseVec==1;
    responseVec = responseVec(2:end,1);


%__________________________________________________________________________
%%  Import experiment datafile
    filename = [HomeDir '/runOrders/run' num2str(run) 'V2.csv'];
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
        for row=1:size(rawData, 1);
            regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
            try
                result = regexp(rawData{row}, regexstr, 'names');
                numbers = result.numbers;

                invalidThousandsSeparator = false;
                if any(numbers==',');
                    thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                    if isempty(regexp(thousandsRegExp, ',', 'once'));
                        numbers = NaN;
                        invalidThousandsSeparator = true;
                    end
                end
                if ~invalidThousandsSeparator;
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

    % Allocate imported array to column variable names
    cueCard = [rawCellColumns(responseVec, 1)];
    orderVec = cell2mat(rawNumericColumns(responseVec, 1));
    rewardVecBin = cell2mat(rawNumericColumns(responseVec, 2));
    rewardVec = cell2mat(rawNumericColumns(responseVec, 3));
    effortVec = cell2mat(rawNumericColumns(responseVec, 4));

    % Clear temporary variables
    clearvars filename delimiter formatSpec fileID dataArray ans col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me rawNumericColumns rawCellColumns;

    
%% Setup LogFile
fileName = fullfile(HomeDir,DataDir,subjectID,['EEfRT_PostScan_' subjectID '_run' num2str(run) '.csv']);
if exist(fileName) > 0
    error(['A data file for this subject/run already exists. '...
        'Please enter a new subject/run combination or delete the existing file to proceed.'])
end  
dataFile = fopen(fileName, 'a');
% print column labels
    fprintf(dataFile,['Subject,'... % subject number
    'Run,'...           % run number
    'RunStart,'...      % run Start
    'Trial,'...         % trial number
    'cueOnset,'...      % onset of effort/RM info
    'Response,'...      % choice (High effort vs/ No Effort)
    'PrevResponse,'...  % response when they did it in the scanner
    'Reward,'...        % reward
    'Effort,'...        % Effort
    'RT,'...            % reaction time
    'Completed,'...     % completed = 1, not completed = 0
    'Trigger,' ...
    'ITI_Onset,' ...
    'ITI_Offset,' ...
    'Handedness,' ...
    '\n']);
%             subj,run,runStart,i,cueOnset, ...
%             ,response,prevresponse,reward,effort,rt,Trigger,ITIOnset,ITIOffset);
%          


%% Prep PTB Screen and Inputs
%Screen('Preferences', 'SkipSyncTests', 1);
subj = str2num(subjectID);
clc
HideCursor;

[win, ScrRect] = Screen('OpenWindow', max(Screen('Screens')));
xCenter = ScrRect(3)/2;
yCenter = ScrRect(4)/2;
leftRect=[xCenter-350,yCenter-215,xCenter-150,yCenter+215];  %for labuser
rightRect=[xCenter+200,yCenter-215,xCenter+450,yCenter+215];  %for labuser
centerspot = 800;
fMRI = 1; %%%%%%CHANGE IF NEEEDED######################################################################
if max(Screen('Screens')) > 1
    fMRI = 1;
end

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

completionStatus = 0;
checkidx = 1;

% button setup for scanner or behavioral
KbName('UnifyKeyNames') %NEED FOR EMORY SYSTEM!!!
    TRIG  = KbName('t');
    LEFT  = KbName('s'); %TOP (blue) button on button box - hit with thumb HARD
    RIGHT = KbName('g'); %Next (yellow) button on button box EASY
    DONE  = KbName('Space'); %Next (yellow) button on button box EASY
    if handedness == 1
        HARD = KbName('s'); %S
        EASY = KbName('g'); %L
    elseif handedness == 2
        HARD = KbName('k'); %S
        EASY = KbName('g'); %L
    end
    
device = max(GetKeyboardIndices);

%Obtain keyboard name
[id,name] = GetKeyboardIndices; % get a list of all devices connected

%Create keylist containing trigger
keys=[TRIG HARD EASY LEFT RIGHT DONE];
keylist=zeros(1,256); %%create a list of 256 zeros

keylist(keys)=1; %%set keys you're interested in to 1

KbQueueCreate(device, keylist);  %23 = trig KEYCODE
KbQueueStart(device);


%% Wait for Initial Pulse        
% waits for trigger in scanner version
DrawFormattedText(win,'The task will begin momentarily.','center','center',White);
Screen('Flip',win);
runStart = GetSecs;


%Counterbalanced presentation side orders.
if sideOrderQ == 1
    sideOrder = [0,1,1,1,0,0,0,1,0,1,1,1,0,0,0,1,0,1,1,1,0,1,0,1,0,1,1,0,0,0,1,1,1,0,1,1,0,1,0,0,0,1,0,0,0,0,1,1];
elseif sideOrderQ == 2
    sideOrder = [1,1,0,0,0,0,1,0,0,0,1,0,1,1,0,1,1,1,0,0,0,1,1,0,1,0,1,0,1,1,1,0,1,0,0,0,1,1,1,0,1,0,0,0,1,1,1,0];
end
        
responseVec = responseVec(responseVec);
%% Begin Trial Loop
for i = 1:length(responseVec) %BEGIN TRIALS
% for i = 1:1

        FontName = 'Arial';
        FontLg = 72;
        FontSm = 18;
        Xres = ScrRect(3);
        Yres = ScrRect(4);
        Dres = sqrt(Xres^2+Yres^2)/1500;
        Screen('FillRect',win,Black);
        Screen('TextFont',win,FontName);
        Screen('TextSize',win,FontLg);
    
        reward = rewardVec(i) + rewardVecBin(i);
        effort = effortVec(i);
        prevresponse = (responseVec(i));
    
        %% Present 2nd Cue and 1st Cue
        CueScreen1 = imread(['STIM/' cueCard{i,1}], 'png');
        Cue1Texture = Screen('MakeTexture',win,CueScreen1);
        
        
        if sideOrder(i) == 1
            Screen('DrawTexture',win,Cue1Texture, [],leftRect);
            DrawFormattedText(win,['$' num2str(reward)],900,'center',White);
        elseif sideOrder(i) == 0
            Screen('DrawTexture',win,Cue1Texture, [],rightRect);
            DrawFormattedText(win,['$' num2str(reward)],200,'center',White);
        end
        
        KbQueueFlush(device);
        if responseVec(i) == 1
            DrawFormattedText(win,'You previously chose Effort','center',30,White);
        elseif responseVec(i) == 0
            DrawFormattedText(win,'You previously chose No Effort','center',30,White);
        end
        Screen(win, 'Flip');

        cueOnset = GetSecs-runStart;
        respTime = GetSecs;
        
        %Check for Press
        while 1
            [pressed, firstpress, firstrelease, lastPress, lastRelease] = KbQueueCheck(device); %check response
            if pressed==1 && lastPress(HARD)
                response = 1; %HARD OPTION
                rt = GetSecs-respTime;
                CueAllOffset = GetSecs - runStart;
                
                if sideOrder(i) == 1
                    Screen('DrawTexture',win,Cue1Texture, [],leftRect);
                    DrawFormattedText(win,['$' num2str(reward)],900,'center',White);
                elseif sideOrder(i) == 0
                    Screen('DrawTexture',win,Cue1Texture, [],rightRect);
                    DrawFormattedText(win,['$' num2str(reward)],200,'center',White);
                end

                if responseVec(i) == 1
                    DrawFormattedText(win,'You previously chose Effort','center',30,White);
                elseif responseVec(i) == 0
                    DrawFormattedText(win,'You previously chose No Effort','center',30,White);
                end
                DrawFormattedText(win,'Accepted','center','center',Green);
%                 Screen('FrameOval', win, Green, [300; 150; 750; 750],6,6);  %[left,top,right,bottom]
                Screen(win, 'Flip');
                break;
            elseif pressed==1 && lastPress(EASY)
                response = 0; %EASY OPTION
                rt = GetSecs-respTime;
                CueAllOffset = GetSecs - runStart;
                
                if sideOrder(i) == 1
                    Screen('DrawTexture',win,Cue1Texture, [],leftRect);
                    DrawFormattedText(win,['$' num2str(reward)],900,'center',White);
                elseif sideOrder(i) == 0
                    Screen('DrawTexture',win,Cue1Texture, [],rightRect);
                    DrawFormattedText(win,['$' num2str(reward)],200,'center',White);
                end
                if responseVec(i) == 1
                    DrawFormattedText(win,'You previously chose Effort','center',30,White);
                elseif responseVec(i) == 0
                    DrawFormattedText(win,'You previously chose No Effort','center',30,White);
                end
                DrawFormattedText(win,'Rejected','center','center',Red);
%                 Screen('FrameOval', win, Green, [725; 150; 1175; 750],8,8);  %[left,top,right,bottom]
                Screen(win, 'Flip');
                break;
            else pressed==0  
            end
        end
        WaitSecs(0.5);

        if pressed ==1 && lastPress(HARD)
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

            currentEffort = effortVec(i) * maxeffort;
            timeDelta = 21;

            displayRows = round(499/(maxeffort)); %This is the number of pixel rows to "fill" dependent on the difficulty of the task.

            while (currentTime < startTime+timeDelta) && (goalReachedCount2 < ((currentEffort))) %While the time has not yet expired
                [pressed, secs, kbData] = KbCheck;
                if (pressed == 1) && (kbData(HARD) == 1) && (acceptingInput==1)
                    if round(499-goalReachedCount2*displayRows) < 0
                        goalReachedCount2 == currentEffort;
                    else
                        progressBarMatrix(round(499-goalReachedCount2*displayRows),:) = 0; % "Fills" the progress bar based on the task difficulty
                    end
                    goalReachedCount2 = goalReachedCount2 + 1; % Increment the number of key presses logged.
                    pause(0.1);
                    acceptingInput=0;
                end

                currentTime = GetSecs;
                Screen('TextSize',win, 30);
                Screen('DrawText', win, strcat('Time HARD:', 32, 32,num2str((startTime+timeDelta)-currentTime)), 800,200, [255,255,255]); %Show remaining time
                Screen('DrawText', win, strcat('Push:', 32, 32 , KbName(HARD),' until bar is', 32, num2str((effortVec(i)*100)),'% full.'),700, 700, [255,255,255]); %Show reminder.
                Screen(win,'PutImage',progressBarMatrix); % Display to window pointer
                Screen(win, 'Flip'); % Write framebuffer to display

                if pressed~=1
                    acceptingInput=1;
                end
            end    

            completionTime = currentTime - startTime;

            %Check for completion status 
            if goalReachedCount2 >= ((currentEffort));
                completionStatus = 1;
            else
                completionStatus = 0;
            end
            if completionStatus == 1
                    Screen('TextSize',win, 30);
                    Screen(win,'FillRect',0);
                    Screen(win, 'Flip');

                    if (response == 1) %hard
                        DrawFormattedText(win, 'You reached the assigned number of key presses!','center',500, 255);
                        DrawFormattedText(win, ['You''ve earned $' num2str(reward) ' for completing this trial.'], 'center', 600, 255);
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
        end
        ITIOnset = GetSecs-runStart;
        WaitSecs(1.5)
        
        %% ITI / Fixation
        DrawFormattedText(win,'+','center','center',White);
        Screen('Flip',win);
        Trigger=1;
        WaitSecs(0.5);  
        ITIOffset = GetSecs-runStart;
       
        % writes trial data to file
        fprintf(dataFile,'%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f, \n',...
            subj,run,runStart,i,cueOnset, ...
            response,prevresponse,reward,effort,rt,completionStatus,Trigger,ITIOnset,ITIOffset,handedness);

                 
    %% Happiness Check In
    checkintimes = [0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0];
    if checkintimes(i) == 1
        ratingQs = {'How happy are you right now?'};
        scale1Vec = {'0'};
        scale2Vec = {'100'};
        Screen('TextSize',win,FontSm);
        slack = Screen('GetFlipInterval', win); %/2
        vbl = Screen('Flip', win);

        commandwindow;
        baseRect = [0 0 10 30];
        xshift = 250;
        LineX = xCenter-xshift; %960+-250
        LineY = yCenter;
        rectColor = [255 255 255];
        pixelsPerPress = 20;
        waitframes = 1;

        %Check for button press
        while KbCheck; end

            while true
                [ keyIsDown, secs, keyCode ] = KbQueueCheck(device);
                pressedKeys = find(keyCode);
                if keyCode(LEFT)
                    LineX = LineX - pixelsPerPress;
                elseif keyCode(RIGHT)
                    LineX = LineX + pixelsPerPress;
                elseif pressedKeys == DONE
                    StopPixel_M = (((LineX - xCenter-xshift) + 250)/5)+100;
                    break;
                elseif keyCode(DONE)
                    StopPixel_M = (((LineX - xCenter-xshift) + 250)/5)+100;
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
                text_P = ratingQs{1};
                centeredRect = CenterRectOnPointd(baseRect, LineX, LineY);
                DrawFormattedText(win, text_P ,xCenter-250-xshift, (yCenter-100), [255, 255, 255],...
                    [],[],[],5)
                Screen('DrawLine', win, [255, 255, 255], (xCenter+250-xshift ), (yCenter), ...
                    (xCenter-250-xshift), (yCenter), 1);
                Screen('DrawLine', win, [255, 255, 255], (xCenter+250-xshift ), (yCenter+10),...
                    (xCenter+250-xshift), (yCenter-10), 1);
                Screen('DrawLine', win, [255, 255, 255], (xCenter-250-xshift ), (yCenter+10),...
                    (xCenter- 250-xshift), (yCenter-10), 1); 
                Screen('DrawText', win,scale1Vec{1}, (xCenter-300-xshift), (yCenter+25),...
                    [255, 255, 255]);
                Screen('DrawText', win,scale2Vec{1}, (xCenter+200-xshift), (yCenter+25),...
                    [255, 255, 255]);
                Screen('FillRect', win, rectColor, centeredRect);
                vbl = Screen('Flip', win, vbl + (waitframes - 0.5) * slack);
            end

        vasResp(checkidx) = StopPixel_M; 

        ShowCursor
        ListenChar(0);

        fileName = fullfile(HomeDir,DataDir,subjectID,['EEfRT_PostScan_momentaryratings_' subjectID '_run' num2str(run) '.csv']);
        dataFile = fopen(fileName, 'a');
        fprintf(dataFile,'%f,%f,%s,%s,%s,%f, \n',...
         subj, ...               % Subject number
         run, ...                % Run number
         ratingQs{1}, ... % Question asked to subject for rating
         scale1Vec{1}, ...% Wording on lower end of scale 
         scale2Vec{1}, ...% Wording higher end of scale
         vasResp(checkidx));     % 1-100 rating scale
     
     
        fileName = fullfile(HomeDir,DataDir,subjectID,['EEfRT_PostScan_' subjectID '_run' num2str(run) '.csv']);
        dataFile = fopen(fileName, 'a');
    else
    end
    checkidx = checkidx + 1;
end
fclose(dataFile);


%% All Done
%Close PTB Window
sca;


