function varargout = qMRLab(varargin)
% qmrlab MATLAB code for qMRLab.fig
% GUI to simulate/fit qMRI data

% ----------------------------------------------------------------------------------------------------
% Written by: Jean-Fran�is Cabana, 2016
%
% -- MTSAT functionality: P. Beliveau, 2017
% -- File Browser changes: P. Beliveau 2017
% ----------------------------------------------------------------------------------------------------
% If you use qMRLab in your work, please cite :

% Cabana, JF. et al (2016).
% Quantitative magnetization transfer imaging made easy with qMRLab
% Software for data simulation, analysis and visualization.
% Concepts in Magnetic Resonance Part A
% ----------------------------------------------------------------------------------------------------

if logical(exist('OCTAVE_VERSION', 'builtin')), warndlg('Graphical user interface not available on octave... use command lines instead'); return; end

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name', mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @qMRLab_OpeningFcn, ...
    'gui_OutputFcn',  @qMRLab_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    varargin{end+1}='wait';
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before qMRLab is made visible.
function qMRLab_OpeningFcn(hObject, eventdata, handles, varargin)
if max(strcmp(varargin,'wait')), wait=true; varargin(strcmp(varargin,'wait'))=[]; else wait=false; end
if ~isfield(handles,'opened') % qMRI already opened?
    % Add qMRLab to path
    qMRLabDir = fileparts(which(mfilename()));
    addpath(genpath(qMRLabDir));

    handles.opened = 1;
    clc;
    % startup;
    qMRLabDir = fileparts(which(mfilename()));
    addpath(genpath(qMRLabDir));
    handles.root = qMRLabDir;
    handles.methodfiles = '';
    handles.CurrentData = [];
    handles.FitDataDim = [];
    handles.FitDataSize = [];
    handles.FitDataSlice = [];
    handles.dcm_obj = [];
    MethodList = {}; SetAppData(MethodList);
    guidata(hObject, handles);
        
    
    % SET WINDOW AND PANELS
    movegui(gcf,'center')
    CurrentPos = get(gcf, 'Position');
    NewPos     = CurrentPos;
    NewPos(1)  = CurrentPos(1) - 40;
    set(gcf, 'Position', NewPos);
    if ispc , set(findobj(handles.FitResultsPlotPanel,'Type','uicontrol'),'FontSize',7); end % everything is bigger on windows or linux
    
    % Fill Menu with models
    handles.ModelDir = [qMRLabDir filesep 'src/Models'];
    guidata(hObject, handles);
    addModelMenu(hObject, eventdata, handles);
    
    % Fill FileBrowser with buttons
    MethodList = getappdata(0, 'MethodList');
    MethodList = strrep(MethodList, '.m', '');
    flist = findall(0,'type','figure');
    for iMethod=1:length(MethodList)
        
        Modelfun = str2func(MethodList{iMethod});
        Model = Modelfun();
        close(setdiff(findall(0,'type','figure'),flist)); % close figures that might open when calling models
        % create file browser uicontrol with specific inputs
        FileBrowserList(iMethod) = MethodBrowser(handles.FitDataFileBrowserPanel,Model);
        FileBrowserList(iMethod).Visible('off');
        
    end
    
    
    SetAppData(FileBrowserList);
    
    load(fullfile(handles.root,'src','Common','Parameters','DefaultMethod.mat'));
else
    Method = class(GetAppData('Model'));
end
% LOAD INPUT
if ~isempty(varargin)
    Model = varargin{1};
    SetAppData(Model);
    Method = class(Model);
    FileBrowserList = GetAppData('FileBrowserList');
    if length(varargin)>1
        data=varargin{2};
        for ff=fieldnames(data)'
            FileBrowserList(strcmp({FileBrowserList.MethodID},Method)).setFileName(ff{1}, data.(ff{1}))
        end
    end
end

% Set Menu to method
methods = sct_tools_ls([handles.ModelDir filesep '*.m'], 0,0,2,1);
i = 1;
while ~strcmp(Method, methods{i})
    i = i+1;
end
set(handles.MethodSelection, 'Value', i);


MethodMenu(hObject, eventdata, handles, Method);
if wait
uiwait(hObject)
end



% View first file
if length(varargin)>1
    butobj = FileBrowserList(strcmp({FileBrowserList.MethodID},Method)).ItemsList(1);	
    butobj.ViewBtn_callback(butobj,[],[],handles)
end


% Outputs from this function are returned to the command line.
function varargout = qMRLab_OutputFcn(hObject, eventdata, handles)
if nargout
    varargout{1} = GetAppData('Model');
    AppData = getappdata(0);
    Fields = fieldnames(AppData);
    for k=1:length(Fields)
        rmappdata(0, Fields{k});
    end
