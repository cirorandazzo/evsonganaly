function c = convJC(a, b)
%CONV Convolution and polynomial multiplication.
%   C = CONV(A, B) convolves vectors A and B.  The resulting
%   vector is length LENGTH(A)+LENGTH(B)-1.
%   If A and B are vectors of polynomial coefficients, convolving
%   them is equivalent to multiplying the two polynomials.
%
%   Class support for inputs A,B:
%      float: double, single
%
%   See also DECONV, CONV2, CONVN, FILTER and, in the Signal
%   Processing Toolbox, XCORR, CONVMTX.

%   Copyright 1984-2006 The MathWorks, Inc.
%   $Revision: 5.16.4.3 $  $Date: 2006/06/20 20:09:21 $

na = length(a);
nb = length(b);

if na ~= numel(a) || nb ~= numel(b)
 error('MATLAB:conv:AorBNotVector', 'A and B must be vectors.');
end

% Convolution, polynomial multiplication, and FIR digital
% filtering are all the same operations.  Since FILTER
% is a fast built-in primitive, we'll use it for CONV.

% CONV(A,B) is the same as CONV(B,A), but we can make it go
% substantially faster if we swap arguments to make the first
% argument to filter the shorter of the two.
if na > nb
   [c,zf] = filter(b, 1, a);
   if nb > 1
       c(na+1:na+nb-1) = zf;
   end
else
   [c,zf] = filter(a, 1, b);
   if na > 1
       c(nb+1:na+nb-1) = zf;
   end
end