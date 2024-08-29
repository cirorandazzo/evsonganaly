function PlotDataFile(hObject,handles)
% function [onsets,offsets]=PlotDataFile(hObject,handles);
% 
% EVSONGANALY Main plotting function
% - get filename from handles structure
% - smooths and segments
% - uses not.mat file it it exists
% - calculate & plot spectrogram
% - plot smoothed noise level
% 
% Modified by PJ to plot trigs from intan board
% 
% Last edit 2024.08.13 CDR

set(hObject,'Interruptible','off');
set(hObject,'BusyAction','Cancel');
%tempvar = handles.INPUTFILES;
%save temp.mat tempvar
FNAME=handles.INPUTFILES(handles.NFILE).fname;
chanspec=handles.ChanSpec;
%PJ added addtlOut for reading triggers on separate channel
[dat,Fs,DOFILT,ext,addtlOut]=ReadDataFile(FNAME,chanspec); 
if strcmp(ext,'.cbin')
    [stim, fs]=ReadCbinFile(FNAME); % EK - for looking at additional input channels 7.15.19
    stim = stim(:, 2 : end);
    nChan = length(stim(1, :)); % number of additional input channels
else
    stim = [];
    nChan = 0;
end
if length(addtlOut) > 0
        for chan = 1 : nChan
            if strcmp(ext,'.rhd')
            try
                trig{chan}.trigDat = addtlOut(:, chan);
                [trig{chan}.pks,trig{chan}.locs] = findpeaks(trigDat);
                trig{chan}.locsT = trig{chan}.locs./Fs; %s
                plotIntanTrigs = 1;
            catch
                plotIntanTrigs = 0;
            end
            elseif strcmp(ext,'.cbin')
                trig{chan}.trigDat = stim(:, chan);
                [trig{chan}.pks,trig{chan}.locs] = findpeaks(trig{chan}.trigDat,'MinPeakHeight',1e4);
                trig{chan}.locsT = trig{chan}.locs./Fs; %s
                plotIntanTrigs = 1;        
            end
        end
else
    plotIntanTrigs = 0;
end
if ((get(handles.UseSpectBox,'Value')==get(handles.UseSpectBox,'Max'))&(exist([FNAME,'.spect'],'file')))    
    eval(['load -mat ',FNAME,'.spect']);
else
    [sm,sp,t,f]=SmoothData(dat,Fs,DOFILT,handles.filter_type);
end
%TAKE OUT THE TOP FREQ HALF OF SPECTROGRAM (IT HAS LITTLE POWER DUE TO
%FILTERING)
%sp = sp(1:128,:);f=f(1:128);
%for problems with taking the log of zero
pp=find(sp>0);
mntmp = min(min(sp(pp)));
pp=find(sp==0);
sp(pp) = mntmp;

handles.FILEEXT  = ext;
handles.MinSpVal = log(min(min(sp)));
handles.MaxSpVal = log(max(max(sp)));
guidata(hObject,handles);
handles=guidata(hObject);

vtmp = get(handles.MinSpecValSlider,'Value');
%handles.SPECTH=exp(handles.MinSpVal+vtmp*(handles.MaxSpVal-handles.MinSpVal));
handles.SPECTH=vtmp*((2^8)-1);

vtmp = get(handles.MaxSpecValSlider,'Value');
%handles.MAXSPECTH=exp(handles.MinSpVal+vtmp*(handles.MaxSpVal-handles.MinSpVal));
handles.MAXSPECTH=vtmp*((2^8)-1);

if (handles.MAXSPECTH<=handles.SPECTH)
    %handles.MAXSPECTH = exp(handles.MaxSpVal);
    set(handles.MaxSpecValSlider,'Value',get(handles.MaxSpecValSlider,'Max'));
end

%handles.MinSpVal = min(min(sp));
%handles.MaxSpVal = max(max(sp));
%guidata(hObject,handles);
%handles=guidata(hObject);
%vtmp=(handles.SPECTH-handles.MinSpVal)./(handles.MaxSpVal-handles.MinSpVal);
%if (vtmp>1)
%    vtmp = 1.0;
%end
%if (vtmp<0)
%    vtmp=0.0;
%end
%set(handles.MinSpecValSlider,'Value',vtmp);

%look for .not.mat file
[tmp1,tmp2,tmpext]=fileparts(FNAME);
if (exist([FNAME,'.not.mat'],'file'))
    load([FNAME,'.not.mat']);
    onsets=onsets*1e-3;
    offsets=offsets*1e-3;
elseif ((strcmp(tmpext,'.filt')) & (exist([FNAME(1:end-4),'not.mat'],'file')))
		load([FNAME(1:end-4),'not.mat']);
		onsets=onsets*1e-3;
		offsets=offsets*1e-3;
else
    %recdata=readrecf(FNAME);
    %if (isfield(recdata,'adfreq'))
    %	    Fs = recdata.adfreq;
    %end
    min_int=handles.MININT;
    min_dur=handles.MINDUR;
    threshold=handles.SEGTH;
    sm_win=handles.SM_WIN;
    sm(1)=0.0;sm(end)=0.0;
    [onsets,offsets]=SegmentNotes(sm,Fs,min_int,min_dur,threshold);
    labels = char(ones([1,length(onsets)])*fix('-'));
    %ONSETS AND OFFSETS COME IN SECONDS NOT MS!