end


% Executes when user attempts to close qMRLab.
function qMRLab_CloseRequestFcn(hObject, eventdata, handles)
if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(hObject);
else
    AppData = getappdata(0);
    Fields = fieldnames(AppData);
    for k=1:length(Fields)
        rmappdata(0, Fields{k});
    end
end
% The GUI is no longer waiting, just close it
delete(hObject);
h = findobj('Tag','OptionsGUI');
delete(findobj('Tag','Simu'))
delete(h);
wh=findall(0,'tag','TMWWaitbar');
delete(wh);


% cd(handles.root);

function MethodSelection_Callback(hObject, eventdata, handles)
Method = GetMethod(handles);
MethodMenu(hObject,eventdata,handles,Method);

function addModelMenu(hObject, eventdata, handles)
% Display all the options in the popupmenu
[MethodList, pathmodels] = sct_tools_ls([handles.ModelDir filesep '*.m'],0,0,2,1);
pathmodels = cellfun(@(x) strrep(x,[handles.ModelDir filesep],''), pathmodels,'UniformOutput',false);
SetAppData(MethodList)
maxlength = max(cellfun(@length,MethodList))+4;
maxlengthpath = max(cellfun(@length,pathmodels))+2;
for iM=1:length(MethodList), MethodListfull{iM} = sprintf(['%-' num2str(maxlength) 's%-' num2str(maxlengthpath) 's'],MethodList{iM},['(' strrep(pathmodels{iM},[handles.ModelDir filesep],'') ')']); end
set(handles.MethodSelection,'String',MethodListfull);
set(handles.MethodSelection,'FontName','FixedWidth')
set(handles.MethodSelection,'FontWeight','bold')
set(handles.MethodSelection,'FontUnits','normalized')
set(handles.MethodSelection,'FontSize',.5)


%###########################################################################################
%                                 COMMON FUNCTIONS
%###########################################################################################

% METHODSELECTION
function MethodMenu(hObject, eventdata, handles, Method)

SetAppData(Method)

% Start by updating the Model object
if isappdata(0,'Model') && strcmp(class(getappdata(0,'Model')),Method) % if same method, load the current class with parameters
    Model = getappdata(0,'Model');
else % otherwise create a new object of this method
    modelfun  = str2func(Method);
    Model = modelfun();
end
SetAppData(Model)
% Create empty Data
Data = GetAppData('Data');
for id=1:length(Model.MRIinputs)
    if isempty(Data) || ~isfield(Data,Method) || ~isfield(Data.(Method),Model.MRIinputs{id})
        Data.(Method).(Model.MRIinputs{id})=[];
    end
end
SetAppData(Data);

% Now create Simulation panel
handles.methodfiles = fullfile(handles.root,'src','Models_Functions',[Method 'fun']);
% find the Simulation functions of the selected Method
Methodfun = methods(Method);
Simfun = Methodfun(~cellfun(@isempty,strfind(Methodfun,'Sim_')));
% Update Options Panel
set(handles.SimPanel,'Visible','off') % hide the simulation panel for qMT methods
if isempty(Simfun)
    set(handles.SimPanel,'Visible','off') % hide the simulation panel
else
    set(handles.SimPanel,'Visible','on') % show the simulation panel
    delete(setdiff(findobj(handles.SimPanel),handles.SimPanel))
    
    N = length(Simfun); %
    Jh = min(0.14,.8/N);
    J=1:max(N,6); J=(J-1)/max(N,6)*0.85; J=1-J-Jh-.01;
    for i = 1:N
        if exist([Simfun{i} '_GUI'],'file')
            uicontrol('Style','pushbutton','String',strrep(strrep(Simfun{i},'Sim_',''),'_',' '),...
                'Parent',handles.SimPanel,'Units','normalized','Position',[.04 J(i) .92 Jh],...
                'HorizontalAlignment','center','FontWeight','bold','Callback',...
                @(x,y) SimfunGUI([Simfun{i} '_GUI']));
        end
    end
    
end


% Update Options Panel
h = findobj('Tag','OptionsGUI');
if ~isempty(h)
    delete(h);
end
OpenOptionsPanel_Callback(hObject, eventdata, handles)

% Show FileBrowser
FileBrowserList = GetAppData('FileBrowserList');
MethodNum = find(strcmp({FileBrowserList.MethodID},Method));
for i=1:length(FileBrowserList)
    FileBrowserList(i).Visible('off');
end
FileBrowserList(MethodNum).Visible('on');

% enable/disable viewdatafit
if Model.voxelwise
set(handles.ViewDataFit,'Enable','on')
set(handles.ViewDataFit,'TooltipString','View fit in a particular voxel')
else
set(handles.ViewDataFit,'Enable','off')
set(handles.ViewDataFit,'TooltipString','No voxel-wise fitting for this qMR Method (Volume based method)')
end
guidata(hObject, handles);

