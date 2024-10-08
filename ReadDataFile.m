function [dat,fs,DOFILT,ext,varargout]=ReadDataFile(fullfname,chanspec,ALLDATA);
%% Modified by PJ to plot trigs from intan board
%[dat,Fs,DOFILT,ext]=ReadDataFile(fullfname,chanspec,ALLDATA);
%
% Reads data from soundfile into matlab vector
%
% INPUTS:
%
%   fullfname - is the full file name with path and extension
%   chanspec -  which channel do you want to read starting from 1st-sorry
%           a value of -1 returns all the data
%    ALLDATA = 1 measn take all data forget sbout what is in chanspec
% OUTPUTS:
%   dat - is a matrix, with all the colums of data
%         wav files will only have one column
%   fs  - The sampling rate if available from the file specified in SOUNDFILE.
%           If the sampling rate is not available, then Fs = -1 is returned
%   DOFILT - set to 0 if it is a filt file, stops SmoothData from filtering
%   ext - file extension
%

DOFILT=1;
varargout = {};

%Defualt is 0 not 0r!
if (~exist('chanspec'))
    chan=0;ISR=0;
elseif (length(chanspec)<1)
    chan=0;ISR=0;
else
    if (strcmp(chanspec(end),'r'))
        chan = str2num(chanspec(1:end-1));
        ISR = 1;
    else
        chan=str2num(chanspec);
        ISR = 0;
    end
end

if (exist('ALLDATA'))
    if (ALLDATA==1)
        chan = -1;
    end
end

[pth,nm,ext]=fileparts(fullfname);
%if (length(ext)<1)
%    ext='.wav';
%end
%ext = lower(ext);

if (strcmp(ext,'.wav'))
    [dat,fs]=audioread(fullfname);
    ISR=0;chan=0;
elseif (strcmp(ext,'.ebin'))
    [dat,fs]=ReadEbinFile(fullfname);
elseif (strcmp(ext,'.cbin')|strcmp(ext,'.bbin'))
    [dat,fs]=ReadCbinFile(fullfname);
    if length(dat(1, :)) > 1
        varargout{1} = dat(:,2); % Triggers
    end
elseif (strcmp(ext,'.filt'))
    [dat,fs]=ReadFilt(fullfname);
    DOFILT=0;chan=0;
elseif (strcmp(ext,'.raw'))
    [dat,fs]=ReadRawFile(fullfname);
    ISR=0;chan=0;
elseif (strcmp(ext,'.rhd'))
    fullfname=[pth '/' nm ext]
    %[dat,fs]=IntanRHDReadSong('',fullfname);
    [freq,dat] = pj_readIntanNoGui_AudioOnly(fullfname,1);
    [o1,o2,digDat,o3] = pj_readIntanNoGui(fullfname,0);
    varargout{1} = digDat; % Triggers
    % Try to find 
    fs = freq.amplifier_sample_rate;
    ISR=0;chan=-1;
elseif strcmp(ext,'') %For krank files
    [dat,fs] = ReadOKrankData(nm,1);
else
    [dat,fs]=audioread(fullfname);
    ext = '.wav';
    ISR=0;chan=0;
end

if length(varargout) == 0
    varargout{1} = [];
end

if (chan ~= -1)
    if (ISR==0)
        wchan = chan + 1;
    else
        wchan = size(dat,2) - chan;
    end
    
    dat = dat(:,wchan);
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%FILT FILE FOR JON %%%%%%%%%%%%%%%%%%%%%%%
function  [filtsong, Fs] = ReadFilt(filt_file)
%read songdata from filt_file
% file format:
% files are assumed to be written by write_filt
% all data is written "big-endian"
% Fs: sample rate (in kHz) 1*(short)
% filtsong: length(filtsong)*(short) 

%try to open file 
[fid, message] = fopen(filt_file, 'r', 'b');

% if couldn't open output, exit
if fid == -1
    filtsong = [];
    Fs = -1;
    return;
end

%read data
Fs = fread(fid, 1, 'double');
filtsong = fread(fid, inf, 'double');

fclose(fid);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%% READEBINFILE %%%%%%%%%%%%%%%%%%%%%%%%%%%
function [data,fs]=ReadEbinFile(fname);
%[data,fs]=ReadEbinFile(fname);
%

if (exist(fname,'file'))
    fid=fopen(fname,'r','b');
    RData=fread(fid,inf,'float');
    fclose(fid);

    % load evtaf defaults
    fs = 32000.0;
    Nchan = 2;
    Ndata = floor(length(RData)/Nchan);

    pos = strfind(fname,'.ebin');
    if (length(pos)==0)
        recfile = [fname,'.rec'];
    else
        recfile = [fname(1:pos(end)),'rec'];
    end
    if (~exist(recfile,'file'))
        warning(['Could not file rec file: ',recfile,...
            '- Assuming standard fs and 2 data channels']);
    else
        recdata=readrecf(fname);
        Ndata = recdata.nsamp;
        fs = recdata.adfreq;
        Nchan = recdata.nchan;
    end

    if (Ndata*Nchan~=length(RData))
        warning(['Data size does not match REC file!']);
    end
    
    data = zeros([Ndata,Nchan]);
    for ind=1:Nchan
        data(:,ind)=RData(ind:Nchan:end);
    end
else
    warning(['Could not find file: ',fname,'- skipping it']);
    data=[];fs=-1;
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%% READRAWFILE %%%%%%%%%%%%%%%%%%%%%%%%%%%
function [data,fs]=ReadRawFile(fname);
%[data,fs]=ReadRawFile(fname);
%

if (exist(fname,'file'))
    fid=fopen(fname,'r','b');
    data=fread(fid,inf,'short');
    fclose(fid);

    % load evtaf defaults
    fs = 32000.000;
    Nchan = 1;
    Ndata = length(data);
else
    warning(['Could not find file: ',fname,'- skipping it']);
    data=[];fs=-1;
end
return;
