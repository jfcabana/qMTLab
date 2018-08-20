classdef qsm_sb < AbstractModel
% CustomExample :  Quantitative susceptibility mapping
%
% Inputs:
%   PhaseGRe    3D xxx
%   (MagnGRE)     3D xxx
%   Mask        Binary mask
%
% Assumptions:
% (1)FILL
% (2)
%
% Fitted Parameters:
%    chi_SB
%    chi_L2
%
% Non-Fitted Parameters:
%    residue                    Fitting residue.
%
% Options:
%   Q-space regularization
%       Smooth q-space data per shell b code for the complete reconstruction pipeline (Laplacian unwrapping, SHARP filtering, ℓ2- and ℓ1- regularized fast susceptibility mapping with magnitude weighting and parameter estimation) is included as supplementary material and made available prior fitting
%
% Example of command line usage (see also <a href="matlab: showdemo Custom_batch">showdemo Custom_batch</a>):
%   For more examples: <a href="matlab: qMRusage(Custom);">qMRusage(Custom)</a>
%
% Authors: Mathieu Boudreau and Agah Karakuzu
%
% References:
%   Please cite the following if you use this module:
%
%     Bilgic et al. (2014), Fast quantitative susceptibility mapping with
%     L1-regularization and automatic parameter selection. Magn. Reson. Med.,
%     72: 1444-1459. doi:10.1002/mrm.25029
%
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

properties

% --- Inputs
MRIinputs = {'PhaseGRE', 'MagnGRE', 'Mask'};

% --- Fitted parameters
xnames = { 'chi_SB','chi_L2', 'mask_Sharp',...
'magn_weight'};

voxelwise = 0;

% Protocols linked to the OSF data
Prot = struct('Resolution',struct('Format',{{'VoxDim[1] (mm)' 'VoxDim[2] (mm)' 'VoxDim[3] (mm)'}},...
'Mat',  [0.6 0.6 0.6]),...
'Timing',struct('Format',{{'TE (s)'}},...
'Mat', 8.1e-3), ...
'Magnetization', struct('Format', {{'Field Strength (T)' 'Central Freq. (MHz)'}}, 'Mat', [3 42.58]));


% Model options
buttons = {'Direction',{'forward','backward'}, 'Sharp Filtering', true, 'Sharp Mode', {'once','iterative'}, 'Padding Size', [9 9 9],'Magnitude Weighting',false,'PANEL', 'Regularization Selection', 4,...
'L1 Regularized', false, 'L2 Regularized', false, 'Split-Bregman', false, 'No Regularization', false, ...
'PANEL', 'L1 Panel',2, 'Lambda L1', 5, 'ReOptimize Lambda L1', false, 'L1 Range', [-4 2.5 15], ...
'PANEL', 'L2 Panel', 2, 'Lambda L2',5, 'ReOptimize Lambda L2', false, 'L2 Range', [-4 2.5 15]
};

% Tiptool descriptions
tips = {'Direction','Direction of the differentiation', ...
'Magnitude Weighting', 'Calculates gradient masks from Magn data using k-space gradients and includes magn weighting in susceptibility maping.',...
'Sharp Filtering', 'Enable/Disable SHARP background removal.', ...
'Sharp Mode', 'Once: 9x9x9 kernel. Iterative: 9x9x9 to 3x3x3 with the step size of -2x-2x-2.', ...
'Padding Size', 'Zero padding size for SHARP kernel convolutions.', ...
'L1 Regularized', 'Open L1 regulatization panel.', ...
'L2 Regularized', 'Open L2 regulatization panel.', ...
'Split-Bregman',  'Perform Split-Bregman quantitative susceptibility mapping.', ...
'ReOptimize Lambda L1', 'Do not use default or user-defined Lambda L1.', ...
'ReOptimize Lambda L2', 'Do not use default or user-defined Lambda L2.', ...
'L1 Range','Optimization range for L1 regularization weights [min max N]',...
'L2 Range','Optimization range for L2 regularization weights [min max N]'
};

options= struct();

end % Public properties

properties (Hidden = true)

rangeL1 = [-4 2.5 5];
rangeL2 = [-4 2.5 5];

lambdaL1Range = [];
lambdaL2Range = [];

onlineData_url = 'https://osf.io/rn572/download/';

end % Hidden public properties

methods