function SimfunGUI(functionName)
Model = getappdata(0,'Model');
SimfunGUI = str2func(functionName);
SimfunGUI(Model);


function MethodSelection_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% SET DEFAULT METHODSELECTION
function DefaultMethodBtn_Callback(hObject, eventdata, handles)
Method = GetMethod(handles);
setappdata(0, 'Method', Method);
save(fullfile(handles.root,'src','Common','Parameters','DefaultMethod.mat'),'Method');

function PanelOn(panel, handles)
eval(sprintf('set(handles.%sPanel, ''Visible'', ''on'')', panel));

function PanelOff(panel, handles)
eval(sprintf('set(handles.%sPanel, ''Visible'', ''off'')', panel));

% OPEN OPTIONS
function OpenOptionsPanel_Callback(hObject, eventdata, handles)
Method = GetAppData('Method');
Model = getappdata(0,'Model');
Custom_OptionsGUI(Model, gcf);


% UPDATE OPTIONS
function UpdateOptions(Sim,Prot,FitOpt)
h = findobj('Tag','OptionsGUI');
if ~isempty(h)
    OptionsGUIhandles = guidata(h);
    set(OptionsGUIhandles.SimFileName,   'String',  Sim.FileName);
    set(OptionsGUIhandles.ProtFileName,  'String',  Prot.FileName);
    set(OptionsGUIhandles.FitOptFileName,'String',  FitOpt.FileName);
end


% GETAPPDATA
function varargout = GetAppData(varargin)
for k=1:nargin; varargout{k} = getappdata(0, varargin{k}); end

%SETAPPDATA
function SetAppData(varargin)
for k=1:nargin; setappdata(0, inputname(k), varargin{k}); end

% RMAPPDATA
function RmAppData(varargin)
for k=1:nargin; rmappdata(0, varargin{k}); end

% ##############################################################################################
%                                    FIT DATA
% ##############################################################################################

% FITDATA GO
function FitGO_Callback(hObject, eventdata, handles)
Method = GetMethod(handles);
setappdata(0, 'Method', Method);
FitGo_FitData(hObject, eventdata, handles);


% Original FitGo function
function FitGo_FitData(hObject, eventdata, handles)

% Get data
data =  GetAppData('Data');
Method = GetAppData('Method');
Model = getappdata(0,'Model');
if isfield(data,[class(Model) '_hdr']), hdr = data.([class(Model) '_hdr']); end
data = data.(Method);

% check data
ErrMsg = Model.sanityCheck(data);
if ~isempty(ErrMsg), errordlg(ErrMsg,'Input error','modal'); return; end

% Do the fitting
FitResults = FitData(data,Model,1);

% Save info with results
FileBrowserList = GetAppData('FileBrowserList');
MethodList = getappdata(0, 'MethodList');
MethodList = strrep(MethodList, '.m', '');
MethodCount = numel(MethodList);

for i=1:MethodCount
    if FileBrowserList(i).IsMethodID(Method)
        MethodID = i;
    end
end
FitResults.StudyID = FileBrowserList(MethodID).getStudyID;
FitResults.WD = FileBrowserList(MethodID).getWD;
if isempty(FitResults.WD), FitResults.WD = pwd; end
FitResults.Files = FileBrowserList(MethodID).getFileName;
SetAppData(FitResults);

% Kill the waitbar in case of a problem occurred
wh=findall(0,'tag','TMWWaitbar');
delete(wh);

% convert Model to struct
FitResults.Model = objProps2struct(FitResults.Model);

% Save fit results
if(~isempty(FitResults.StudyID))
    filename = strcat('FitResults_',FitResults.StudyID,'.mat');
else
    filename = 'FitResults.mat';
end
outputdir = fullfile(FitResults.WD,['FitResults_', datestr(datetime('now','TimeZone','local'),'yyyy-mm-dd_HH-MM-SS')]); % ISO 8601 format adapted for MATLAB compatibility
if ~exist(outputdir,'dir'), mkdir(outputdir); 
else
    iii=1; outputdirnew = outputdir;
    while exist(outputdirnew,'dir')
        iii=iii+1;
        outputdirnew = [outputdir,'_' num2str(iii)];
    end
    outputdir = outputdirnew;
    mkdir(outputdir);
end
save(fullfile(outputdir,filename),'-struct','FitResults');
set(handles.CurrentFitId,'String','FitResults.mat');

