function [smooth,spec,t,f]=SmoothData(rawsong,Fs,DOFILT,filter_type,nfft,olap,sm_win,F_low,F_High);
% [smooth,spec,t,f]=SmoothData(rawsong,Fs,DOFILT,filter_type,nfft,olap,sm_win,F_low,F_High);
% returns the smoothed waveform/envelope + the spectrum
%

if (~exist('filter_type','var'))
	filter_type='hanningfir';
end
if (~exist('F_low','var'))
	F_low  = 500.0;
end
if (~exist('F_high','var'))
	F_high = 10000.0;
end
if (~exist('nfft','var'))
	nfft = 512;
end
if (~exist('olap','var'))
	olap = 0.8;
end
if (~exist('sm_win','var'))
	sm_win = 2.0;%ms
end
if(~exist('SPTH'))
    SPTH=0.01;
end


if (~exist('DOFILT','var'))
    DOFILT=1;
end

if (DOFILT==1)
    filtsong=bandpass_blab(rawsong,Fs,F_low,F_high,filter_type);
else
    filtsong=rawsong;
end

if (nargout > 1)
    spect_win = nfft;
    noverlap = floor(olap*nfft);
    [spec,f,t] = specgram(filtsong,nfft,Fs,spect_win,noverlap);
    p = find(abs(spec)<=SPTH);
    spec(p) = SPTH;
end

squared_song = filtsong.^2;

%smooth the rectified song
len = round(Fs*sm_win/1000);
h   = ones(1,len)/len;
smooth = conv(h, squared_song);
offset = round((length(smooth)-length(filtsong))/2);
smooth=smooth(1+offset:length(filtsong)+offset);
return;