end
handles.SMOOTHDATA = sm;
handles.ONSETS=onsets;
handles.OFFSETS=offsets;
handles.SEGTH=threshold;
handles.MININT=min_int;
handles.MINDUR=min_dur;
handles.LABELS=labels;
handles.SM_WIN=sm_win;
handles.FS = Fs;

guidata(hObject,handles);

if (length(onsets)==0)
    onsets=[t(1)];offsets=[t(end)];labels=['-'];
end

%% plot the smooth power
dsamp=handles.SMUNDERSAMPLE;
axes(handles.SmoothAxes);
hold off;
semilogy( ...  # plot filt rec smoothed audio
    [1:length(sm(1:dsamp:end))] * dsamp/double(Fs), ...
    sm(1:dsamp:end), ...
    LineStyle='-', ...
    Color='#bdbdbd' ...  # gray
    );
hold on;

%% plot spectrogram
axes(handles.SpecGramAxes);hold off;

%%%%%%%%%% change for caxis version %%%%%%%%%%
%pp = find(sp<=handles.SPECTH);
%sptemp = sp;sptemp(pp) = handles.SPECTH;
%pp = find(sptemp>=handles.MAXSPECTH);
%sptemp(pp) = handles.MAXSPECTH;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sptemp=log(sp);
sptemp = sptemp - min(sptemp, [], 'all');
sptemp = uint8(((2^8) - 1)*(sptemp./max(max(sptemp)))); % SAVE SOME MEMORY 8X less than 64 bit double

SPECT_HNDL=image(t,f,sptemp);
set(gca,'YD','n');
m=colormap;
set(SPECT_HNDL,'CDataMapping','Scaled');
axis([t(1) t(end) 0 1e4]);vv=axis;

vtmpmin = get(handles.MinSpecValSlider,'Value');
vtmpmax = get(handles.MaxSpecValSlider,'Value');

caxis(((2^8)-1)*[vtmpmin,vtmpmax]);
    
handles.OrigAxis = vv;
clear sptemp;
spectitle=FNAME;
title(RemoveUnderScore(spectitle));

%%
handles = replotSegments(handles);
guidata(hObject,handles);

if (get(handles.HighLightBtn,'Value')==get(handles.HighLightBtn,'Max'))
    pp=findstr(labels,get(handles.HighLightNoteBox,'string'));
    for ii=1:length(pp)
        set(handles.LABELTAGS(pp(ii)),'Color','b');
    end
end
% PJ: Plot intan trigs -- for multiple input channels 7.15.19 EK
C = {'r', 'c', 'g', 'm'};
if exist('trig','var')
    for chan = 1 : nChan
        axes(handles.LabelAxes); hold on;
        scatter(trig{chan}.locsT,-1.5.*ones(1,length(trig{chan}.locsT)), 30, C{chan}, 'filled', '^');
        hold off;drawnow;
    end
end

drawnow;

%if it is a catch trial put that in the box
if strcmp(ext,'') %Krank file
    rdata = [];
else
    rdata=readrecf(FNAME);
end

if (~isfield(rdata,'ttimes'))
    rdata.ttimes=[];
end

if (length(rdata)>0)
    if (isfield(rdata,'iscatch'))
        if (rdata.iscatch)
            set(handles.CatchTrialBox,'Value',get(handles.CatchTrialBox,'Max'));
        else
            set(handles.CatchTrialBox,'Value',get(handles.CatchTrialBox,'Min'));
        end
    end
    
    % put marker at trigger times
    if (get(handles.ShowTrigBox,'Value')==get(handles.ShowTrigBox,'Max'))
            axes(handles.LabelAxes);hold on;
            for ii=1:length(rdata.ttimes)
                plot(rdata.ttimes(ii)*1e-3,-1.5,'b^');
                if rdata.catch(ii)==1
                    plot(rdata.ttimes(ii)*1e-3,-1.5,'r^');
                end;
            end
            hold off;drawnow;
    end
else
    rdata.ttimes=[];
end

set(hObject,'Interruptible','on');
set(hObject,'BusyAction','Queue');

%save sp, fs, labels
handles.SPECGRAMVALS = sp;
handles.SPECT_HNDL=SPECT_HNDL;
handles.TIMEVALS = t;
handles.FREQVALS = f;
handles.FS = Fs;
handles.LABELS = labels;
handles.ONSETS = onsets;
handles.OFFSETS = offsets;
handles.MININT=min_int;
handles.MINDUR=min_dur;
handles.SEGTH=threshold;
handles.SM_WIN=sm_win;
handles.TRIGTIMES=rdata.ttimes*1e-3;
guidata(hObject,handles);
return;


function OutString=RemoveUnderScore(InString);
    % replaces all _ with \_ for proper display
    
    TmpStr=InString;
    pos = findstr(InString,'_');
    for ind=1:length(pos)
        indu = pos(ind);
        if (indu==1)
            TmpStr=['\',TmpStr];
        else
            TmpStr = [TmpStr(1:(indu-1)),'\',TmpStr(indu:end)];
        end
        pos = pos + 1;
    end
    OutString=TmpStr;
    return;