% Save nii maps
for ii = 1:length(FitResults.fields)
    map = FitResults.fields{ii};
    file = strcat(map,'.nii.gz');

    if ~exist('hdr','var')
        save_nii(make_nii(FitResults.(map)),fullfile(outputdir,file));
    else
        save_nii_v2(FitResults.(map),fullfile(outputdir,file),hdr,64);
    end
end

SetAppData(FileBrowserList);
% Show results
handles.CurrentData = FitResults;
guidata(hObject,handles);
DrawPlot(handles);
set(handles.RoiAnalysis,'Enable','on');


% FITRESULTSSAVE
function FitResultsSave_Callback(hObject, eventdata, handles)
FitResults = GetAppData('FitResults');
[FileName,PathName] = uiputfile('*.mat');
if PathName == 0, return; end
save(fullfile(PathName,FileName),'-struct','FitResults');
set(handles.CurrentFitId,'String',FileName);


% FITRESULTSLOAD
function FitResultsLoad_Callback(hObject, eventdata, handles)

[FileName,PathName] = uigetfile({'*FitResults*.mat;*.qmrlab.mat;*.mat'},'FitResults.mat');
if PathName == 0, return; end
set(handles.CurrentFitId,'String',FileName);
FitResults = load(fullfile(PathName,FileName));
if isfield(FitResults,'Protocol')
    Prot   =  FitResults.Protocol;
else
    Prot   =  FitResults.Prot;
end
if isfield(FitResults,'FitOpt'), FitOpt =  FitResults.FitOpt; SetAppData(FitResults, Prot, FitOpt); Method = FitResults.Protocol.Method; end
if isfield(FitResults,'Model')
    Method = FitResults.Model.ModelName;
    Model = qMRloadObj(FitResults.Model);
    SetAppData(FitResults,Model);
end

% find model value in the method menu list
methods = sct_tools_ls([handles.ModelDir filesep '*.m'], 0,0,2,1);
val = find(strcmp(methods,Method));
set(handles.MethodSelection,'Value',val)

MethodMenu(hObject, eventdata, handles,Method)
handles = guidata(hObject); % update handle
FileBrowserList = GetAppData('FileBrowserList');
% if isfield(FitResults,'WD'), FileBrowserList.setWD(FitResults.WD); end
% if isfield(FitResults,'StudyID'), FileBrowserList.setStudyID(FitResults.StudyID); end
% if isfield(FitResults,'Files'),
%     for ifile = fieldnames(FitResults.Files)'
%         FileBrowserList.setFileName(ifile{1},FitResults.Files.(ifile{1}))
%     end
% end

SetAppData(FileBrowserList);
handles.CurrentData = FitResults;
guidata(hObject,handles);
DrawPlot(handles);
set(handles.RoiAnalysis,'Enable','on');


% #########################################################################
%                            PLOT DATA
% #########################################################################

function ColorMapStyle_Callback(hObject, eventdata, handles)
val  =  get(handles.ColorMapStyle, 'Value');
maps =  get(handles.ColorMapStyle, 'String');
colormap(maps{val});

function Auto_Callback(hObject, eventdata, handles)
GetPlotRange(handles);
RefreshPlot(handles);

% SOURCE
function SourcePop_Callback(hObject, eventdata, handles)
GetPlotRange(handles);
RefreshPlot(handles);

% MIN
function MinValue_Callback(hObject, eventdata, handles)
mini   =  str2double(get(hObject,'String'));
maxi = str2double(get(handles.MaxValue, 'String'));

lower =  mini - 0.25*abs(mini+maxi);
set(handles.MinSlider, 'Value', mini);
set(handles.MinSlider, 'min',   lower);
caxis([mini maxi]);
% RefreshColorMap(handles);


function MinSlider_Callback(hObject, eventdata, handles)
maxi = str2double(get(handles.MaxValue, 'String'));
mini = min(get(hObject, 'Value'),maxi-eps);
set(hObject,'Value',mini)
set(handles.MinValue,'String',mini);
caxis([mini maxi]);
% RefreshColorMap(handles);

% MAX
function MaxValue_Callback(hObject, eventdata, handles)
mini = str2double(get(handles.MinValue, 'String'));
maxi = str2double(get(handles.MaxValue, 'String'));
upper =  1.5 * maxi;
set(handles.MaxSlider, 'Value', maxi)
set(handles.MaxSlider, 'max',   upper);
caxis([mini maxi]);
% RefreshColorMap(handles);

function MaxSlider_Callback(hObject, eventdata, handles)
mini = str2double(get(handles.MinValue, 'String'));
maxi = max(mini +eps,get(hObject, 'Value'));
set(hObject,'Value',maxi)
set(handles.MaxValue,'String',maxi);
caxis([mini maxi]);
% RefreshColorMap(handles);

% VIEW
function ViewPop_Callback(hObject, eventdata, handles)
UpdatePopUp(handles);
RefreshPlot(handles);
xlim('auto');
ylim('auto');

