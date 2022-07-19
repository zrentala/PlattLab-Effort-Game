% Max Effort Task 
% contact treadlab at emory university
%%
% clean up
addpath(genpath('/Applications/Psychtoolbox'))
clear all
fclose('all'); 
sca
clc

% PTB basics 
AddPsychJavaPath; 
LoadPsychHID;
PsychJavaTrouble;

FontSm = 18;

n2s = @num2str;

%Set Paths
cd('C:\Users\zrent\Documents\PlattLab\Summer\Staggered_EBDM_Experiment\eefrt_scanner_practice'); % UPDATE this path
addpath(pwd);
addpath([pwd '/STIM']);

% Subject information 
 prompt = {'Subject number: ','Handedness (l/r):'};
 defaults = {'',''};
 dlgout = inputdlg(prompt,'',1,defaults);
 subjectID  = str2double(dlgout{1});
 dexterity = dlgout{2};
 
% Set up output
Screen('Preference', 'SkipSyncTests', 0); % CANGE
homedir = 'C:\Users\zrent\Documents\PlattLab\Summer\Staggered_EBDM_Experiment\eefrt_scanner_practice'; %UPDATE PATH
datadir = '/LogFiles/DATA_practice';
subjdir = [homedir datadir '/' n2s(subjectID)];
mkdir(subjdir);
filename = fullfile(homedir, [datadir '/' n2s(subjectID) '/' n2s(subjectID) '.csv']);
%dataFileName='MaxEffortData';\\
%dataFile=fopen(filename,'a+');
if exist(filename) > 0
    error(['A data file for this subject/run already exists. '...
        'Please enter a new subject/run combination or delete the existing file to proceed.'])
end  
dataFile = fopen(filename, 'a');
 if dataFile == -1
    error('Error opening data file!');
 end
 
fprintf(dataFile,['subjectID,'...
    'dexterity,'...
    'calibration,'...
    'goalReachedCount,'...
    'trial,'...
    'maxEffortPresses1,'...
    'maxEffortPresses2,'...
    'maxEffortPresses3,'...
    'aveMaxEffort,'...
    'AssignedEffort,'...
    'RecordedEffort,'...
    'completionStatus,'...
    'calRT,'...
    'trialRT,'...
    '\n']);

% Set up screen 
Screen('Preference', 'SkipSyncTests', 1);  %CHANGE
% Call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
screenNumber = max(screens); 

% Set up screen display
resX = 1280;
resY = 1024; 
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);


xCenter=windowRect(3)/2;
yCenter=windowRect(4)/2;
Xres = windowRect(3);
Yres = windowRect(4);

escapeKey = KbName('ESCAPE');
leftKey = KbName('s');
rightKey = KbName('l');
leftarrow = KbName('LeftArrow');
rightarrow = KbName('RightArrow');
DONE = KbName('Space');

twentyBar = [homedir '/STIM/twentybar.png'];  
fiftyBar = [homedir '/STIM/fiftybar.png'];
eightyBar = [homedir '/STIM/eightybar.png']; 
hundredBar = [homedir '/STIM/hundredbar.png'];

twentyBarData=imread(twentyBar);
twentyBarTexture=Screen('MakeTexture',window,twentyBarData);
fiftyBarData=imread(fiftyBar);  
fiftyBarTexture=Screen('MakeTexture',window,fiftyBarData);
eightyBarData=imread(eightyBar); 
eightyBarTexture=Screen('MakeTexture',window,eightyBarData);
hundredBarData=imread(hundredBar); 
hundredBarTexture=Screen('MakeTexture',window,hundredBarData);

% Fixation cross 
calIm = [homedir '/STIM/fixation.bmp'];
calibrationImage = imread(calIm,'bmp');
Screen(window,'PutImage',calibrationImage); %Display fixation
Screen(window, 'Flip');
WaitSecs(1);