function obj = qsm_sb


  % Transfer regularization parameter optimization range to the logspace
  obj.lambdaL1Range = logspace(obj.rangeL1(1),obj.rangeL1(2), obj.rangeL1(3));
  obj.lambdaL2Range = logspace(obj.rangeL2(1), obj.rangeL2(2), obj.rangeL2(3));
  % Convert buttons to options
  obj.options = button2opts(obj.buttons);
  % UpdateFields to take GUI interactions their effect on opening.
  obj = UpdateFields(obj);

end % fx: Constructor

function obj = UpdateFields(obj)

  % Functional but imperfect for now. When Split-Bergman
  % selected,you cannot disable L1 and L2, but they are not
  % disabled. Use state = getCheckBoxState(obj,checkBoxName)
  % later.

  obj = linkGUIState(obj, 'Sharp Filtering', 'Sharp Mode', 'show_hide_button', 'active_1');
  obj = linkGUIState(obj, 'Sharp Filtering', 'Padding Size', 'show_hide_button', 'active_1');

  obj = linkGUIState(obj, 'Split-Bregman', 'L1 Regularized', 'enable_disable_button', 'active_0', true);
  obj = linkGUIState(obj, 'No Regularization', 'L1 Regularized', 'enable_disable_button', 'active_0',false);

  obj = linkGUIState(obj, 'Split-Bregman', 'L2 Regularized', 'enable_disable_button', 'active_0', true);
  obj = linkGUIState(obj, 'No Regularization', 'L2 Regularized', 'enable_disable_button', 'active_0',false);

  obj = linkGUIState(obj, 'No Regularization', 'Split-Bregman', 'enable_disable_button', 'active_0',false);
  obj = linkGUIState(obj, 'Split-Bregman', 'No Regularization', 'enable_disable_button', 'active_0',false);

  obj = linkGUIState(obj, 'L1 Regularized', 'L1 Panel', 'show_hide_panel', 'active_1');
  obj = linkGUIState(obj, 'L2 Regularized', 'L2 Panel', 'show_hide_panel', 'active_1');

  obj = linkGUIState(obj, 'ReOptimize Lambda L1', 'L1 Range', 'show_hide_button', 'active_1');
  obj = linkGUIState(obj, 'ReOptimize Lambda L2', 'L2 Range', 'show_hide_button', 'active_1');
  obj = linkGUIState(obj, 'ReOptimize Lambda L1', 'Lambda L1', 'enable_disable_button', 'active_0');
  obj = linkGUIState(obj, 'ReOptimize Lambda L2', 'Lambda L2', 'enable_disable_button', 'active_0');

  % LINK PADSIZE TO THE SHARP

end %fx: UpdateFields (Member)