% SLICE
function SliceValue_Callback(hObject, eventdata, handles)
Slice = str2double(get(hObject,'String'));
Slice = min(get(handles.SliceSlider,'Max'),Slice);
Slice = max(1,Slice);
set(hObject,'String',num2str(Slice));
set(handles.SliceSlider,'Value',Slice);
View =  get(handles.ViewPop,'Value');
handles.FitDataSlice(View) = Slice;
guidata(gcbf,handles);
RefreshPlot(handles);

function SliceSlider_Callback(hObject, eventdata, handles)
Slice = get(hObject,'Value');
Slice = max(1,round(Slice));
set(handles.SliceSlider, 'Value', Slice);
set(handles.SliceValue, 'String', Slice);
View =  get(handles.ViewPop,'Value');
handles.FitDataSlice(View) = Slice;
guidata(gcbf,handles);
RefreshPlot(handles);

function TimeValue_Callback(hObject, eventdata, handles)
Time = str2double(get(hObject,'String'));
Time = min(get(handles.TimeSlider,'Max'),Time);
Time = max(1,Time);
set(hObject,'String',num2str(Time));
set(handles.TimeSlider,'Value',Time);
RefreshPlot(handles);

function TimeSlider_Callback(hObject, eventdata, handles)
Time = get(hObject,'Value');
Time = max(1,round(Time));
set(handles.TimeSlider, 'Value', Time);
set(handles.TimeValue, 'String', Time);
RefreshPlot(handles);

% OPEN FIG
function PopFig_Callback(hObject, eventdata, handles)
xl = xlim;
yl = ylim;
figure();
xlim(xl);
ylim(yl);
RefreshPlot(handles);

% SAVE FIG
function SaveFig_Callback(hObject, eventdata, handles)
[FileName,PathName] = uiputfile(fullfile('.','NewFig.fig'));

if PathName == 0, return; end
xl = xlim;
yl = ylim;
h = figure();
xlim(xl);
ylim(yl);
RefreshPlot(handles);
savefig(fullfile(PathName,FileName));
delete(h);

% HISTOGRAM FIG
function Histogram_Callback(hObject, eventdata, handles)
Data =  getappdata(0,'Data');
Model = class(GetAppData('Model')); % Get cur model name (string)
Map = getimage(handles.FitDataAxe);

% Mask data
if isfield(Data.(Model),'Mask')
    if ~isempty(Data.(Model).Mask)
        Map(~rot90(Data.(Model).Mask)) = 0;
    end
end

ii = find(Map);
nVox = length(ii);
data = reshape(Map(ii),1,nVox);

% Plot figure
f=figure('Position', [0 0 700 400], 'Resize', 'Off');

% Matlab < R2014b
MatlabVer = version;
if str2double(MatlabVer(1))<8 || (str2double(MatlabVer(1))==8 && str2double(MatlabVer(3))<4)
defaultNumBins = max(5,round(length(data)/100));
hist(data, defaultNumBins); 
% Label axes
SourceFields = cellstr(get(handles.SourcePop,'String'));
Source = SourceFields{get(handles.SourcePop,'Value')};
xlabel(Source);
ylabel('Counts');
return;
end

% Matlab >= R2014b
h_plot = subplot(1,2,2); % Use subplot to give space for GUI elements
h_plot.OuterPosition = [0.3 0 0.7 1.0];

h_hist=histogram(data);
defaultNumBins = h_hist.NumBins;
% Label axes
SourceFields = cellstr(get(handles.SourcePop,'String'));
Source = SourceFields{get(handles.SourcePop,'Value')};
xlabel(Source);
h_ylabel = ylabel('Counts');

% Statistics (mean and standard deviation)
Stats = sprintf('Mean: %4.3g \n Median: %4.3g \n   Std: %4.3g',mean(data(~isinf(data) & ~isnan(data))),median(data(~isinf(data) & ~isnan(data))),std(data(~isinf(data) & ~isnan(data))));
h_stats=text(0.10,0.90,Stats,'Units','normalized','FontWeight','bold','FontSize',12,'Color','black');

% No. of bins GUI objects
h_text_bin = uicontrol(f,'Style','text',...
                     'String', 'Number of bins:',...
                     'FontSize', 14,...
                     'Position',[5 20+300 140 34]);
h_edit_bin = uicontrol(f,'Style','edit',...
                     'String', defaultNumBins,...
                     'FontSize', 14,...
                     'Position',[135 25+300 34 34]);
h_slider_bin = uicontrol(f,'Style','slider',...
                       'Min',1,'Max',100,'Value',defaultNumBins,...
                       'SliderStep',[1/(100-1) 1/(100-1)],...
                       'Position',[185 26+300 0 30],...
                       'Callback',{@sl_call,{h_hist h_edit_bin}});
