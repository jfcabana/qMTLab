function Fit = FitData(data, Model, wait , Fittmp)

% ----------------------------------------------------------------------------------------------------
% Fit = FitData( data, Model, wait, FitTempResults_filename )
% Takes 2D or 3D MTdata and returns fitted parameters maps
% ----------------------------------------------------------------------------------------------------
% Inputs
%     data                       [struct] with fields Model.MRIinputs. Contains MRI data.
%                                          data fields are array of size [x,y,z,(nT or 1)],
%                                          where x = image height, y = image width,
%                                          z = image depth and nT is the number of
%                                          data points for each voxel
%     Model                      [class]  Model object
%     wait                       [binary] display a wait bar?
%     FitTempResults_filename    [string] filename of a temporary fitting file
%
% Output
%     Fit                        [struct] with fitted parameters
%
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-Fran??ois Cabana, 2016
% ----------------------------------------------------------------------------------------------------
% If you use qMRLab in your work, please cite :
%
% Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S.,
% Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016),
% Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation,
% analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
% ----------------------------------------------------------------------------------------------------

% Before fitting, do a sanity check on the input data and protocol
Model.sanityCheck(data);

tStart = tic;

h=[];
if ismethod(Model,'Precompute'), Model = Model.Precompute; end
if Model.voxelwise % process voxelwise
    %############################# INITIALIZE #################################
    % Get dimensions
    MRIinputs = fieldnames(data);
    MRIinputs(structfun(@isempty,data))=[];
    MRIinputs(strcmp(MRIinputs,'hdr'))=[];
    qDataIdx=find((strcmp(Model.MRIinputs{1},MRIinputs')));
    qData = double(data.(MRIinputs{qDataIdx}));
    x = 1; y = 1; z = 1;
    [x,y,z,nT] = size(qData);

    % Arrange voxels into a column
    nV = x*y*z;     % number of voxels
    for ii = 1:length(MRIinputs)
        if ndims(data.(MRIinputs{ii})) == 4
            data.(MRIinputs{ii}) = reshape(data.(MRIinputs{ii}),nV,nT);
        elseif ~isempty(data.(MRIinputs{ii}))
            data.(MRIinputs{ii}) = reshape(data.(MRIinputs{ii}),nV,1);
        end
    end

    % Load FitTempResults
    if exist('Fittmp','var')
        Fit = load(Fittmp);
        computed = Fit.computed(:);
        fields = Fit.fields;
    else
        computed = false(nV,1);
    end


    % Find voxels that are not empty
    if isfield(data,'Mask') && (~isempty(data.Mask))
        Voxels = find(all(data.Mask & ~computed,2));
    else
        Voxels = find(~computed)';
    end
    l = length(Voxels);

    % Travis?
    if isempty(getenv('ISTRAVIS')) || ~str2double(getenv('ISTRAVIS')), ISTRAVIS=false; else ISTRAVIS=true; end

    %############################# FITTING LOOP ###############################
    % Create waitbar
    if exist('wait','var') && (wait)
        h = waitbar(0,'0%','Name','Fitting data','CreateCancelBtn',...
            'if ~strcmp(get(gcbf,''Name''),''canceling...''), setappdata(gcbf,''canceling'',1); set(gcbf,''Name'',''canceling...''); else delete(gcbf); end');
        setappdata(h,'canceling',0)
    end

    if (isempty(h)), j_progress('Fitting voxel ',l); end
    for ii = 1:l
        vox = Voxels(ii);

        % Update waitbar
        if (isempty(h))
            % j_progress(ii) Feature removed temporarily until logs are implemented ? excessive printing is a nuissance in Jupyter Notebooks, and slow down processing
%            fprintf('Fitting voxel %d/%d\r',ii,l);
        else
            if getappdata(h,'canceling');  break;  end  % Allows user to cancel
            waitbar(ii/l, h, sprintf('Fitting voxel %d/%d', ii, l));
        end

        % Get current voxel data
        for iii = 1:length(MRIinputs)
            M.(MRIinputs{iii}) = data.(MRIinputs{iii})(vox,:)';
        end
        if isfield(data,'hdr'), M.hdr = data.hdr; end
        % Fit data
        tempFit = Model.fit(M);
        if isempty(tempFit), Fit=[]; return; end

        % initialize the outputs
        if ii==1 && ~exist('Fittmp','var')
            fields =  fieldnames(tempFit)';

            for ff = 1:length(fields)
                Fit.(fields{ff}) = zeros(x,y,z,length(tempFit.(fields{ff})));
            end
            Fit.fields = fields;
            Fit.computed = zeros(x,y,z);
        end

        % Assign current voxel fitted values
        for ff = 1:length(fields)
            [xii,yii,zii] = ind2sub([x,y,z],vox);
            Fit.(fields{ff})(xii,yii,zii,:) = tempFit.(fields{ff});
        end

        Fit.computed(vox) = 1;

        %-- save temp file every 20 voxels
        if(mod(ii,20) == 0)
            save('FitTempResults.mat', '-struct','Fit');
        end

        if ISTRAVIS && ii>2
            try
                Fit = load(fullfile('.','FitResults','FitResults.mat'));
            end
            break;
        end
    end

else % process entire volume

% AK: Commenting out this block. Modal window is actually annoying.
    %{
    if exist('wait','var') && (wait) && not(isdeployed)
        hMSG = msgbox({'Fitting has been started. Please wait until this window disappears.'; ...
        ' '; 'You can follow outputs from the CommandWindow'});

        set(hMSG,'WindowStyle','modal')
        set(hMSG,'pointer', 'watch'); drawnow;
    end
    %}

    Fit = Model.fit(data);
    Fit.fields = fieldnames(Fit);
    disp('...done');
end
% delete waitbar
%if (~isempty(hMSG) && not(isdeployed));  delete(hMSG); end

Fit.Time = toc(tStart);
Fit.Protocol = Model.Prot;
Fit.Model = Model;
Fit.Version = qMRLabVer;
if exist(fullfile('.','FitTempResults.mat'),'file')
    delete FitTempResults.mat
end
end
