% This function is to provide Octave compatibility for help text.
% Octave accepts a different convention for help documentation. 
% Until we find a through solution for Octave help, we will skip this for
% Octave. 

% This is the reason why this function will be used instead of 'help' 

function varargout = qMRinfo(varargin)
% Display Model headers (MR protocol, model detail, fitting parameters, options)
% Example:
%   qMRinfo('MWF'); % display help for Myelin Water Fraction
if ~moxunit_util_platform_is_octave
    if nargin==0, varargin{1}='qMRinfo'; end
    [varargout{1:nargout}] = help(varargin{:});
else
    varargout{1} = 'Sorry, not implemented for Octave yet. Please contribute on github.com/neuropoly/qMRLab';
	disp(varargout{1})
end