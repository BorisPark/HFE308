function demo3()
%----------------------------------------------------------------------
%                           REVISE RECORD
%----------------------------------------------------------------------
% 19.11.25 - target appearance time: 0.5sec -> 1sec
%----------------------------------------------------------------------

%----------------------------------------------------------------------
%                           Screen Setting
%----------------------------------------------------------------------

Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebugLevel', 1);
Screen('Preference', 'SuppressAllWarnings', 1);

% Clear the workspace
close all;
clearvars;
sca;

% Setup PTB with some default values
PsychDefaultSetup(2);

baseSettings = load('baseSettings.mat');
breakFirst = baseSettings.numTrials * (1 / 4);
breakSecond = baseSettings.numTrials * (2 / 4);
breakThird = baseSettings.numTrials * (3 / 4);

% Seed the random number generator. Here we use the an older way to be
% compatible with older systems. Newer syntax would be rng('shuffle'). Look
% at the help function of rand "help rand" for more information
% rand('seed', sum(100 * clock));
rng('default');
rng('shuffle');

% Set the screen number to the external secondary monitor if there is one
% connected
screenNumber = max(Screen('Screens'));

% Define black, white and grey
white = WhiteIndex(screenNumber);
grey = white / 2;
black = BlackIndex(screenNumber);

% Open the screen
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, white, [], 32, 2);