function FitResults = fit(obj,data)

  gyro =   2*pi*(obj.Prot.Magnetization.Mat(2));
  B0   =   obj.Prot.Magnetization.Mat(1);
  TE   =   obj.Prot.Timing.Mat;
  imageResolution = obj.Prot.Resolution.Mat;
  FitOpt = GetFitOpt(obj);
  FitResults = struct();
  % For now, assuming wrapped phase.

  % Mask wrapped phase
  data.Mask = logical(data.Mask);
  data.PhaseGRE(~data.Mask) = 0;

  % Throw exceptions here to close annoying please wait window.
   if not(FitOpt.noreg_Flag) && not(FitOpt.regL2_Flag) && not(FitOpt.regSB_Flag)

      errordlg('Please make a regularization selection.');
      error('Operation has exited.')
  elseif not(FitOpt.noreg_Flag) && not(FitOpt.regL2_Flag) && not(FitOpt.regSB_Flag) && not(FitOpt.regL1_Flag)
      % This is temporary stupid message. This will be handled @ Update
      errordlg('Regularization L1 alone has no function :p');
      error('Operation has exited.')
  end


  if FitOpt.sharp_Flag % SHARP BG removal

    padSize = FitOpt.padSize;

    phaseWrapPad = padVolumeForSharp(data.PhaseGRE, padSize);
    maskPad      = padVolumeForSharp(data.Mask, padSize);

    disp('Started   : Laplacian phase unwrapping ...');
    phaseLUnwrap = unwrapPhaseLaplacian(phaseWrapPad);
    disp('Completed : Laplacian phase unwrapping');
    disp('-----------------------------------------------');

    disp('Started   : SHARP background removal ...');
    [phaseLUnwrap, maskGlobal] = backgroundRemovalSharp(phaseLUnwrap, maskPad, [TE B0 gyro], FitOpt.sharpMode);
    disp('Completed : SHARP background removal');
    disp('-----------------------------------------------');



  else

    disp('Started   : Laplacian phase unwrapping ...');
    phaseLUnwrap = unwrapPhaseLaplacian(data.PhaseGRE);
    disp('Completed : Laplacian phase unwrapping');
    disp('-----------------------------------------------');

    % WARNING!!: NOT SURE AT ALL IF THIS IS LEGIT
    %------- ! ! !  ! ! !  ! ! ! ---------
    % I assumed that even w/o SHARP, magn weight is possible by passing
    % brainmask and padding size as 0 0 0.

    % If there is sharp, phaseLUnwrap is the SHARP masked one
    % If there is not sharp phaseLUnwrap is just laplacian unwrapped phase.

    maskGlobal = data.Mask;
    padSize    = [0 0 0];

  end % SHARP BG removal

  if not(isempty(data.MagnGRE)) && FitOpt.magnW_Flag % Magnitude weighting

    disp('Started   : Calculation of gradient masks for magn weighting ...');
    magnWeight = calcGradientMaskFromMagnitudeImage(data.MagnGRE, maskGlobal, padSize, FitOpt.direction);
    disp('Completed : Calculation of gradient masks for magn weighting');
    disp('-----------------------------------------------');

  elseif isempty(data.MagnGRE) && FitOpt.magnW_Flag

    error('Magnitude data is missing. Cannot perform weighting.');

  end % Magnitude weighting

  % Lambda one has a dependency on Lambda2. On the other hand, there is no
  % chi_L1.


  if FitOpt.regL2_Flag && FitOpt.reoptL2_Flag  % || Reopt Lamda L2 case chi_L2 generation

    disp('Started   : Reoptimization of lamdaL2. ...');
    lambdaL2 = calcLambdaL2(phaseLUnwrap, FitOpt.lambdaL2Range, imageResolution);
    disp(['Completed   : Reoptimization of lamdaL2. Lambda L2: ' num2str(lamdaL2)]);
    disp('-----------------------------------------------');

    if not(isempty(data.MagnGRE)) && FitOpt.magnW_Flag % MagnitudeWeighting case | Lambdal2 reopted

      disp('Started   : Calculation of chi_L2 map with magnitude weighting...');
      [FitResults.chiL2,FitResults.chiL2pcg] = calcChiL2(phaseLUnwrap, lambdaL2, FitOpt.direction, imageResolution, maskGlobal, padSize, magnWeight);
      disp('Completed   : Calculation of chi_L2 map with magnitude weighting.');
      disp('-----------------------------------------------');

    else % No magnitude weighting case | Lambdal2 reopted

      disp('Started   : Calculation of chi_L2 map without magnitude weighting...');
      [FitResults.chiL2] = calcChiL2(phaseLUnwrap, lambdaL2, FitOpt.direction, imageResolution, maskGlobal, padSize);
      disp('Completed  : Calculation of chi_L2 map without magnitude weighting.');
      disp('-----------------------------------------------');

    end

  elseif FitOpt.regL2_Flag && not(FitOpt.reoptL2_Flag ) % || DO NOT reopt Lambda L2 case chi_L2 generation

    if isempty(FitOpt.LambdaL2) % In case user forgets

      error('Lambda2 value is needed. Please select Re-opt LambdaL2 if you dont know the value');

    else

      disp('Skipping reoptimization of Lambda L2.');
      lambdaL2 = FitOpt.LambdaL2;

    end

    if not(isempty(data.MagnGRE)) && FitOpt.magnW_Flag % MagnitudeWeighting is present | Lambdal2 known

      disp('Started   : Calculation of chi_L2 map with magnitude weighting...');
      [FitResults.chiL2,FitResults.chiL2pcg] = calcChiL2(phaseLUnwrap, lambdaL2, FitOpt.direction, imageResolution, maskGlobal, padSize, magnWeight);
      disp('Completed   : Calculation of chi_L2 map with magnitude weighting.');
      disp('-----------------------------------------------');

    else % magn weight is not present | Lambdal2 known

      disp('Started   : Calculation of chi_L2 map without magnitude weighting...');
      [FitResults.chiL2] = calcChiL2(phaseLUnwrap, lambdaL2, FitOpt.direction, imageResolution, maskGlobal, padSize);
      disp('Completed  : Calculation of chi_L2 map without magnitude weighting.');
      disp('-----------------------------------------------');

    end

  end

  % L1 flag is raised only if split bregman is selected

  if FitOpt.regL1_Flag && FitOpt.reoptL1_Flag  % || Reopt Lamda L2 case chi_L2 generation

    disp('Started   : Reoptimization of Lamda L1. ...');
    lambdaL1 = calcSBLambdaL1(phaseLUnwrap, FitOpt.lambdaL1Range, lambdaL2, imageResolution, FitOpt.direction);
    disp('Completed   : Reoptimization of Lamda L1. ...');
    disp('-----------------------------------------------');

  elseif FitOpt.regL1_Flag && not(FitOpt.reoptL1_Flag)

    lambdaL1 = FitOpt.LambdaL1;

  end


  if FitOpt.regSB_Flag && FitOpt.magnW_Flag

    disp('Started   : Calculation of chi_SBM map with magnitude weighting.. ...');
    FitResults.chiSBM = qsmSplitBregman(phaseLUnwrap, maskGlobal, lambdaL1, lambdaL2, FitOpt.direction, imageResolution, padSize, preconMagWeightFlag, magn_weight);
    disp('Completed   : Calculation of chi_SBM map with magnitude weighting.');
    disp('-----------------------------------------------');

  elseif FitOpt.regSB_Flag && not(FitOpt.magnW_Flag)

    disp('Started   : Calculation of chi_SBM map without magnitude weighting.. ...');
    FitResults.chiSBM = qsmSplitBregman(phaseLUnwrap, maskGlobal, lambdaL1, lambdaL2, FitOpt.direction, imageResolution, padSize);
    disp('Completed   : Calculation of chi_SBM map without magnitude weighting.');
    disp('-----------------------------------------------');

  end

  if FitOpt.noreg_Flag

    FitResults.nfm = abs(phaseLUnwrap(1+padSize(1):end-padSize(1),1+padSize(2):end-padSize(2),1+padSize(3):end-padSize(3)));

  end



  if not(isdeployed) && not(exist('OCTAVE_VERSION', 'builtin'))
      disp('Loading outputs to the GUI may take some time after fit has been completed.');
  end

  % Some functions are added as nasted functions for memory management.
  % --------------------------------------------------------------------

  function paddedVolume = padVolumeForSharp(inputVolume, padSize)
    % Pads mask and wrapped phase volumes with zeros for SHARP convolutions.

    paddedVolume = padarray(inputVolume, padSize);

  end % fx: padVolumeForSharp (Nested)

  function magnWeight = calcGradientMaskFromMagnitudeImage(magnVolume, maskSharp, padSize, direction)
    % Calculates gradient masks from magnitude image using k-space gradients.


    N = size(maskSharp);

    [fdx, fdy, fdz] = calcFdr(N, direction);

    magnPad = padarray(magnVolume, padSize) .* maskSharp;
    magnPad = magnPad / max(magnPad(:));

    Magn = fftn(magnPad);
    magnGrad = cat(4, ifftn(Magn.*fdx), ifftn(Magn.*fdy), ifftn(Magn.*fdz));

    magnWeight = zeros(size(magnGrad));

    for s = 1:size(magn_grad,4)

      magnUse = abs(magnGrad(:,:,:,s));

      magnOrder = sort(magnUse(maskSharp==1), 'descend');
      magnThreshold = magnOrder( round(length(magnOrder) * .3) );
      magnWeight(:,:,:,s) = magnUse <= magnThreshold;

    end

  end % calcGradientMaskFromMagnitudeImage (Nested)

  % --------------------------------------------------------------------

