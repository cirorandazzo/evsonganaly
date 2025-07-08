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
    fname = replace(fname, "\", "/");  % forward slashes compatibile across OS

    % check if var `fname` in `.not.mat` file
    assert( ...
        exist('fname', 'var'), ...
        "Provided .not.mat does not have field `fname`! File: " + notmat_fname ...
    );

    % try updating server address to match OS
    % won't change path if it's not one of these.
    if ismac
        fname = replace(fname, "//macaw.ucsf.edu", "/Volumes");
    elseif ispc
        fname = replace(fname, "/Volumes", "//macaw.ucsf.edu");
    else
        warning('Platform not supported; may not find files on the server.')
    end

    % check if file @ fname exists.
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

    disp("Found local copy of audio to use. File: " + fname);
end

audio_fname = fname;

end