% Flip to clear
Screen('Flip', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set the text size
Screen('TextSize', window, 60);

% Query the maximum priority level
topPriorityLevel = MaxPriority(window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Set the blend funciton for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%----------------------------------------------------------------------
%                             Sound Setting
%----------------------------------------------------------------------

% Initialize Sounddriver
InitializePsychSound(1);

% Number of channels and Frequency of the sound
nrchannels = 2;
freq = 48000;

% How many times to we wish to play the sound
repetitions = 0;

% Length of the beep
beepLengthSecs = baseSettings.beepLength;

% Length of the pause between beeps
beepPauseTime = 1;

% Start immediately (0 = immediately)
startCue = 0;

% Should we wait for the device to really start (1 = yes)
% INFO: See help PsychPortAudio
waitForDeviceStart = 1;

% Open Psych-Audio port, with the follow arguements
% (1) [] = default sound device
% (2) 1 = sound playback only
% (3) 1 = default level of latency
% (4) Requested frequency in samples per second
% (5) 2 = stereo input
pahandle = PsychPortAudio('Open', [], 1, 1, freq, nrchannels);

% Set the volume to 0.4 for this demo
PsychPortAudio('Volume', pahandle, 0.4);

% Make a beep which we will play back to the user
% 700 Hz is the for the target, as same as Beeper
myBeep = MakeBeep(880, beepLengthSecs, freq);

% Fill the audio playback buffer with the audio data, doubled for stereo
% presentation
PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);
% PsychPortAudio('FillBuffer', pahandle, myBeep);

%----------------------------------------------------------------------
%                       Timing Information
%----------------------------------------------------------------------

% Interstimulus interval time in seconds and frames
isiTimeSecs = 1;
isiTimeFrames1Sec = round(isiTimeSecs / ifi);
isiTimeFramesHalfSec = round((isiTimeSecs / 2) / ifi);
isiTimeFrames3Sec = round((isiTimeSecs * 3) / ifi);

% Numer of frames to wait before re-drawing
waitframes = 1;

%----------------------------------------------------------------------
%                       Keyboard information
%----------------------------------------------------------------------

spacebarKey = KbName('space');
escapeKey = KbName('ESCAPE');

%----------------------------------------------------------------------
%                          Make Task Set
%----------------------------------------------------------------------

% Total 300 trials
% each of Catches 20
% each of Targets 80
% portion: 4 : 4 : 4 : 1 : 1 : 1

% stimulusPresentTime of catch will not be used

typeList = {'visual', 'auditory', 'visuaditory', 'v-catch', 'a-catch', 'va-catch'};
shuffler = Shuffle(repmat([[1 2 3 4] [1 2 3 5] [1 2 3 6] [1 2 3]], 1, baseSettings.numTrials / 15));
stimulusPresentTime = 2 * rand(1, baseSettings.numTrials);

taskSet = [shuffler; stimulusPresentTime];

%----------------------------------------------------------------------
%                      Make a response matrix
%----------------------------------------------------------------------

% This is a two row matrix
% 1: The type of task (V, A, VA, catch)
% 2: Response time (default: NaN)

respMat = nan(2, baseSettings.numTrials);

%----------------------------------------------------------------------
%                       Experimental loop
%----------------------------------------------------------------------

% Animation loop: we loop for the total number of trials
for trial = 1:baseSettings.numTrials
    
    PsychPortAudio('Stop', pahandle);

    % Type and PresentTime
    typeNum = taskSet(1, trial);
    SPT = taskSet(2, trial);

    % The type word
    theType = typeList(typeNum);

    % Cue to determine whether a response has been made
    respToBeMade = true;
    
    % Cue to determine further sound stimulus is needed
    soundToBeMade = true;
    soundStopped = false;

    % If this is the first trial we present a start screen and wait for a
    % key-press
    if trial == 1
        DrawFormattedText(window, 'Explain here \n\n Press Any Key To Begin',...
            'center', 'center', black);
        Screen('Flip', window);
        KbStrokeWait;
    end

    % Flip again to sync us to the vertical retrace at the same time as
    % drawing our fixation point
%     Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
%     % crossbar(window);
     vbl = Screen('Flip', window);

    % DEBUG
%     DrawFormattedText(window, sprintf('%d: Preliminary Cue', trial),...
%         'center', 'center', black);
%     vbl = Screen('Flip', window);
    
    % Preliminary Cue
    if (typeNum == 1 || typeNum == 4)
        for frame = 1:isiTimeFrames1Sec - 1

            % Draw the fixation point
            % Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
            crossbar(window);
        
            % Flip to the screen
            vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        end
    elseif (typeNum == 2 || typeNum == 5)
        beepMed();
    elseif (typeNum == 3 || typeNum == 6)
        beepMed();
        for frame = 1:isiTimeFrames1Sec - 1

            % Draw the fixation point
            % Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
            crossbar(window);
        
            % Flip to the screen
            vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        end
    end
    
    for frame = 1:isiTimeFrames1Sec - 1
       
        % Flip to the screen
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    end
    
    if (typeNum == 1)
        
        %DEBUG
%         DrawFormattedText(window, sprintf('%d: Visual', trial),...
%             'center', 'center', black);
%         Screen('Flip', window);
        
        WaitSecs(1 + SPT);
        
%         frameToWait = isiTimeFrames1Sec * (1 + SPT);
%         for frame = 1:frameToWait - 1
%             % Flip to the screen
%             vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
%         end
        
        tStart = GetSecs;
        for frame = 1:isiTimeFrames3Sec - 1
            
            % stimulus: visual
            if frame < isiTimeFrames1Sec - 1    
                circle(window);
                vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
            else
                vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
            end
            
            if respToBeMade == false
                break
            end
           
            [keyIsDown,secs, keyCode] = KbCheck;
            if keyCode(escapeKey)
                ShowCursor;
                sca;
                return
            elseif keyCode(spacebarKey)
                respToBeMade = false;
            end
            
            % vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        end
    elseif (typeNum == 2)
        
        %DEBUG
%         DrawFormattedText(window, sprintf('%d: Auditory', trial),...
%             'center', 'center', black);
%         Screen('Flip', window);
        
        WaitSecs(1 + SPT);
        
%         frameToWait = isiTimeFrames1Sec * (1 + SPT);
%         for frame = 1:frameToWait - 1
%             % Flip to the screen
%             vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
%         end
        
        tStart = GetSecs;
%         beepHigh();
        PsychPortAudio('Start', pahandle, repetitions, startCue, waitForDeviceStart);
        for frame = 1:isiTimeFrames3Sec - 1
            
            % stimulus: auditory
            if frame >= isiTimeFrames1Sec - 1
                if soundToBeMade == true
                    soundToBeMade = false;
                end
            end
            
            if soundToBeMade == false && soundStopped == false
                PsychPortAudio('Stop', pahandle, 1, 1);
                soundStopped = true;
            end
            
            if respToBeMade == false
                break
            end
           
            [keyIsDown,secs, keyCode] = KbCheck;
            if keyCode(escapeKey)
                if soundStopped == false
                    PsychPortAudio('Stop', pahandle, 1, 1);
                end
                ShowCursor;
                sca;
                return
            elseif keyCode(spacebarKey)
                soundToBeMade = false;
                respToBeMade = false;
            end
            
            vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        end
    elseif (typeNum == 3)
        
        %DEBUG
%         DrawFormattedText(window, sprintf('%d: Visuauditory', trial),...
%             'center', 'center', black);
%         Screen('Flip', window);
        
        WaitSecs(1 + SPT);
        
%         frameToWait = isiTimeFrames1Sec * (1 + SPT);
%         for frame = 1:frameToWait - 1
%             % Flip to the screen
%             vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
%         end
        
        tStart = GetSecs;
%         beepHigh();
        PsychPortAudio('Start', pahandle, repetitions, startCue, waitForDeviceStart);
        for frame = 1:isiTimeFrames3Sec - 1
            
            % stimulus: visuauditory
            if frame < isiTimeFrames1Sec - 1   
                circle(window);
                vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
            else
                if soundToBeMade == true
                    soundToBeMade = false;
                end
                vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
            end
            
            if soundToBeMade == false && soundStopped == false
                PsychPortAudio('Stop', pahandle, 1, 1);
                soundStopped = true;
            end
            
            if respToBeMade == false
                break
            end
           
            [keyIsDown,secs, keyCode] = KbCheck;
            if keyCode(escapeKey)
                if soundStopped == false
                    PsychPortAudio('Stop', pahandle, 1, 1);
                end
                ShowCursor;
                sca;
                return
            elseif keyCode(spacebarKey)
                soundToBeMade = false;
                respToBeMade = false;
            end
            
            % vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        end
    else
        % case: catch
        
        tStart = GetSecs;
        
        %DEBUG
%         DrawFormattedText(window, sprintf('%d: Catch', trial),...
%             'center', 'center', black);
%         Screen('Flip', window);
        
        WaitSecs(3.500);
        
        Screen('Flip', window);
    end
    
    tEnd = GetSecs;
    rt = tEnd - tStart;
    
    respMat(1, trial) = typeNum;
    if (typeNum ~= 4 || typeNum ~= 5 || typeNum ~= 6)
        respMat(2, trial) = rt;
    end

    % breaktime
    if (trial == breakFirst || trial == breakSecond || trial == breakThird)
        for time = 1:baseSettings.breaktimeSecs
            leftSecs = baseSettings.breaktimeSecs - time + 1;
            DrawFormattedText(window, sprintf('Now in break time \n\n We will let you know the left time: %d', leftSecs),...
                'center', 'center', black);
            Screen('Flip', window);
            WaitSecs(1);
        end
    end
    
    vbl = Screen('Flip', window);
    WaitSecs(1.000);    
end
DrawFormattedText(window, 'Experiment Finished \n\n Press Any Key To Exit',...
    'center', 'center', black);
Screen('Flip', window);
KbStrokeWait;
sca;

respMat

save('res.mat','respMat');

end

function crossbar(windowPtr)
baseSettings = load('baseSettings.mat');
[width, height] = Screen('WindowSize', windowPtr);

offset = baseSettings.drawings.cross.offset;

Screen('DrawLine', windowPtr, 0,...
    width/2 - offset, height/2,...
    width/2 + offset, height/2, 5);
Screen('DrawLine', windowPtr, 0,...
    width/2, height/2 - offset,...
    width/2, height/2 + offset, 5);
end

function dot(windowPtr)
baseSettings = load('baseSettings.mat');
[width, height] = Screen('WindowSize', windowPtr);

size = baseSettings.drawings.dot.size;
black = BlackIndex(windowPtr);

Screen('DrawDots', windowPtr, [width/2 height/2], size, black);
end

function circle(windowPtr)
baseSettings = load('baseSettings.mat');
[width, height] = Screen('WindowSize', windowPtr);

radius = baseSettings.drawings.circle.radius;
black = BlackIndex(windowPtr);

Screen('FillOval', windowPtr, black,...
    [(width/2 - radius) (height/2 - radius) (width/2 + radius) (height/2 + radius)]);
end

function empty(~)
end

function beepMed()
Beeper('med', 0.4, 1);
end

function beepHigh()
Beeper('high', 0.4, 1)
end

%opens file and save info

% fid = fopen( [baseName '.txt'],'w') %opens files for writing
% fprintf(fid,'%1.2f %1.2f', rt, rand); %saves some date
% fclose(fid) %closes file

%opens file and reads data

% fid = fopen( [baseName '.txt'],'r+') %opens file for reading
% threshes = fscanf(fid,'%f') %reads the data into the variable threshes
% fclose(fid) %closes the file