h_edit_bin.Callback = {@ed_call,{h_hist h_slider_bin}};

% Min-Max GUI objects
h_text_min = uicontrol(f,'Style','text',...
                      'String', 'Min',...
                      'FontSize', 14,...
                      'Position',[0 20+200 140 34]);
h_edit_min = uicontrol(f,'Style','edit',...
                     'String', h_hist.BinLimits(1),...
                     'FontSize', 14,...
                     'Position', [35 20+180 70 34]);
h_text_max = uicontrol(f,'Style','text',...
                      'String', 'Max',...
                      'FontSize', 14,...
                      'Position',[135 20+200 34 34]);
h_edit_max = uicontrol(f,'Style','edit',...
                     'String', h_hist.BinLimits(2),...
                     'FontSize', 14,...
                     'Position', [116 20+180 70 34]);
h_button_minmax = uicontrol(f,'Style','pushbutton',...
                              'String', 'Recalculate',...
                              'FontSize', 14,...
                              'Position', [65 20+140 100 34],...
                              'Callback',{@minmax_call,{h_hist h_edit_min h_edit_max data h_stats}});

% Normalization GUI objects
h_text_min = uicontrol(f,'Style','text',...
                      'String', 'Normalization mode',...
                      'FontSize', 14,...
                      'Position',[30 20+40 180 34]);
h_popup_norm = uicontrol(f,'Style','popupmenu',...
                           'String', {'Count',...
                                      'Cumulative count',...
                                      'Probability',...
                                      'PDF',...
                                      'CDF'},...
                           'FontSize', 14,...
                           'Position', [30 20+20 180 34],...
                           'Callback',{@norm_call,{h_hist h_ylabel}});

% Histogram GUI callbacks
function [] = sl_call(varargin)
    % Callback for the histogram slider.
    [h_slider_bin,h_cell] = varargin{[1,3]};
    h_hist = h_cell{1};
    h_edit_bin = h_cell{2};

    h_hist.NumBins = round(h_slider_bin.Value);
    h_edit_bin.String = round(h_slider_bin.Value);

function [] = ed_call(varargin)
    % Callback for the histogram edit box.
    [h_edit_bin,h_cell] = varargin{[1,3]};
    h_hist = h_cell{1};
    h_slider_bin = h_cell{2};

    h_hist.NumBins = round(str2double(h_edit_bin.String));
    h_slider_bin.Value = round(str2double(h_edit_bin.String));

function [] = minmax_call(varargin)
    % Callback for the histogram bin bounds recalculate box.
    h_cell = varargin{3};
    h_hist = h_cell{1};
    h_min = h_cell{2};
    h_max = h_cell{3};
    data = h_cell{4};
    h_stats = h_cell{5};

    % Mask data out of range of min-max
    minVal = str2double(h_min.String);
    maxVal = str2double(h_max.String);
    data(data>maxVal) = [];
    data(data<minVal) = [];

    h_hist.Data=data;

    % Small hack to refresh histogram object/fig.
    numBins = h_hist.NumBins;
    if numBins == 100
        h_hist.NumBins = numBins-1;
        h_hist.NumBins = numBins;
    else
        h_hist.NumBins = numBins+1;
        h_hist.NumBins = numBins;
    end

    % Update stats on fig
    Stats = sprintf('Mean: %4.3g \n Median: %4.3g \n   Std: %4.3g',mean(data(~isinf(data) & ~isnan(data))),median(data(~isinf(data) & ~isnan(data))),std(data(~isinf(data) & ~isnan(data))));
    set(h_stats,'String',Stats);
    
function [] = norm_call(varargin)
    % Callback for the histogram edit box.
    [h_popup_norm,h_cell] = varargin{[1,3]};
    h_hist = h_cell{1};
    h_ylabel = h_cell{2};

    menu_status = h_popup_norm.String{h_popup_norm.Value};

    switch menu_status
        case 'Count'
            h_hist.Normalization = 'count';
        case 'Cumulative count'
            h_hist.Normalization = 'cumcount';
        case 'Probability'
            h_hist.Normalization = 'probability';
        case 'PDF'
            h_hist.Normalization = 'pdf';
        case 'CDF'
            h_hist.Normalization = 'cdf';
    end

    h_ylabel.String = menu_status;

% PLOT DATA FIT
function ViewDataFit_Callback(hObject, eventdata, handles)
% Get data
data =  getappdata(0,'Data'); data=data.(class(getappdata(0,'Model')));
Model = GetAppData('Model');

