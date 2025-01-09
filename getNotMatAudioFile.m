function [audio_fname] = getNotMatAudioFile(notmat_fname)
% GETNOTMATAUDIOFILE
% 
% Given path to a .not.mat file, return the associated audio file (stored as
% fname).
% 
% Made this as a function to (1) avoid polluting other workspace and (2) make
% it easier to change fieldname/other behavior later, if need be. 
% 

load(notmat_fname, 'fname');

assert( ...
    exist('fname', 'var'), ...
    "Provided .not.mat does not have field `fname`! File: " + notmat_fname ...
);

audio_fname = fname;
end