% Set up dexterity instructions 
    commandwindow;
    if dexterity == 'l'; 
        Screen('TextSize',window, 30);
        DrawFormattedText(window, 'Press "l" with your right pinky finger as fast as you can until the timer counts down.','center',500,[255,255,255]);
        DrawFormattedText(window, 'You will be asked to do this three times.','center',800,[255,255,255]);
        DrawFormattedText(window,'Press any key to continue the experiment.','center',1000,[255,255,255]);
        Screen(window,'Flip');
        WaitSecs(.5);
        KbWait; % Wait for key press
    else dexterity == 'r';
        Screen('TextSize',window, 30);
        DrawFormattedText(window,'Press "s" with your left pinky finger as fast as you can until the timer counts down.','center',500,[255,255,255]);
        DrawFormattedText(window, 'You will be asked to do this three times.','center',800,[255,255,255]);
        DrawFormattedText(window,'Press any key to continue the experiment.','center',1000,[255,255,255]);
        Screen(window,'Flip');
        WaitSecs(.5);
        KbWait; % Wait for key press
        WaitSecs(.5);
    end
    
    % Ready?
    Screen('TextSize',window, 40);
    DrawFormattedText(window,'Ready?','center',500,[255,255,255]);
    DrawFormattedText(window,'Press any key to continue.','center',700,[255,255,255]);
    Screen(window,'Flip');
    WaitSecs(.5);
    KbWait; % Wait for key press
    WaitSecs(.5);
    
    % Set up progress bar
    progressBarMatrix = ones(500,100);
    progressBarMatrix = progressBarMatrix*256;
    progressBarMatrix(1:2,:) = 0;
    progressBarMatrix(499:500,:) = 0;
    progressBarMatrix(:,1:2) = 0;
    progressBarMatrix(:,99:100) = 0;

    Screen(window,'PutImage',progressBarMatrix);
    Screen(window, 'Flip'); 
       
    % Set the time and number of presses 
        numberOfPresses = 200;
        timeDelta = 21;
  
    % Button setup
    KbName('UnifyKeyNames');
    
    if (dexterity == 'r');
        requiredKeyPosition = KbName('s');
        showKey = 's';
    else (dexterity == 'l');
        requiredKeyPosition = KbName('l');
        showKey = 'l';
    end
        
    reactionTime = 0;

    displayRows = floor(499/numberOfPresses); %This is the number of pixel rows to "fill" dependent on the difficulty of the task.

    goalReachedCount = 0;
    maxEffortPresses = 0;
    effortOutput1 = 0;
    effortOutput2 = 0;
    effortOutput3 = 0;
    
    acceptingInput = 1; 
    
    currentTime = GetSecs;
    startTime=GetSecs;
   
    % Button press loop 
    
    for calibration = 1:3; 
        
        goalReachedCount(calibration) = 0;
        acceptingInput = 1; 
        currentTime = GetSecs;
        startTime=GetSecs;
         
        progressBarMatrix = ones(500,100);
        progressBarMatrix = progressBarMatrix*256;
        progressBarMatrix(1:2,:) = 0;
        progressBarMatrix(499:500,:) = 0;
        progressBarMatrix(:,1:2) = 0;
        progressBarMatrix(:,99:100) = 0;
   
        secs0=GetSecs;
        while (currentTime < startTime+timeDelta) %While the time has not yet expired...
            [pressed, secs, kbData] = KbCheck;
            if (pressed == 1) && (kbData(requiredKeyPosition) == 1) && (acceptingInput==1)
                progressBarMatrix(round(499-(goalReachedCount(calibration))*displayRows),:) = 0; % "Fills" the progress bar based on the task difficulty
                goalReachedCount(calibration) = goalReachedCount(calibration) + 1; %Increment the number of key presses logged.
                pause(0.1);
                acceptingInput=0;
            end
        currentTime = GetSecs;
        Screen('TextSize',window, 40);
        DrawFormattedText(window, strcat('Time left:', 32, 32,num2str((startTime+timeDelta)-currentTime)), 800, 200, [255,255,255]); %Show remaining time
        DrawFormattedText(window, strcat('Push: ', 32, 32,showKey,' until bar is full.'),800, 850, [255,255,255]); %Show reminder.

        Screen(window,'PutImage',progressBarMatrix); %Display to window 
        Screen(window, 'Flip'); %Write framebuffer to display
    
        if pressed~=1
        acceptingInput=1;
        end
        end
        
        calRT=secs-secs0; % Get reaction time 

    % Check for completion of key presses
    completionTime = currentTime - startTime; 
    

            Screen(window,'FillRect',0);
            Screen(window, 'Flip');
        DrawFormattedText(window,'Ready?','center',500,[255,255,255]);
            DrawFormattedText(window,'Press any key to continue.','center',700,[255,255,255]);
            WaitSecs(1.0);
            Screen(window, 'Flip');
            KbWait; % Wait for key press


    effortOutput(calibration)=goalReachedCount(calibration);
            
    end

        effortOutput1 = goalReachedCount(1);
        effortOutput2 = goalReachedCount(2);
        effortOutput3 = goalReachedCount(3);
      
    

    maxEffortPresses = [effortOutput1, effortOutput2, effortOutput3];
    
    aveMaxEffort = mean(maxEffortPresses);

    % Instructions for 2nd phase
    Screen('TextSize',window, 24);
    if dexterity == 'l';
        %text = sprintf('Your maximum number of key presses was %d.', goalReachedCount);
        DrawFormattedText(window, 'When you go into the scanner you will be asked to make choices between- ','center',200,[255,255,255]);
        DrawFormattedText(window, 'effort and no effort in exchange for different amounts of money.','center',250,[255,255,255]);
        DrawFormattedText(window, 'While in the scanner, you will make choices about whether to expend 20%, 50%, 80% or 100% effort.','center',300,[255,255,255]);
        DrawFormattedText(window, 'You will complete the effort you choose at the end of the study.','center',350,[255,255,255]);
        DrawFormattedText(window, 'Press "l" with your right pinky finger to reach the assigned number of key presses.','center',550,[255,255,255]);
        DrawFormattedText(window, 'Press any key to continue the experiment.','center',600,[255,255,255]);
        Screen(window,'Flip');
        WaitSecs(2);
        KbWait;
    else dexterity == 'r';
        %text = sprintf('Your maximum number of key presses was %d.', goalReachedCount);
        %text = sprintf('Your maximum number of key presses was %d.', goalReachedCount);
        DrawFormattedText(window, 'In this task you will be asked to make choices between effort and no effort-','center',200,[255,255,255]);
        DrawFormattedText(window, 'in exchange for different amounts of money.','center',250,[255,255,255]);
        DrawFormattedText(window, 'While in the scanner, you will make choices about whether to expend 20%, 50%, 80% or 100% effort. ','center',300,[255,255,255]);
        DrawFormattedText(window, 'You will complete the effort you choose at the end of the study.','center',350,[255,255,255]);
        DrawFormattedText(window, 'Press "s" with your left pinky finger to reach the assigned number of key presses.','center',550,[255,255,255]);
        DrawFormattedText(window, 'Press any key to continue the experiment.','center',600,[255,255,255]);
        Screen(window,'Flip');
        WaitSecs(2);
        KbWait;
    end

    numtrial = 0;
    