% Get selected voxel
S = [size(data.(Model.MRIinputs{1}),1) size(data.(Model.MRIinputs{1}),2) size(data.(Model.MRIinputs{1}),3)];
Data = handles.CurrentData;	
selected = get(handles.SourcePop,'Value');	
Scurrent = [size(Data.(Data.fields{selected}),1) size(Data.(Data.fields{selected}),2) size(Data.(Data.fields{selected}),3)];
if isempty(handles.dcm_obj) || isempty(getCursorInfo(handles.dcm_obj))
    helpdlg('Select a voxel in the image using cursor')
elseif sum(S)==0
    helpdlg(['Specify a ' Model.MRIinputs{1} ' file in the filebrowser'])

elseif ~isequal(Scurrent(1:3), S(1:3))
    Sstr = sprintf('%ix',S);
    Scurstr = sprintf('%ix',Scurrent);
    helpdlg([Model.MRIinputs{1} ' file (' Sstr(1:end-1) ') in the filebrowser is inconsistent with ' Data.fields{selected} ' in the viewer (' Scurstr(1:end-1) '). Load corresponding ' Model.MRIinputs{1} '.'])

else
    Model.sanityCheck(data);
    info_dcm = getCursorInfo(handles.dcm_obj);
    x = info_dcm.Position(1);
    y = 1 + size(info_dcm.Target.CData,1)-info_dcm.Position(2);
    z = str2double(get(handles.SliceValue,'String'));
    View =  get(handles.ViewPop,'String'); if ~iscell(View), View = {View}; end
    switch View{get(handles.ViewPop,'Value')}
        case 'Axial',    vox = [x,y,z]; 
        case 'Coronal',  vox = [x,z,y]; 
        case 'Sagittal', vox = [z,x,y]; 
    end
    
    
    for ii=1:length(Model.MRIinputs)
        if isfield(data,(Model.MRIinputs{ii})) && ~isempty(data.(Model.MRIinputs{ii}))
            data.(Model.MRIinputs{ii}) = squeeze(data.(Model.MRIinputs{ii})(vox(1),vox(2),vox(3),:));
        end
    end
    if isfield(data,'Mask'), data.Mask = []; end
    
    
    % Create axe
    figure(68)
    h = findobj(68,'Style','checkbox','String','hold plot in order to compare voxels');
    if isempty(h) || ~get(h,'Value')  % If a data fit check has already been run OR do not hold plot,
            clf(68)        % clear the previous data from the figure plot
            uicontrol('Style','checkbox','String','hold plot in order to compare voxels','Value',0,'Position',[0 0 210 20]);
    end 
                                  
    set(68,'Name',['Fitting results of voxel [' num2str([info_dcm.Position(1) info_dcm.Position(2) z]) ']'],'NumberTitle','off');
    haxes = get(68,'children'); haxes = haxes(strcmp(get(haxes,'Type'),'axes'));
    
    if ~isempty(haxes)
        % turn gray old plots
        for h=1:length(haxes) %might have subplots
            haxe = get(haxes(h),'children');
            set(haxe,'Color',[0.8 0.8 0.8]);
            hAnnotation = get(haxe,'Annotation');
            % remove their legends
            for ih=1:length(hAnnotation)
                if iscell(hAnnotation), hAnnot = hAnnotation{ih}; else hAnnot = hAnnotation; end
                hLegendEntry = get(hAnnot,'LegendInformation');
                set(hLegendEntry,'IconDisplayStyle','off');
            end
        end
    end
    hold on;
    
    % Do the fitting
    Model = getappdata(0,'Model');
    if Model.voxelwise==0,  warndlg('Not a voxelwise model'); return; end
    if ~ismethod(Model,'plotModel'), warndlg('No plotting methods in this model'); return; end
    Fit = Model.fit(data) % Display fitting results in command window
    Model.plotModel(Fit,data);
    
    % update legend
    legend('Location','NorthEast')
end


% OPEN VIEWER
function Viewer_Callback(hObject, eventdata, handles)
SourceFields = cellstr(get(handles.SourcePop,'String'));
Source = SourceFields{get(handles.SourcePop,'Value')};
file = fullfile(handles.root,strcat(Source,'.nii'));
if isempty(handles.CurrentData), return; end
Data = handles.CurrentData;
nii = make_nii(Data.(Source));
save_nii(nii,file);
nii_viewer(file);


% PAN
function PanBtn_Callback(hObject, eventdata, handles)
pan;
set(handles.ZoomBtn,'Value',0);
set(handles.CursorBtn,'Value',0);
zoom off;
datacursormode off;

% ZOOM
function ZoomBtn_Callback(hObject, eventdata, handles)
zoom;
set(handles.PanBtn,'Value',0);
set(handles.CursorBtn,'Value',0);
pan off;
datacursormode off;