end % fx: fit (Member)


function FitOpt = GetFitOpt(obj)

  FitOpt.padSize = obj.options.PaddingSize;
  FitOpt.direction = obj.options.Direction;
  FitOpt.sharp_Flag = obj.options.SharpFiltering;
  FitOpt.sharpMode = obj.options.SharpMode;

  FitOpt.regSB_Flag = obj.options.RegularizationSelection_SplitBregman;
  FitOpt.regL1_Flag = obj.options.RegularizationSelection_L1Regularized;
  FitOpt.regL2_Flag = obj.options.RegularizationSelection_L2Regularized;
  FitOpt.noreg_Flag = obj.options.RegularizationSelection_NoRegularization;

  FitOpt.magnW_Flag = obj.options.MagnitudeWeighting;

  FitOpt.LambdaL1 = obj.options.L1Panel_LambdaL1;
  FitOpt.LambdaL2 = obj.options.L2Panel_LambdaL2;

  FitOpt.reoptL1_Flag = obj.options.L1Panel_ReOptimizeLambdaL1;
  FitOpt.reoptL2_Flag = obj.options.L2Panel_ReOptimizeLambdaL2;

  FitOpt.lambdaL1Range = obj.lambdaL1Range;
  FitOpt.lambdaL2Range = obj.lambdaL2Range;

end % fx: GetFitOpt (member)


end

end
