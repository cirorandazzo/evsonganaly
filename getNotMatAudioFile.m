function [audio_fname] = getNotMatAudioFile(notmat_fname)
% GETNOTMATAUDIOFILE
% 
% Given path to a .not.mat file, return the associated audio file (stored as
% fname).
% 
% Made this as a function to (1) avoid polluting other workspace and (2) make
% it easier to change fieldname/other behavior later, if need be. 
% 

try  % load audio fname from notmat
    load(notmat_fname, 'fname');

    assert( ...
        exist('fname', 'var'), ...
        "Provided .not.mat does not have field `fname`! File: " + notmat_fname ...
    );

    assert( ...
        exist(fname, 'file'), ...
        "Audio file does not exist! File: " + fname ...
    );

catch  % check locally for audio.
    disp("Trying matching audio file in local dir...")

    fname = replace(notmat_fname, ".not.mat", "");

    assert( ...
        exist(fname, 'file'), ...
        "Couldn't find audio locally either! Tried file: " + fname ...
    );

    % if local audio file does exist, update audio path saved notmat
    save(notmat_fname, "fname", "-append")
end

audio_fname = fname;

end