% CURSOR
function CursorBtn_Callback(hObject, eventdata, handles)
datacursormode;
set(handles.ZoomBtn,'Value',0);
set(handles.PanBtn,'Value',0);
zoom off;
pan off;
fig = gcf;
handles.dcm_obj = datacursormode(fig);
guidata(gcbf,handles);

set(handles.dcm_obj,'UpdateFcn',{@dataCursorUpdateFcn,handles})

function txt = dataCursorUpdateFcn(h_PointDataTip,event_obj,handles)
% Customizes text of data tips

pos = get(event_obj,'Position');
data = event_obj.Target.CData;

SourceFields = cellstr(get(handles.SourcePop,'String'));
Source = SourceFields{get(handles.SourcePop,'Value')};

sliceNum = str2double(get(handles.SliceValue,'String'));

txt = {['Source: ', Source],...
       ['[X,Y]: ', '[', num2str(pos(1)), ',', num2str(pos(2)), ']'],...
       ['Slice: ', num2str(sliceNum)],...
	   ['Value: ', num2str(data(pos(2), pos(1)))]};

function RefreshPlot(handles)
if isempty(handles.CurrentData), return; end
Current = GetCurrent(handles);
xl = xlim;
yl = ylim;
% imagesc(flipdim(Current',1));
imagesc(rot90(Current));
axis equal off;
RefreshColorMap(handles);
xlim(xl);
ylim(yl);
drawnow;



% ######################## CREATE FUNCTIONS ##############################
function SimVaryOptRuns_CreateFcn(hObject, eventdata, handles)
function SimVaryPlotX_CreateFcn(hObject, eventdata, handles)
function SimVaryPlotY_CreateFcn(hObject, eventdata, handles)
function SimVaryOptTable_CellEditCallback(hObject, eventdata, handles)
function SimRndOptVoxels_CreateFcn(hObject, eventdata, handles)
function SimRndPlotX_CreateFcn(hObject, eventdata, handles)
function SimRndPlotY_CreateFcn(hObject, eventdata, handles)
function SimRndPlotType_CreateFcn(hObject, eventdata, handles)
function CurrentFitId_CreateFcn(hObject, eventdata, handles)
function ColorMapStyle_CreateFcn(hObject, eventdata, handles)
function SourcePop_CreateFcn(hObject, eventdata, handles)
function View_CreateFcn(hObject, eventdata, handles)
function MinValue_CreateFcn(hObject, eventdata, handles)
function MaxValue_CreateFcn(hObject, eventdata, handles)
function MinSlider_CreateFcn(hObject, eventdata, handles)
function MaxSlider_CreateFcn(hObject, eventdata, handles)
function SliceSlider_CreateFcn(hObject, eventdata, handles)
function SliceValue_CreateFcn(hObject, eventdata, handles)
function ViewPop_CreateFcn(hObject, eventdata, handles)
function FitDataAxe_CreateFcn(hObject, eventdata, handles)
function edit35_Callback(hObject, eventdata, handles)
function edit35_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function uibuttongroup1_SizeChangedFcn(hObject, eventdata, handles)
function Method_Selection_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function pushbutton173_Callback(hObject, eventdata, handles)
function pushbutton174_Callback(hObject, eventdata, handles)
function pushbutton175_Callback(hObject, eventdata, handles)
function pushbutton170_Callback(hObject, eventdata, handles)
function pushbutton171_Callback(hObject, eventdata, handles)
function pushbutton172_Callback(hObject, eventdata, handles)
function slider4_Callback(hObject, eventdata, handles)
function slider4_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function slider5_Callback(hObject, eventdata, handles)
function slider5_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function RoiDraw_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function RoiThreshMin_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function RoiThreshMax_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function MethodqMT_Callback(hObject, eventdata, handles)
function ChooseMethod_Callback(hObject, eventdata, handles)

function pushbutton169_Callback(hObject, eventdata, handles)
function pushbutton168_Callback(hObject, eventdata, handles)
function pushbutton167_Callback(hObject, eventdata, handles)
function pushbutton166_Callback(hObject, eventdata, handles)
function TimeValue_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function TimeSlider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function RoiAnalysis_Callback(hObject, eventdata, handles)
% hObject    handle to RoiAnalysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

 setappdata(0,'roidata',handles.CurrentData);
if ~license('test', 'Image_Toolbox'), warndlg('Image Toolbox is not installed: ROI Analysis tool not available in the GUI;'); return; end

roiGui = Roi_analysis(handles);
set(roiGui,'WindowStyle','modal') %If you want to "freeze" main GUI until secondary is closed.
uiwait(roiGui) %Wait for user to finish with secondary GUI.
guidata(hObject, handles);
%----------------------------------------- END ------------------------------------------%
