function varargout = Appetitive_training(varargin)
%
%Appetitive_training({'C:\Users\...*.rcx'},{'Title String'})
%
%This GUI allows a user to hand-train an animal to associate a sound
%with a water reward.  Pure tones and broadband noise are both supported.
%Input 1: 1x1 cell array containing the filename of an RPVds circuit
%Input 2: 1x1 cell array containing the text for the title of the GUI
%
%See Appetitive_Training_Menu.m for more detailed information.
%
%Written by ML Caras Jun 18 2015


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Appetitive_training_OpeningFcn, ...
                   'gui_OutputFcn',  @Appetitive_training_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%Executes just before GUI is made visible
function Appetitive_training_OpeningFcn(hObject, ~, handles, varargin)
global PERSIST

handles.output = hObject;

%Initialize RPVds circuit and title text
if nargin > 3
    handles.RPfile = varargin{1}{1};
    set(handles.title_text,'String',varargin{2}{1});
else
    error('Error: Incorrect or not enough input arguments')
end

%Load in speaker calibration file
[fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select speaker calibration file');
calfile = fullfile(pn,fn);


if ~fidx
    error('Error: No calibration file was found')
else
    handles.C = load(calfile,'-mat');
    calfiletype_tone = strfind(func2str(handles.C.hdr.calfunc),'Tone');
    
end

%Are we running a nosie training paradigm?
[st,i] = dbstack;
stcell = struct2cell(st);
nameind = ~cellfun('isempty',strfind(fieldnames(st),'name'));
noise_called = cell2mat(strfind(stcell(nameind,:),'noise'));

%Noise training
if ~isempty(noise_called)
    set(handles.freq,'enable','off')
    handles.freq_flag = 0;
    
    %We want noise calibration file
    if ~isempty(calfiletype_tone)
        error('Error: Incorrect calibration file loaded')
    end
%Tone training    
elseif isempty(noise_called)
    
    %We want tone calibration file
    if isempty(calfiletype_tone)
        error('Error: Incorrect calibration file loaded')
    end
    handles.freq_flag = 1;
    
end


%Open a figure for ActiveX control
handles.f1 = figure('Visible','off','Name','RPfig');

%Connect to the first module of the RZ6 ('GB' = optical gigabit connector)
handles.RP = actxcontrol('RPco.x','parent',handles.f1);

if handles.RP.ConnectRZ6('GB',1);
    disp 'Connected to RZ6'
else
    error('Error: Unable to connect to RZ6')
end

%Load the RPVds file (*.rco or *.rcx)
if handles.RP.LoadCOF(handles.RPfile);
    disp 'Circuit loaded successfully';
else
    error('Error: Unable to load RPVds circuit')
end

%Disable apply and stop button button
set(handles.apply,'enable','off');
set(handles.stop,'enable','off');

PERSIST = 0;

guidata(hObject, handles);

%Ouputs from this function are returned to the command line
function varargout = Appetitive_training_OutputFcn(hObject, ~, handles) 


% Get default command line output from handles structure
varargout{1} = handles.output;
guidata(hObject,handles);


%-------------------------------------------------------------
%%%%%%%%%%%  BUTTON AND SOUND CONTROLS %%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------

%START BUTTON CALLBACK
function start_Callback(hObject, ~, handles)

%Start the processing chain
if handles.RP.Run;
    disp 'Circuit is running'
else
    error('Error: circuit will not run')
end

%Initialize Pump
handles.pump = TrialFcn_PumpControl;

%Apply default settings to circuit and pump
apply_Callback(handles.apply,'', handles)

%Inactivate START button
set(handles.start,'BackgroundColor',[0.9 0.9 0.9])
set(handles.start,'ForegroundColor',[0.8 0.8 0.8])
set(handles.start,'Enable','off');

%Set dropdown menu colors to blue and disable apply button
set(handles.dBSPL,'ForegroundColor',[0 0 1]);
set(handles.freq,'ForegroundColor',[0 0 1]);
set(handles.pumprate,'ForegroundColor',[0 0 1]);
set(handles.apply,'enable','off');

%Start Timer
handles.timer = CreateTimer(handles);
start(handles.timer);

%Activate STOP button
set(handles.stop,'enable','on');


guidata(hObject,handles);


%STOP BUTTON CALLBACK
function stop_Callback(hObject, ~, handles)

stop(handles.timer);
delete(handles.timer);

%Stop the RPVds processing chain, and clear everything out
handles.RP.Halt;
handles.RP.ClearCOF;
release(handles.RP);

%Close the activeX controller window
close(handles.f1);

%Close out the pump
fclose(handles.pump); 
delete(handles.pump);

%Inactivate STOP AND APPLY buttons
set(handles.stop,'BackgroundColor',[0.9 0.9 0.9])
set(handles.stop,'ForegroundColor',[0.8 0.8 0.8])
set(handles.stop,'Enable','off');

set(handles.apply,'BackgroundColor',[0.9 0.9 0.9])
set(handles.apply,'ForegroundColor',[0.8 0.8 0.8])
set(handles.apply,'Enable','off');

guidata(hObject,handles)


%APPLY BUTTON CALLBACK
function apply_Callback(hObject, ~, handles)

%If frequency is an option
if handles.freq_flag == 1
    %Get frequency from GUI and send back to RPVds circuit
    freq = getval(handles.freq);
    handles.RP.SetTagVal('Freq',freq);
    CalAmp = Calibrate(freq,handles.C);
    
else
    CalAmp = handles.C.data(1,4);
end


if isfield(handles,'RP') && isfield(handles,'pump')
    %Set the voltage adjustment for calibration in RPVds circuit
    handles.RP.SetTagVal('~Freq_Amp',CalAmp);
    
    %Set the dB SPL value in RPVds circuit
    level = getval(handles.dBSPL);
    handles.RP.SetTagVal('dBSPL',level);
    
    %Send flowrate to pump
    rate = getval(handles.pumprate);
    fprintf(handles.pump,'RAT%0.1f\n',rate);
    %flushinput(handles.pump);flushoutput(handles.pump);
    %fprintf(handles.pump,'RAT');fscanf(handles.pump)
end

%Disable apply button
set(hObject,'enable','off')

%Set the dropdown menu colors to blue
set(handles.freq,'ForegroundColor',[0 0 1]);
set(handles.dBSPL,'ForegroundColor',[0 0 1]);
set(handles.pumprate,'ForegroundColor',[0 0 1]);


guidata(hObject,handles);




%-------------------------------------------------------------
%%%%%%%%%%%  TIMER CONTROLS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------
%CREATE TIMER FUNCTION
function T = CreateTimer(handles)

% Creates new timer for RPvds control of experiment
T = timerfindall;
while ~isempty(T)
    stop(T);
    delete(T);
    T = timerfindall;
end


%Sampling frequency of timer
handles.fs = 0.010;

%All values in seconds
T = timer('BusyMode','drop', ...
    'ExecutionMode','fixedSpacing', ...
    'Period',handles.fs, ...
    'Name','Training_Timer',...
    'StartFcn',{@Timer_start},...
    'StopFcn',{@Timer_stop},...
    'TimerFcn',{@Timer_callback,handles}, ...
    'TasksToExecute',inf); 

%TIMER START FUNCTION
function Timer_start(~,~)

%TIMER STOP FUNCTION
function Timer_stop(~,~)

%TIMER RUN FUNCTION
function Timer_callback(~,event,handles)
global PERSIST
persistent starttime timestamps spout_hist sound_hist water_hist

%If this is a new launch, clear persistent variables
if PERSIST == 0;
    starttime = event.Data.time;
    timestamps = [];
    spout_hist = [];
    sound_hist = [];
    water_hist = [];
    
    PERSIST = 1;
end
    

% %Determine start time
% if isempty(starttime)
%     starttime = event.Data.time;
% end

%Determine current time
currenttime = etime(event.Data.time,starttime);

%Update timetamp
timestamps = [timestamps;currenttime];

%Update Spout History
spout_TTL = handles.RP.GetTagVal('Spout');
spout_hist = [spout_hist;spout_TTL];

%Update Water History
water_TTL = handles.RP.GetTagVal('Water');
water_hist = [water_hist; water_TTL];

%Update Sound history
sound_TTL = handles.RP.GetTagVal('Sound');
sound_hist = [sound_hist;sound_TTL];

%Limit matrix size
xmin = timestamps(end)- 10;
xmax = timestamps(end)+ 10;
ind = find(timestamps > xmin+1 & timestamps < xmax-1);

timestamps = timestamps(ind);
spout_hist = spout_hist(ind);
water_hist = water_hist(ind);
sound_hist = sound_hist(ind);


plotRealTime(timestamps,sound_hist,handles.soundAx,'r',xmin,xmax)
plotRealTime(timestamps,spout_hist,handles.spoutAx,'k',xmin,xmax)
plotRealTime(timestamps,water_hist,handles.waterAx,'b',xmin,xmax,'Time (sec)')


%-------------------------------------------------------------
%%%%%%%%%%%  PLOTTING CONTROLS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------

%PLOT REALTIME TTLS
function plotRealTime(timestamps,TTL,ax,clr,xmin,xmax,varargin)

ind = logical(TTL);
xvals = timestamps(ind);
yvals = ones(size(xvals));

cla(ax);

if ~isempty(xvals)
    plot(ax,xvals,yvals,'s','color',clr,'linewidth',8)
end

%Format plot
set(ax,'ylim',[0.5 1.5]);
set(ax,'xlim',[xmin xmax]);
set(ax,'YTickLabel','');
set(ax,'XGrid','on');
set(ax,'XMinorGrid','on');

if nargin == 7
    xlabel(ax,varargin{1},'Fontname','Arial','FontSize',12)
else
    set(ax,'XTickLabel','');
end

 
%-------------------------------------------------------------
%%%%%%%%%%% CALLBACK AND OTHER FUNCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------

%DROPDOWN CHANGE SELECTION
function Change_Selection_Callback(hObject, ~, handles)
set(hObject,'ForegroundColor','r');
set(handles.apply,'enable','on');

guidata(hObject,handles)


%GET VALUE FUNCTION
function val = getval(h)
 str = get(h,'String');
 val = get(h,'Value');
 val = str2double(str{val});
    


%CLOSE FUNCTION
function figure1_CloseRequestFcn(hObject, ~, handles)
T = timerfind;

%If the timer is still running, confirm with user that you want the
%experiment to end
if ~isempty(T)
    question = 'Are you sure you want to end the experiment?';
    choice = questdlg(question,'End Experiment','Yes','No','No');
    
    switch choice
        case 'Yes'
            
            %Stop experiment
            stop_Callback(handles.stop, [], handles)
            
            %Delete figure
            delete(hObject);
    end
    
%If the timer is not running   
else
    delete(hObject);
    clc;
    
end
 


