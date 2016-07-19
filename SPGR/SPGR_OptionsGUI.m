function varargout = SPGR_OptionsGUI(varargin)
% SPGR_OPTIONSGUI MATLAB code for SPGR_OptionsGUI.fig
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-Fran�ois Cabana, 2016
% ----------------------------------------------------------------------------------------------------
% If you use qMTLab in your work, please cite :

% Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S.,
% Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016),
% Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation,
% analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
% ----------------------------------------------------------------------------------------------------


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SPGR_OptionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @SPGR_OptionsGUI_OutputFcn, ...
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


% --- Executes just before SPGR_OptionsGUI is made visible.
function SPGR_OptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.root = fileparts(which(mfilename()));
handles.CellSelect = [];
handles.caller = [];            % Handle to caller GUI
if (~isempty(varargin))         % If called from GUI, set position to dock left
    handles.caller = varargin{1};
    CurrentPos = get(gcf, 'Position');
    CallerPos = get(handles.caller, 'Position');
    NewPos = [CallerPos(1)+CallerPos(3), CallerPos(2)+CallerPos(4)-CurrentPos(4), CurrentPos(3), CurrentPos(4)];
    set(gcf, 'Position', NewPos);
end
guidata(hObject, handles);

% LOAD DEFAULTS (if not called from app)
if (isempty(varargin))
    PathName = fullfile(handles.root,'Parameters');
    LoadDefaultOptions(PathName);
end

Sim    =  getappdata(0, 'Sim');
Prot   =  getappdata(0, 'Prot');
FitOpt =  getappdata(0, 'FitOpt');

set(handles.SimFileName,   'String', Sim.FileName);
set(handles.ProtFileName,  'String', Prot.FileName);
set(handles.FitOptFileName,'String', FitOpt.FileName);

SetSim(Sim,handles);
SetProt(Prot,handles);
SetFitOpt(FitOpt,handles);

setappdata(gcf, 'oldSim',    Sim);
setappdata(gcf, 'oldProt',   Prot);
setappdata(gcf, 'oldFitOpt', FitOpt);


function varargout = SPGR_OptionsGUI_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;




% #########################################################################
%                           SIMULATION PANEL
% #########################################################################

% SAVE
function SimSave_Callback(hObject, eventdata, handles)
Sim = GetSim(handles);
[FileName,PathName] = uiputfile(fullfile(handles.root,'Parameters','NewSim.mat'));
if PathName == 0, return; end
Sim.FileType = 'Sim';
Sim.FileName = FileName;
save(fullfile(PathName,FileName),'-struct','Sim');
setappdata(gcf,'oldSim',Sim);
set(handles.SimFileName,'String',FileName);

% LOAD
function SimLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile(handles.root,'Parameters','*.mat'));
if PathName == 0, return; end
Sim = load(fullfile(PathName,FileName));
if (~any(strcmp('FileType',fieldnames(Sim))) || ~strcmp(Sim.FileType,'Sim') )
    errordlg('Invalid simulation parameters file');
    return;
end
SetSim(Sim,handles);
setappdata(gcf,'oldSim',Sim);
set(handles.SimFileName,'String',FileName);

% RESET
function SimReset_Callback(hObject, eventdata, handles)
Sim = getappdata(gcf,'oldSim');
SetSim(Sim,handles);
set(handles.SimFileName,'String',Sim.FileName);

% DEFAULT
function SimDefault_Callback(hObject, eventdata, handles)
FileName = 'DefaultSim.mat';
Sim = load(fullfile(handles.root,'Parameters',FileName));
SetSim(Sim,handles);
setappdata(gcf,'oldSim', Sim);
set(handles.SimFileName,'String',FileName);

% GETSim Get Sim
function Sim = GetSim(handles)
data = get(handles.ParamTable,'Data');
Param.F = data(1);      Param.kf = data(2);     Param.kr = data(3);    
Param.R1f = data(4);    Param.R1r = data(5);    Param.T2f = data(6);
Param.T2r = data(7);    Param.M0f = data(8);    
Param.T1f = 1/(Param.R1f);      Param.T1r = 1/(Param.R1r);      
Param.R2f = 1/(Param.T2f);      Param.R2r = 1/(Param.T2r);     
Param.M0r = Param.F*Param.M0f;
LineShapes = cellstr(get(handles.LineShapePopUp,'String'));
Param.lineshape = LineShapes{get(handles.LineShapePopUp,'Value')};

