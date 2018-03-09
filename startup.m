addpath(genpath(pwd))

% install octave package

if moxunit_util_platform_is_octave
    more off;
    installist = {'struct-1.0.14.tar.gz','optim-1.5.2.tar.gz','io-2.4.10.tar.gz','statistics-1.3.0.tar.gz','image-2.6.1.tar.gz'};
    loadlist = {'struct','optim','io','statistics','image'};
    for ii=1:length(installist)
        try
            disp(['Installing --> ' installist{ii}])
            eval(['pkg install ' installist{ii}])
            disp(['Loading -->' loadlist{ii}])
            eval(['pkg load ' loadlist{ii}])
        catch
            errorcount = 1;
            while errorcount % try to install 30 times (Travis)
                try
                    eval(['pkg install ' installist{ii}])
                    eval(['pkg load ' loadlist{ii}])
                    errorcount = 0;
                catch err
                    errorcount = errorcount+1;
                    if errorcount>30
                        error(err.message)
                    end
                end
            end
        end
    end
disp('Packages have been installed and loaded.')    
end



try
    NODDI_erfi(.8);
catch
    % Compile Faddeeva
    cur = pwd;
    cd(fullfile(fileparts(mfilename('fullpath')),'External','Faddeeva_MATLAB'))
    try
        disp('Compile Faddeeva...')
        Faddeeva_build
        disp('                ...ok')
        cd(cur)
    catch
        cd(cur)
        error('Cannot compile External/Faddeeva_MATLAB, a function used by NODDI. Plz install a compiler and run Faddeeva_build. Alternatively, edit NODDI_erfi.')
    end
end