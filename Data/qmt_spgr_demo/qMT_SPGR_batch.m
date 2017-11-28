% Command Line Interface (CLI) is well-suited for automatization 
% purposes and Octave. 

% Please execute this m-file section by section to get familiar with batch
% processing for qmt_spgr on CLI.

% This m-file has been automatically generated. 

% Written by: Agah Karakuzu, 2017
% =========================================================================

%% AUXILIARY SECTION - (OPTIONAL) -----------------------------------------
% -------------------------------------------------------------------------

qMRinfo('qmt_spgr'); % Display help 
[pathstr,fname,ext]=fileparts(which('qmt_spgr_batch.m'));
cd (pathstr);

%% STEP|CREATE MODEL OBJECT -----------------------------------------------
%  (1) |- This section is a one-liner.
% -------------------------------------------------------------------------

Model = qmt_spgr; % Create model object

%% STEP |CHECK DATA AND FITTING - (OPTIONAL) ------------------------------
%  (2)	|- This section will pop-up the options GUI. (MATLAB Only)
%		|- Octave is not GUI compatible. 
% -------------------------------------------------------------------------

if not(moxunit_util_platform_is_octave) % ---> If MATLAB
Custom_OptionsGUI(Model);
Model = getappdata(0,'Model');
end



%% STEP |LOAD PROTOCOL ----------------------------------------------------
%  (3)	|- Respective command lines appear if required by qmt_spgr. 
% -------------------------------------------------------------------------

% qmt_spgr object needs 2 protocol field(s) to be assigned:
 

% MTdata
% TimingTable
% --------------
% Angle is a vector of [10X1]
Angle = [142.0000; 426.0000; 142.0000; 426.0000; 142.0000; 426.0000; 142.0000; 426.0000; 142.0000; 426.0000];
% Offset is a vector of [10X1]
Offset = [443.0000; 443.0000; 1088.0000; 1088.0000; 2732.0000; 2732.0000; 6862.0000; 6862.0000; 17235.0000; 17235.0000];
Model.Prot.MTdata.Mat = [ Angle Offset];
% -----------------------------------------
Tmt  = 0.0102;
Ts  = 0.003;
Tp  = 0.0018;
Tr  = 0.01;
TR  = 0.025;
Model.Prot.TimingTable.Mat = [ Tmt  Ts  Tp  Tr  TR ];
% -----------------------------------------



%% STEP |LOAD EXPERIMENTAL DATA -------------------------------------------
%  (4)	|- Respective command lines appear if required by qmt_spgr. 
% -------------------------------------------------------------------------
% qmt_spgr object needs 5 data input(s) to be assigned:
 

% MTdata
% R1map
% B1map
% B0map
% Mask
% --------------

data = struct();
 
% B0map.mat contains [88  128] data.
 load('B0map.mat');
% B1map.mat contains [88  128] data.
 load('B1map.mat');
% MTdata.mat contains [88  128    1   10] data.
 load('MTdata.mat');
% Mask.mat contains [88  128] data.
 load('Mask.mat');
% R1map.mat contains [88  128] data.
 load('R1map.mat');
 data.MTdata= double(MTdata);
 data.R1map= double(R1map);
 data.B1map= double(B1map);
 data.B0map= double(B0map);
 data.Mask= double(Mask);

%% STEP |FIT DATASET ------------------------------------------------------
%  (5)  |- This section will fit data. 
% -------------------------------------------------------------------------

FitResults = FitData(data,Model,0);

FitResults.Model = Model; % qMRLab output.

%% STEP |CHECK FITTING RESULT IN A VOXEL - (OPTIONAL) ---------------------
%   (6)	|- To observe outputs, please execute this section.
% -------------------------------------------------------------------------

% Read output  ---> 
%{
outputIm = FitResults.(FitResults.fields{1});
row = round(size(outputIm,1)/2);
col = round(size(outputIm,2)/2);
voxel           = [row, col, 1]; % Please adapt 3rd index if 3D. 
%}

% Show plot  ---> 
% Warning: This part may not be available for all models.
%{
figure();
FitResultsVox   = extractvoxel(FitResults,voxel,FitResults.fields);
dataVox         = extractvoxel(data,voxel);
Model.plotModel(FitResultsVox,dataVox)
%}

% Show output map ---> 
%{ 
figure();
imagesc(outputIm); colorbar(); title(FitResults.fields{1});
%}


%% STEP |SAVE -------------------------------------------------------------
%  	(7) |- Save your outputs. 
% -------------------------------------------------------------------------

if moxunit_util_platform_is_octave % ---> If Octave 

save -mat7-binary 'qmt_spgr_FitResultsOctave.mat' 'FitResults';

else % ---> If MATLAB 

qMRsaveModel(Model,'qmt_spgr.qMRLab.mat'); 

end

% You can save outputs in Nifti format using FitResultSave_nii function:
% Plase see qMRinfo('FitResultsSave_nii')