Sim.Opt.AddNoise = get(handles.AddNoiseBox,'Value');
Sim.Opt.SNR = str2double(get(handles.SNR,'String'));
Sim.Opt.SScheck = get(handles.SSCheckBox,'Value');
Sim.Opt.SStol = str2double(get(handles.SStolValue,'String'));
Sim.Opt.Reset = get(handles.ResetBox,'Value');

Sim.Param = Param;
Sim.FileName = get(handles.SimFileName, 'String');
setappdata(0,'Sim', Sim);

% SETSim Set Sim
function SetSim(Sim,handles)
Param = Sim.Param;
data = [Param.F;   Param.kf;  Param.kr; Param.R1f; Param.R1r; ...
        Param.T2f; Param.T2r; Param.M0f];
set(handles.ParamTable, 'Data', data);

switch Param.lineshape
    case 'Gaussian'
        ii = 1;
    case 'Lorentzian'
        ii = 2;
    case 'SuperLorentzian'
        ii = 3;
end
set(handles.LineShapePopUp, 'Value', ii);

set(handles.AddNoiseBox,'Value', Sim.Opt.AddNoise);
set(handles.SNR,'String', Sim.Opt.SNR);
set(handles.SSCheckBox, 'Value', Sim.Opt.SScheck);
set(handles.SStolValue, 'String', Sim.Opt.SStol);
set(handles.ResetBox, 'Value', Sim.Opt.Reset);

set(handles.SimFileName, 'String', Sim.FileName);
setappdata(0,'Sim',Sim);


% ############################ PARAMETERS #################################
% ParamTable CellEdit
function ParamTable_CellEditCallback(hObject, eventdata, handles)
Sim = GetSim(handles);
if (eventdata.Indices(1) == 2)
    Sim.Param.kr = Sim.Param.kf / Sim.Param.F;
elseif (eventdata.Indices(1) == 3)
    Sim.Param.kf = Sim.Param.kr * Sim.Param.F;
end
set(handles.SimFileName,'String','unsaved');
Sim.FileName = 'unsaved';
SetSim(Sim, handles);

% LineShapePopUp
function LineShapePopUp_Callback(hObject, eventdata, handles)
Sim = GetSim(handles);
contents = cellstr(get(handles.LineShapePopUp,'String'));
Sim.Param.lineshape = contents{get(handles.LineShapePopUp,'Value')};
set(handles.SimFileName,'String','unsaved');
GetSim(handles);

function LineShapePopUp_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% ############################ SIM OPTIONS ###############################
% Sim.OptEditPanel
function SimOptEditPanel_SelectionChangeFcn(hObject, eventdata, handles)
set(handles.SimFileName,'String','unsaved');
GetSim(handles);

% AddNoiseBox
function AddNoiseBox_Callback(hObject, eventdata, handles)
set(handles.SimFileName,'String','unsaved');
GetSim(handles);

% SNR
function SNR_Callback(hObject, eventdata, handles)
set(handles.SimFileName,'String','unsaved');
GetSim(handles);

function SNR_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% STEADY STATE CHECK
function SSCheckBox_Callback(hObject, eventdata, handles)
set(handles.SimFileName,'String','unsaved');
GetSim(handles);

function SStolValue_Callback(hObject, eventdata, handles)
set(handles.SimFileName,'String','unsaved');
GetSim(handles);

function SStolValue_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% RESET M0
function ResetBox_Callback(hObject, eventdata, handles)
set(handles.SimFileName,'String','unsaved');
GetSim(handles);





% #########################################################################
%                           FIT OPTIONS PANEL
% #########################################################################

% SAVE
function FitOptSave_Callback(hObject, eventdata, handles)
FitOpt = GetFitOpt(handles);
[FileName,PathName] = uiputfile(fullfile(handles.root,'Parameters','NewFitOpt.mat'));
if PathName == 0, return; end
FitOpt.FileType = 'FitOpt';
FitOpt.FileName = FileName;
save(fullfile(PathName,FileName),'-struct','FitOpt');
setappdata(gcf,'oldFitOpt',FitOpt);
set(handles.FitOptFileName,'String',FileName);

% LOAD
function FitOptLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile(handles.root,'Parameters','*.mat'));
if PathName == 0, return; end
FitOpt = load(fullfile(PathName,FileName));

if (~any(strcmp('FileType',fieldnames(FitOpt))) || ~strcmp(FitOpt.FileType,'FitOpt') )
    errordlg('Invalid fit options file');
    return;
end
SetFitOpt(FitOpt,handles);
setappdata(gcf,'oldFitOpt',FitOpt);
set(handles.FitOptFileName,'String',FileName);

