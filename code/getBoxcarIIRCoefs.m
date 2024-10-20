% Function converts a boxcar FIR filter into an equivalent IIR filter
%
% inputs:
%   L       boxcar filter length
%
% outputs:
%   b       transfer function numerator coefficients
%   a       transfer function denominator coefficients
function [b, a] = getBoxcarIIRCoefs(L)

    % For FIR filter
    % Y(z) = X(z)*sum(z^-n) for n in [0,L-1]
    % => Y(z) = X(z)*(1-z^-L)/(1-z^-1)
    a = [1, -1];
    b = [1, zeros(1,L-1), -1];
end