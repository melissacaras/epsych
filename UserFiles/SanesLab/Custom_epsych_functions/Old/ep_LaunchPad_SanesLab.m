function varargout = ep_LaunchPad_SanesLab(varargin)
% ep_LaunchPad_SanesLab
%
% Buttons to launch the different GUIs associated with the ElectroPsych
% toolbox.
%
% Daniel.Stolzberg@gmail.com 2015

% Edit the above text to modify the response to help ep_LaunchPad_SanesLab

% Last Modified by GUIDE v2.5 16-Jun-2015 10:14:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ep_LaunchPad_SanesLab_OpeningFcn, ...
                   'gui_OutputFcn',  @ep_LaunchPad_SanesLab_OutputFcn, ...
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


% --- Executes just before ep_LaunchPad_SanesLab is made visible.
function ep_LaunchPad_SanesLab_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ep_LaunchPad_SanesLab wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ep_LaunchPad_SanesLab_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