% RESET
function FitOptReset_Callback(hObject, eventdata, handles)
FitOpt = getappdata(gcf,'oldFitOpt');
SetFitOpt(FitOpt,handles);
set(handles.FitOptFileName,'String',FitOpt.FileName);

% DEFAULT
function FitOptDefault_Callback(hObject, eventdata, handles)
FileName = 'DefaultFitOpt.mat';
FitOpt = load(fullfile(handles.root,'Parameters',FileName));
SetFitOpt(FitOpt,handles);
setappdata(gcf,'oldFitOpt',FitOpt);
set(handles.FitOptFileName,'String',FileName);

% GETFITOPT Get Fit Option from table
function FitOpt = GetFitOpt(handles)
data = get(handles.FitOptTable,'Data'); % Get options
FitOpt.names = data(:,1)';
FitOpt.fx = cell2mat(data(:,2)');
FitOpt.st = cell2mat(data(:,3)');
FitOpt.lb = cell2mat(data(:,4)');
FitOpt.ub = cell2mat(data(:,5)');
FitOpt.R1reqR1f = get(handles.R1reqR1fBox, 'Value');
FitOpt.R1map = get(handles.R1mapBox, 'Value');
FitOpt.FixR1fT2f = get(handles.FixR1fT2fBox, 'Value');
FitOpt.FixR1fT2fValue = str2double(get(handles.FixR1fT2fValue, 'String'));
LineShapes = cellstr(get(handles.FitLineShape,'String'));
FitOpt.lineshape = LineShapes{get(handles.FitLineShape,'Value')};

Models = cellstr(get(handles.FitModel,'String'));
FitOpt.model = Models{get(handles.FitModel,'Value')};
FitOpt.FileName = get(handles.FitOptFileName, 'String');
setappdata(0,'FitOpt',FitOpt);

% SETFITOPT Set Fit Option table data
function SetFitOpt(FitOpt,handles)
handles.FitOpt = FitOpt;
data = [FitOpt.names', num2cell(logical(FitOpt.fx')), num2cell(FitOpt.st'),...
                        num2cell(FitOpt.lb'), num2cell(FitOpt.ub')];
set(handles.FitOptTable,    'Data',     data);
set(handles.R1reqR1fBox,    'Value',    FitOpt.R1reqR1f);
set(handles.R1mapBox,       'Value',    FitOpt.R1map);
set(handles.FixR1fT2fBox,	'Value',    FitOpt.FixR1fT2f);
set(handles.FixR1fT2fValue, 'String',	FitOpt.FixR1fT2fValue);
guidata(gcf, handles);
switch FitOpt.lineshape
    case 'Gaussian'
        ii = 1;
    case 'Lorentzian'
        ii = 2;
    case 'SuperLorentzian'
        ii = 3;
end
set(handles.FitLineShape, 'Value', ii);
switch FitOpt.model
    case 'SledPikeRP'
        ii = 1;
    case 'SledPikeCW'
        ii = 2;
    case 'Yarnykh'
        ii = 3;
    case 'Ramani'
        ii = 4;
end
set(handles.FitModel, 'Value', ii);
switch FitOpt.model
    case {'Yarnykh', 'Ramani'}
        set(handles.FixR1fT2fValue,'Visible','on');
        set(handles.FixR1fT2fBox,'Visible','on');
    otherwise
        set(handles.FixR1fT2fValue,'Visible','off');
        set(handles.FixR1fT2fBox,'Visible','off');
end
setappdata(0,'FitOpt',FitOpt);

% FitOptTable CellEdit
function FitOptTable_CellEditCallback(hObject, eventdata, handles)
FitOpt = GetFitOpt(handles);
if (~FitOpt.fx(3))
    set(handles.R1mapBox,'Value',0);
    FitOpt.R1map = false;
end
if (~FitOpt.fx(4))
    set(handles.R1reqR1fBox,'Value',0);
    FitOpt.R1reqR1f = false;
end
set(handles.FitOptFileName,'String','unsaved');
SetFitOpt(FitOpt,handles);

% R1reqR1fBox
function R1reqR1fBox_Callback(hObject, eventdata, handles)
if (get(hObject, 'Value'))
    data = get(handles.FitOptTable,'Data');
    data(4,2) =  num2cell(true);
    set(handles.FitOptTable,'Data', data)
end
set(handles.FitOptFileName,'String','unsaved');
GetFitOpt(handles);

% R1mapBox
function R1mapBox_Callback(hObject, eventdata, handles)
if (get(hObject, 'Value'))
    data = get(handles.FitOptTable,'Data');
    data(3,2) =  num2cell(true);
    set(handles.FitOptTable,'Data', data)
end
set(handles.FitOptFileName,'String','unsaved');
GetFitOpt(handles);

% FIT LINESHAPE
function FitLineShape_Callback(hObject, eventdata, handles)
GetFitOpt(handles);

function FitLineShape_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% FIX R1F*T2f
function FixR1fT2fBox_Callback(hObject, eventdata, handles)
set(handles.FitOptFileName,'String','unsaved');
GetFitOpt(handles);

function FixR1fT2fValue_Callback(hObject, eventdata, handles)
set(handles.FitOptFileName,'String','unsaved');
GetFitOpt(handles);

function FixR1fT2fValue_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% FIT MODEL
function FitModel_Callback(hObject, eventdata, handles)
set(handles.FitOptFileName,'String','unsaved');
FitOpt = GetFitOpt(handles);
SetFitOpt(FitOpt,handles);
        

function FitModel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





% #########################################################################
%                           PROTOCOL PANEL
% #########################################################################

% SAVE
function ProtSave_Callback(hObject, eventdata, handles)
Prot = GetProt(handles);
[FileName,PathName] = uiputfile(fullfile(handles.root,'Parameters','NewProtocol.mat'));
if PathName == 0, return; end
Prot.FileType = 'Protocol';
Prot.Method = 'SPGR';
Prot.FileName = FileName;
save(fullfile(PathName,FileName),'-struct','Prot');
setappdata(gcf,'oldProt',Prot);
set(handles.ProtFileName,'String',FileName);

% LOAD
function ProtLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile(handles.root,'Parameters','*.mat'));
if PathName == 0, return; end
Prot = load(fullfile(PathName,FileName));
if (~any(strcmp('FileType',fieldnames(Prot))) || ~strcmp(Prot.FileType,'Protocol') )
    errordlg('Invalid protocol file');
    return;
end
SetProt(Prot,handles);
setappdata(gcf,'oldProt',Prot);
set(handles.ProtFileName,'String',FileName);

% RESET
function ProtReset_Callback(hObject, eventdata, handles)
Prot = getappdata(gcf,'oldProt');
SetProt(Prot,handles);
set(handles.ProtFileName,'String',Prot.FileName);

% DEFAULT
function ProtDefault_Callback(hObject, eventdata, handles)
FileName = 'DefaultProt.mat';
Prot = load(fullfile(handles.root,'Parameters',FileName));
SetProt(Prot,handles);
setappdata(gcf,'oldProt', Prot);
set(handles.ProtFileName,'String',FileName);

% GETPROT Get Protocol
function Prot = GetProt(handles)
Seq = get(handles.SeqTable, 'Data');
Prot.Angles = Seq(:,1);
Prot.Offsets = Seq(:,2);

SeqOpt = get(handles.SeqOptTable,'Data');
Prot.Tm = SeqOpt(1);
Prot.Ts = SeqOpt(2);
Prot.Tp = SeqOpt(3);
Prot.Tr = SeqOpt(4);
Prot.TR = SeqOpt(5);

Prot.Alpha  = str2double(get(handles.ReadPulseAlpha, 'String'));
Prot.Npulse = str2double(get(handles.NpulseValue,    'String'));
content = cellstr(get(handles.MTPulseShapePopUp,'String'));
Prot.MTpulse.shape = content{get(handles.MTPulseShapePopUp,'Value')};
Prot.MTpulse.opt = struct;
    switch Prot.MTpulse.shape
        case 'fermi'
            Prot.MTpulse.opt.slope = str2double(get(handles.PulseOptSlope, 'string'));
            if (isnan(Prot.MTpulse.opt.slope)); Prot.MTpulse.opt.slope = []; end
        case {'sinc','sinchann'}
            Prot.MTpulse.opt.TBW   = str2double(get(handles.PulseOptTBW,   'string'));
            if (isnan(Prot.MTpulse.opt.TBW)); Prot.MTpulse.opt.TBW = []; end
        case {'gaussian','gausshann'}
            Prot.MTpulse.opt.bw    = str2double(get(handles.PulseOptBW,    'string'));
            if (isnan(Prot.MTpulse.opt.bw)); Prot.MTpulse.opt.bw = []; end
        case 'sincgauss'
            Prot.MTpulse.opt.TBW   = str2double(get(handles.PulseOptTBW,   'string'));
            Prot.MTpulse.opt.bw    = str2double(get(handles.PulseOptBW,    'string'));
            if (isnan(Prot.MTpulse.opt.TBW)); Prot.MTpulse.opt.TBW = []; end
            if (isnan(Prot.MTpulse.opt.bw)); Prot.MTpulse.opt.bw = []; end
    end
Prot.Sf = getappdata(0,'Sf');
Prot.FileName = get(handles.ProtFileName,'String');
setappdata(0,'Prot',Prot);

% SETPROT Set Protocol
function SetProt(Prot,handles)
angles = mat2str(unique(Prot.Angles)');
offsets = mat2str(unique(Prot.Offsets)');
set(handles.AngleBox, 'String', angles);
set(handles.DeltaBox, 'String', offsets);
set(handles.SeqTable, 'Data', [Prot.Angles, Prot.Offsets]);
if (isfield(Prot,'Sf'))
    setappdata(0,'Sf',Prot.Sf);
end
data = [Prot.Tm; Prot.Ts; Prot.Tp; Prot.Tr; Prot.TR];
set(handles.SeqOptTable,'Data',data);
set(handles.ReadPulseAlpha,'String', Prot.Alpha);
set(handles.NpulseValue, 'String', Prot.Npulse);

% MT pulse
switch Prot.MTpulse.shape
    case 'hard';      ii = 1;
    case 'gaussian';  ii = 2;
    case 'gausshann'; ii = 3;
    case 'sinc';      ii = 4;
    case 'sinchann';  ii = 5;
    case 'sincgauss'; ii = 6;
    case 'fermi';     ii = 7;
end
set(handles.MTPulseShapePopUp,'Value',ii);

if (~isfield(Prot.MTpulse,'opt')); Prot.MTpulse.opt = struct; end
if (~isfield(Prot.MTpulse.opt,'TBW')); Prot.MTpulse.opt.TBW = []; end
if (~isfield(Prot.MTpulse.opt,'bw')); Prot.MTpulse.opt.bw = []; end
if (~isfield(Prot.MTpulse.opt,'slope')); Prot.MTpulse.opt.slope = []; end

set(handles.PulseOptTBW,'string',Prot.MTpulse.opt.TBW);
set(handles.PulseOptBW,'string',Prot.MTpulse.opt.bw);
set(handles.PulseOptSlope,'string',Prot.MTpulse.opt.slope);
set(handles.ProtFileName, 'String', Prot.FileName);
setappdata(0,'Prot',Prot);


% COMPUTE SF TABLE
function ComputeSf_Callback(hObject, eventdata, handles)

button = questdlg('Compute Sf table using current protocol settings?','Build Sf table','Start','Cancel','Start');
if (~strcmp(button,'Start'))
    return;
end
Prot = GetProt(handles);
angles = unique(Prot.Angles);
SfAngles = zeros(length(angles)*3 +2,1);
SfAngles(1) = 0;
SfAngles(end) = max(angles)*1.5;
minScale = 0.75;
maxScale = 1.25;

ind = 3;
for i = 1:length(angles)
    SfAngles(ind) = angles(i);
    SfAngles(ind-1) = minScale*angles(i);
    SfAngles(ind+1) = maxScale*angles(i);
    ind = ind + 3;
end
SfAngles = unique(SfAngles);

% Extend offsets limits and add midpoints
offsets = unique(Prot.Offsets);
SfOffsets = zeros(length(offsets)*4 +2,1);
SfOffsets(1) = 100;
SfOffsets(end) = max(offsets) + 1000;
maxOff = 100;
offsets = [0; offsets];
ind = 4;
for i = 2:length(offsets)
    SfOffsets(ind-2) = 0.5*(offsets(i) + offsets(i-1));
    SfOffsets(ind-1) = offsets(i) - maxOff;
    SfOffsets(ind) = offsets(i);
    SfOffsets(ind+1) = offsets(i) + maxOff;
    ind = ind + 4;
end
SfOffsets = unique(SfOffsets);

% T2f = linspace(FitOpt.lb(5), FitOpt.ub(5), 20);
T2f = [0.0010 0.0050 0.0100 0.0150 0.0200 0.0250 0.0300 0.0350 0.0400 ...
       0.0450 0.0500 0.0550 0.0600 0.0650 0.0700 0.0750 0.0800 0.0850 ...
       0.0900 0.2500 0.5000 1.0000];
Trf = Prot.Tm;
shape = Prot.MTpulse.shape;
PulseOpt = Prot.MTpulse.opt;
Sf = BuildSfTable(SfAngles, SfOffsets, T2f, Trf, shape, PulseOpt);
setappdata(0,'Sf',Sf);
ProtSave_Callback(hObject, eventdata, handles)



% ######################### SEQUENCE ######################################
% ANGLES
function AngleBox_Callback(hObject, eventdata, handles)

function AngleBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% OFFSETS
function DeltaBox_Callback(hObject, eventdata, handles)

function DeltaBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% GENERATE SEQUENCE
function GenSeq_Callback(hObject, eventdata, handles)
Prot = GetProt(handles);
angles = get(handles.AngleBox,'String');
offsets = get(handles.DeltaBox,'String');
Angles = eval(angles);
Offsets = eval(offsets);
[Prot.Angles,Prot.Offsets] = SPGR_GetSeq( Angles, Offsets );
SetProt(Prot,handles);

% REMOVE POINT
function PointRem_Callback(hObject, eventdata, handles)
selected = handles.CellSelect;
data = get(handles.SeqTable,'Data');
nRows = size(data,1);
if (numel(selected)==0)
    data = data(1:nRows-1,:);
else
    data (selected(:,1), :) = [];
end
set(handles.SeqTable,'Data',data);
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

% ADD POINT
function PointAdd_Callback(hObject, eventdata, handles)
selected = handles.CellSelect;
oldDat = get(handles.SeqTable,'Data');
nRows = size(oldDat,1);
dat = zeros(nRows+1,2);
if (numel(selected)==0)
    dat(1:nRows,:) = oldDat;
else
    dat(1:selected(1),:) = oldDat(1:selected(1),:);
    dat(selected(1)+2:end,:) = oldDat(selected(1)+1:end,:);
end
set(handles.SeqTable,'Data',dat);
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

% MOVE POINT UP
function PointUp_Callback(hObject, eventdata, handles)
selected = handles.CellSelect;
dat = get(handles.SeqTable,'Data');
oldDat = dat;
if (numel(selected)==0)
    return;
else
    dat(selected(1)-1,:) = oldDat(selected(1),:);
    dat(selected(1),:) = oldDat(selected(1)-1,:);
end
set(handles.SeqTable,'Data',dat);
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

% MOVE POINT DOWN
function PointDown_Callback(hObject, eventdata, handles)
selected = handles.CellSelect;
dat = get(handles.SeqTable,'Data');
oldDat = dat;
if (numel(selected)==0)
    return;
else
    dat(selected(1)+1,:) = oldDat(selected(1),:);
    dat(selected(1),:) = oldDat(selected(1)+1,:);
end
set(handles.SeqTable,'Data',dat);
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

% CELL SELECT
function SeqTable_CellSelectionCallback(hObject, eventdata, handles)
handles.CellSelect = eventdata.Indices;
guidata(hObject,handles);

% CELL EDIT
function SeqTable_CellEditCallback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);


% ######################  SEQUENCE OPTIONS #################################
% SeqOptTable
function SeqOptTable_CellEditCallback(hObject, eventdata, handles)
data = get(hObject,'Data');
if (eventdata.Indices(1) == 5)
    data(4) = data(5) - sum(data(1:3,1));
else
    data(5) = sum(data(1:4,1));
end
set(hObject,'Data',data);
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);


% MT PULSESHAPE
function MTPulseShapePopUp_Callback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

function MTPulseShapePopUp_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% PULSE OPTIONS
function PulseOptTBW_Callback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

function PulseOptTBW_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function PulseOptBW_Callback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

function PulseOptBW_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function PulseOptSlope_Callback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

function PulseOptSlope_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% VIEW PULSE
function ViewMTpulse_Callback(hObject, eventdata, handles)
Prot = GetProt(handles);
angles = Prot.Angles(1);
offsets = Prot.Offsets(1);
shape = Prot.MTpulse.shape;
Trf = Prot.Tm;
PulseOpt = Prot.MTpulse.opt;
Pulse = GetPulse(angles, offsets, Trf, shape, PulseOpt);
figure();
ViewPulse(Pulse,'b1');

% NPULSE
function NpulseValue_Callback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

function NpulseValue_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% READ PULSE ALPHA
function ReadPulseAlpha_Callback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

function ReadPulseAlpha_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% SeqOpt Table CellSelect
function SeqOptTable_CellSelectionCallback(hObject, eventdata, handles)
handles.CellSelect = eventdata.Indices;
guidata(hObject,handles);
