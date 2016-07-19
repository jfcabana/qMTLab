function Pulse = GetPulse(alpha, delta, Trf, shape, PulseOpt)

gamma = 2*pi*42576;

if (nargin < 5)
    PulseOpt = struct;
end

switch shape
    case 'hard';      pulse_fcn = @hard_pulse;  
    case 'sinc';      pulse_fcn = @sinc_pulse;        
    case 'sinchann';  pulse_fcn = @sinchann_pulse;        
    case 'sincgauss'; pulse_fcn = @sincgauss_pulse;        
    case 'gaussian';  pulse_fcn = @gaussian_pulse;        
    case 'gausshann'; pulse_fcn = @gausshann_pulse;    
    case 'fermi';     pulse_fcn = @fermi_pulse;  
end

b1     =  @(t) pulse_fcn(t,Trf,PulseOpt);
amp    =  2*pi*alpha / ( 360 * gamma * integral(@(t) (b1(t)), 0, Trf) );
% amp    =  2*pi*alpha / ( 360 * gamma * integral(@(t) abs(b1(t)), 0, Trf,'ArrayValued',true) );
omega  =  @(t) (gamma*amp*pulse_fcn(t,Trf,PulseOpt));
omega2 =  @(t) (gamma*amp*pulse_fcn(t,Trf,PulseOpt)).^2;

Pulse.pulse_fcn = pulse_fcn;  % Fcn handle to pulse shape function
Pulse.b1     =   b1;          % Fcn handle to pulse enveloppe amplitude
Pulse.amp    =   amp;         % Pulse max amplitude
Pulse.omega  =   omega;       % Fcn handle to pulse omega1
Pulse.omega2 =   omega2;      % Fcn handle to pulse omega1^2 (power)
Pulse.alpha  =   alpha;       % Flip angle
Pulse.delta  =   delta;       % Pulse offset
Pulse.Trf    =   Trf;         % Pulse duration
Pulse.shape  =   shape;       % Pulse shape string
Pulse.opt    =   PulseOpt;    % Additional options (e.g. TBW for sinc time-bandwidth window, bw for gaussian bandwidth)


end