% Trial loop based on max effort button presses
for trial = 1:8 % number of practice trials; let'a go with 8 for now
    numtrial = numtrial+1;
    
    % Ready?
DrawFormattedText(window,'Ready?','center','center',0);
    Screen('Flip',window);
    WaitSecs(3);
    Screen(window, 'Flip');
    pause(1); 

    Screen(window,'PutImage',progressBarMatrix); 
    Screen(window, 'Flip'); 
       
    % Set up progress bar
    progressBarMatrix = ones(500,100);
    progressBarMatrix = progressBarMatrix*256;
    progressBarMatrix(1:2,:) = 0;
    progressBarMatrix(499:500,:) = 0;
    progressBarMatrix(:,1:2) = 0;
    progressBarMatrix(:,99:100) = 0;
    
    %Set the time and number of presses 
        numberOfPresses = 200;
        timeDelta = 21;
  
    % Button setup
    KbName('UnifyKeyNames');
    
    if (dexterity == 'r');
        requiredKeyPosition = KbName('s');
        showKey = 's';
    else (dexterity == 'l');
        requiredKeyPosition = KbName('l');
        showKey = 'l';
    end
       
    percentMaxEffort = [.5, 1, .2, 1, .8, .5, .8, .2]; % Percentage of key presses order; edit to follow 
    % number of prax trials
    %Shuffle = percentMaxEffort;
    %percentMaxEffort = percentMaxEffort{ceil(rand(1)*length(percentMaxEffort))};
    
    %displayRows = floor(499/(aveMaxEffort)); %This is the number of pixel rows to "fill" dependent on the difficulty of the task.
    displayRows = floor(499/(aveMaxEffort)); %This is the number of pixel rows to "fill" dependent on the difficulty of the task.
    
    format short 
    
    if trial ==  3 || trial ==  8;
        %Screen(window, 'DrawText','Press any key to continue the experiment.', 800,125,[255,255,255]);
        Screen('DrawTexture',window,twentyBarTexture);
        Screen('TextSize',window, 20);
        DrawFormattedText(window,'Now you have the opportunity to practice reaching 20% of your average maximum effort.', 'center',25,[255,255,255]);
        Screen(window,'Flip');
        WaitSecs(4);
        percent='20';
    elseif trial ==  1 || trial == 6;
        %Screen(window, 'DrawText','Press any key to continue the experiment.', 800,125,[255,255,255]);
        Screen('DrawTexture',window,fiftyBarTexture);
        Screen('TextSize',window, 20);
        DrawFormattedText(window,'Now you have the opportunity to practice reaching 50% of your average maximum effort.', 'center',25,[255,255,255]);
        Screen(window,'Flip');
        WaitSecs(4);
        percent='50';
    elseif trial ==  5 || trial == 7;
        %Screen(window, 'DrawText','Press any key to continue the experiment.', 800,125,[255,255,255])
        Screen('DrawTexture',window,eightyBarTexture);
        Screen('TextSize',window, 20);
        DrawFormattedText(window,'Now you have the opportunity to practice reaching 80% of your average maximum effort.', 'center',25,[255,255,255]);
        Screen(window,'Flip');
        WaitSecs(4);
        percent='80';
    elseif trial == 2 || trial ==  4;
        %Screen(window, 'DrawText','Press any key to continue the experiment.', 800,125,[255,255,255]);
        Screen('DrawTexture',window,hundredBarTexture);
        Screen('TextSize',window, 20);
        DrawFormattedText(window,'Now you have the opportunity to practice reaching 100% of your average maximum effort.', 'center',25,[255,255,255]);
        Screen(window,'Flip');
        WaitSecs(4);
        percent='100';
    end
   
    reactionTime = 0;
    
    goalReachedCount2 = 0;

    acceptingInput = 1; 

    currentTime = GetSecs;
    startTime = GetSecs;
    
    % Loop for button press response 
    secs0=GetSecs;
    while (currentTime < startTime+timeDelta) && (goalReachedCount2 < ((percentMaxEffort(numtrial))*(aveMaxEffort))) %While the time has not yet expired
        [pressed, secs, kbData] = KbCheck;
        if (pressed == 1) && (kbData(requiredKeyPosition) == 1) && (acceptingInput==1)
            progressBarMatrix(499-goalReachedCount2*displayRows,:) = 0; % "Fills" the progress bar based on the task difficulty
            %progressBarMatrix(goalReachedCount2*displayRows,:) = 0; % "Fills" the progress bar based on the task difficulty
            goalReachedCount2 = goalReachedCount2 + 1; % Increment the number of key presses logged.
            pause(0.1);
            acceptingInput=0;
        end
        currentTime = GetSecs;
        Screen('TextSize',window, 20);
        Screen('DrawText', window, strcat('Time left:', 32, 32,num2str((startTime+timeDelta)-currentTime)), 800,200, [255,255,255]); %Show remaining time
        Screen('DrawText', window, strcat('Push:', 32, 32 ,showKey,' until bar is', 32, percent,'% full.'),800, 850, [255,255,255]); %Show reminder.
        %text = sprintf('%d key presses.',((percentMaxEffort(numtrial))*(aveMaxEffort)));
        %Screen(window, 'DrawText', text, 800,900,[255,255,255]);
        Screen(window,'PutImage',progressBarMatrix);     % Display to window pointer
        Screen(window, 'Flip');     % Write framebuffer to display
    
        if pressed~=1
        acceptingInput=1;
        end
    end
    
    trialRT=secs-secs0; % Get reaction time 

    completionTime = currentTime - startTime;
    
    %Check for completion status 
    if goalReachedCount2 >= ((percentMaxEffort(numtrial))*(aveMaxEffort));
        completionStatus = 1;
    else
        completionStatus = 0;
    end
   
    %Report on completion status 
    if completionStatus == 1
            Screen('TextSize',window, 20);
            Screen(window,'FillRect',0);
            Screen(window, 'Flip');
            DrawFormattedText(window, 'You reached the assigned number of key presses!','center',500, 255);
            Screen(window, 'Flip');
            pause(2.0);
    else
            Screen('TextSize',window, 20);
            Screen(window,'FillRect',0);
            Screen(window, 'Flip');
            DrawFormattedText(window, 'You did not reach the assigned number of key presses!','center',500, 255);
            Screen(window, 'Flip');
            pause(2.0);
    end 
            
   
    fprintf(dataFile, '%s,%s,%s,%s,%s,%d,%d,%d,%s,%s,%s,%s,%s,%s,\n', ...
        num2str(subjectID), dexterity, num2str(calibration), ...
        num2str(goalReachedCount), num2str(trial), effortOutput1, effortOutput2, effortOutput3, ...
        num2str(aveMaxEffort), num2str((percentMaxEffort(numtrial))*(aveMaxEffort)), ...
        num2str(goalReachedCount2),num2str(completionStatus),num2str(calRT), ...
        num2str(trialRT));
  
    cd ../
    
ShowCursor
ListenChar(0);
      
end

fclose(dataFile);
copyDir = [homedir '/logfiles/DATA_practice_copy/'];
copyfilename = fullfile(copyDir, ['EEfRT_practice_' n2s(subjectID) '_raw.csv']);
copyfile(filename,copyfilename);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear screen
Screen('Flip',window);
fclose(dataFile);

close all;