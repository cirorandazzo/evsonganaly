function varargout = evsonganaly(varargin)
% EVSONGANALY M-file for evsonganaly.fig
%      EVSONGANALY, by itself, creates a new EVSONGANALY or raises the existing
%      singleton*.
%
%      H = EVSONGANALY returns the handle to a new EVSONGANALY or the handle to
%      the existing singleton*.
%
%      EVSONGANALY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EVSONGANALY.M with the given input arguments.
%
%      EVSONGANALY('Property','Value',...) creates a new EVSONGANALY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before evsonganaly_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to evsonganaly_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright 2002-2003 The MathWorks, Inc.

% Edit the above text to modify the response to help evsonganaly

% Last Modified by GUIDE v2.5 12-Oct-2023 16:34:53
% CDR added audio playback functionality 2023.10.12 

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @evsonganaly_OpeningFcn, ...
                   'gui_OutputFcn',  @evsonganaly_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
return;

% --- Executes just before evsonganaly is made visible.
function evsonganaly_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to evsonganaly (see VARARGIN)

% Choose default command line output for evsonganaly
handles.output = hObject;

% get the structure array of input files
[INPUTFILES,ChanSpec,FilterType]=evloadfile;
if (isempty(INPUTFILES))
    errordlg('No Input Files Found!');
    delete(handles.EVSONGANAL);
    return;
end
handles.filter_type=FilterType;
handles.INPUTFILES=INPUTFILES;
handles.ChanSpec=ChanSpec;
handles.NFILE=1;
handles.SPECTH=0.01;
handles.SEGTH=10000;
handles.MININT=5.0;%in msec
handles.MINDUR=30.0;%in msec
handles.SM_WIN=2.0;
handles.CurLabelInd = 0;
handles.DOLABEL=0;
handles.DOEDIT=0;
handles.EditBndLines=-1;
handles.EditBnds=-1;
handles.SMUNDERSAMPLE=10;%undersample factor for smooth display - speeds everything up
guidata(hObject, handles);handles=guidata(hObject);

%setup 2^8 element colormap
axes(handles.SpecGramAxes);
colormap(rand([2^8,3])); % lol its a random colormap, is this just to preallocate?
colormap('bone');

%link the x axes
linkaxes([handles.SpecGramAxes,handles.LabelAxes,handles.SmoothAxes],'x');

%take care of intial contrast settings
set(handles.MaxSpecValSlider,'Value',1.0);
set(handles.MinSpecValSlider,'Value',0.67);

%defualt to show the trig times
set(handles.ShowTrigBox,'Value',get(handles.ShowTrigBox,'Max'));

% do first file
while (1)
    fname = handles.INPUTFILES(handles.NFILE).fname;
    if (exist(fname,'file'))
        break;
    else
        handles.NFILE=handles.NFILE+1;
    end
    if (handles.NFILE>=length(handles.INPUTFILES))
        errordlg('No Input Files Found!');
        delete(handles.EVSONGANAL);
        return;
    end
end

PlotDataFile(hObject,handles);
handles=guidata(hObject);

% setup some defaults for the GUI
set(handles.PrevFileBtn,'Value',get(handles.PrevFileBtn,'Min'));
set(handles.NextFileBtn,'Value',get(handles.NextFileBtn,'Min'));
set(handles.ResegBtn,'Value',get(handles.ResegBtn,'Min'));
set(handles.SngleNoteLbl,'Value',get(handles.SngleNoteLbl,'Min'));

%get initial zoom setting right
zoom xon;
set(handles.XZoomBtn,'Value',get(handles.XZoomBtn,'Max'));

uiwait(handles.EVSONGANAL);
return;

% --- Outputs from this function are returned to the command line.
function varargout = evsonganaly_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(handles.EVSONGANAL);
return;

% --- Executes on button press in NextFileBtn.
function NextFileBtn_Callback(hObject, eventdata, handles)
% hObject    handle to NextFileBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of NextFileBtn

%SAVE DATA TO NOTMAT FILES
SaveNotMatData(hObject,handles);

while (1)
	handles.NFILE=handles.NFILE+1;
	if (handles.NFILE>length(handles.INPUTFILES))
		handles.NFILE=length(handles.INPUTFILES);
		errordlg('That was the last file there''s no going forward!');
		break;
	end
	if (exist(handles.INPUTFILES(handles.NFILE).fname,'file'))
		break;
	end
end
set(handles.NextFileBtn,'Value',get(handles.NextFileBtn,'Min'));
guidata(hObject,handles);

handles=guidata(hObject);
DisableBtns(hObject,handles);
handles=guidata(hObject);

PlotDataFile(hObject,handles);

handles=guidata(hObject);
EnableBtns(hObject,handles);
handles=guidata(hObject);

if (~isempty(handles.ONSETS))
	handles.CurLabelInd = 1;
else
	handles.CurLabelInd = 0;
end
guidata(hObject,handles);
handles=guidata(hObject);
SetLabelingOff(hObject,handles);

return;

function DisableBtns(hObject,handles)
% turn off control btns during plotting
set(handles.PrevFileBtn,'Enable','off');
set(handles.NextFileBtn,'Enable','off');
set(handles.SkipToFileBtn,'Enable','off');
set(handles.NextFileBtn,'Enable','off');
guidata(hObject,handles);
return;

function EnableBtns(hObject,handles)
% turn on control btns after plotting
set(handles.PrevFileBtn,'Enable','on');
set(handles.NextFileBtn,'Enable','on');
set(handles.SkipToFileBtn,'Enable','on');
set(handles.NextFileBtn,'Enable','on');
guidata(hObject,handles);
return;

% --- Executes on button press in PrevFileBtn.
function PrevFileBtn_Callback(hObject, eventdata, handles)
% hObject    handle to PrevFileBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Save data to notmat file
SaveNotMatData(hObject,handles);

while (1)
	handles.NFILE=handles.NFILE-1;
	if (handles.NFILE<1)
		handles.NFILE=1;
		errordlg('This is the first file there''s no going back!');
		break;
	end
	if (exist(handles.INPUTFILES(handles.NFILE).fname,'file'))
		break;
	end
end
set(handles.PrevFileBtn,'Value',get(handles.PrevFileBtn,'Min'));
guidata(hObject,handles);

handles=guidata(hObject);
DisableBtns(hObject,handles);
handles=guidata(hObject);

PlotDataFile(hObject,handles);

handles=guidata(hObject);
EnableBtns(hObject,handles);


handles=guidata(hObject);
SetLabelingOff(hObject,handles);

if (~isempty(handles.ONSETS))
	handles.CurLabelInd = 1;
else
	handles.CurLabelInd = 0;
end
guidata(hObject,handles);

return;


% --- Executes on button press in QuitBtn.
function QuitBtn_Callback(hObject, eventdata, handles)
% hObject    handle to QuitBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Save data to notmat file
SaveNotMatData(hObject,handles);
uiresume(handles.EVSONGANAL);
return;

% --- Executes on button press in XZoomBtn.
function XZoomBtn_Callback(hObject, eventdata, handles)
% hObject    handle to XZoomBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of XZoomBtn

if (get(handles.LabelBtn,'Value')==get(handles.LabelBtn,'Max'))
    SetLabelingOff(hObject, handles);
end

val = get(handles.XZoomBtn,'Value');
if (val==get(handles.XZoomBtn,'Max'))
    zoom xon;
else
    zoom off;
end
return;


% --- Executes on button press in LabelBtn.
function LabelBtn_Callback(hObject, eventdata, handles)
% hObject    handle to LabelBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of LabelBtn
%set(handles.EVSONGANAL,'Selected','On');
%set(handles.SpecGramAxes,'Selected','On');

if (get(handles.LabelBtn,'Value')==get(handles.LabelBtn,'Max'))
    % turn zoom off
    zoom off;
    set(handles.XZoomBtn,'Value',get(handles.XZoomBtn,'Min'));
    handles.DOLABEL=1;
else
    zoom xon;
    set(handles.XZoomBtn,'Value',get(handles.XZoomBtn,'Max'));
    handles.DOLABEL=0;
end
guidata(hObject,handles);
handles=guidata(hObject);

curlabelind = handles.CurLabelInd;
txtlbl = handles.LABELTAGS;
if (handles.DOLABEL)
    axes(handles.SpecGramAxes);
    vv=axis;
    
    
    ResetLabelInd(hObject,handles,vv);
    handles=guidata(hObject);
    %FOCUS????
else
    SetLabelingOff(hObject, handles);
end
return;

% --- Executes on key press over EVSONGANAL with no controls selected.
function EVSONGANAL_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to EVSONGANAL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%get(hObject,'CurrentCharacter')
%get(hObject,'SelectionType')


newlabel = get(hObject,'CurrentCharacter');
newlabelfix = fix(newlabel);
if ((newlabelfix>=49)&&(newlabelfix<=51))
    if (newlabelfix==49)
        set(hObject,'SelectionType','normal');
    elseif (newlabelfix==50)
        set(hObject,'SelectionType','extend');
    else
        set(hObject,'SelectionType','alt');
    end
    EVSONGANAL_WindowButtonDownFcn(hObject, eventdata, handles);
    return;
end

%For Labeling
if (handles.DOLABEL)
    %onsets = handles.ONSETS; offsets = handles.OFFSETS;
    curlabelind = handles.CurLabelInd;
    txtlbl = handles.LABELTAGS;

    %axes(handles.SpecGramAxes);
    vv=axis;
    dXAxis = vv(2)-vv(1);

    newlabel = get(hObject,'CurrentCharacter');
    newlabelfix = fix(newlabel);
    
    if (newlabelfix == 27)
        % ESC has been hit - quit out
        SetLabelingOff(hObject, handles);
        return;
    elseif ((newlabelfix == 8)||(newlabelfix == 28))
        %backspace/back arrow
        if (curlabelind>0)
            set(txtlbl(curlabelind),'Color',[0,0,0]);
            curlabelind=curlabelind-1;
            if (curlabelind<1)
                curlabelind=1;
            end
            set(txtlbl(curlabelind),'Color',[1,0,0]);
            handles.CurLabelInd=curlabelind;
            guidata(hObject,handles);

            if (curlabelind>1)
                lblpos = get(txtlbl(curlabelind),'Position');
                if (lblpos(1)<=vv(1))
                    axes(handles.SpecGramAxes);
                    axis([[vv(1:2) - 0.8*dXAxis],vv(3:4)]);
                end
            end
        else
            if ((vv(2)-0.8*dXAxis)>0)
                axis([[vv(1:2) - 0.8*dXAxis],vv(3:4)]);
            end
        end
    elseif (newlabelfix == 29) %forward arrow
        if (curlabelind>0)
            set(txtlbl(curlabelind),'Color',[0,0,0]);
            curlabelind=curlabelind+1;
            if (curlabelind>length(txtlbl))
                curlabelind=length(txtlbl);
            end
            set(txtlbl(curlabelind),'Color',[1,0,0]);
            handles.CurLabelInd=curlabelind;
            guidata(hObject,handles);

            if (curlabelind<=length(txtlbl))
                lblpos = get(txtlbl(curlabelind),'Position');
            end
            if (lblpos(1)>vv(2))
                axes(handles.SpecGramAxes);
                axis([[vv(1:2) + 0.8*dXAxis],vv(3:4)]);
            end
        else
            if ((vv(1)+0.8*dXAxis)<handles.OrigAxis(2))
                axis([[vv(1:2) + 0.8*dXAxis],vv(3:4)]);
            end
        end
    elseif (newlabelfix == 30) % up arrow
        if (curlabelind>0)
		    set(txtlbl(curlabelind),'Color',[0,0,0]);
        end
        pp=find(handles.ONSETS>vv(2));
        if (~isempty(pp))
            curlabelind=pp(1);
            set(txtlbl(curlabelind),'Color',[1,0,0]);
            axis([vv(2),(vv(2)+dXAxis),vv(3:4)]);
        else
            curlabelind=0;
            axis([vv(2),(vv(2)+dXAxis),vv(3:4)]);
        end
        handles.CurLabelInd=curlabelind;
        guidata(hObject,handles);
    elseif (newlabelfix == 31) %down arrow
        if (curlabelind>0)
		    set(txtlbl(curlabelind),'Color',[0,0,0]);
        end
        pp=find(handles.OFFSETS<vv(1));
        if (length(pp)>0)
            curlabelind=pp(end);
            set(txtlbl(curlabelind),'Color',[1,0,0]);
            axis([vv(1)-dXAxis,vv(1),vv(3:4)]);
        else
            curlabelind=0;
            axis([vv(1)-dXAxis,vv(1),vv(3:4)]);
        end
        handles.CurLabelInd=curlabelind;
        guidata(hObject,handles);
    else
        if (curlabelind>0)
            if (length(newlabel>0))
                set(txtlbl(curlabelind),'String',newlabel);
                %waitfor(txtlbl(curlabelind),'String',newlabel);
                handles.LABELS(curlabelind) = newlabel;
                set(txtlbl(curlabelind),'Color',[0,0,0]);
                curlabelind = curlabelind + 1;
                if (curlabelind>length(txtlbl))
                    curlabelind = length(txtlbl);
                end
                set(txtlbl(curlabelind),'Color',[1,0,0]);
                handles.CurLabelInd=curlabelind;
                guidata(hObject,handles);

                if (curlabelind<=length(txtlbl))
                    lblpos = get(txtlbl(curlabelind),'Position');
                    if (lblpos(1)>=vv(2))
                        axes(handles.SpecGramAxes);
                        axis([[vv(1:2) + 0.8*dXAxis],vv(3:4)]);
                    end
                end
            end
        end
    end
    if (curlabelind>0)
        lblpos = get(txtlbl(curlabelind),'Position');
        vv=axis;
        if (~((lblpos(1)>=vv(1))&&(lblpos(1)<=vv(2))))
            axis([[lblpos(1)+[-0.5,0.5]*dXAxis],vv(3:4)]);
        end
    end
% For Editing
elseif (handles.DOEDIT)
    onsets = handles.ONSETS;
    offsets = handles.OFFSETS;
    labels = handles.LABELS;
    editfunc = get(hObject,'CurrentCharacter');
    editfuncfix = fix(editfunc);
        
    axes(handles.SmoothAxes);
    vv=axis;
    
    lns = handles.EditBndLines;
    lnsval = handles.EditBnds;

    if (editfuncfix == 27)
        % ESC has been hit - quit out do nothing
        set(handles.EditBtn,'Value',get(handles.EditBtn,'Min'));
        EditBtn_Callback(hObject, [], handles);
        handles=guidata(hObject);
        return;
    elseif (editfuncfix==13)
        % return was hit
        
        % is either endpoint inside an interval
        pp = find((onsets<=lnsval(1))&(offsets>=lnsval(1)));
        if (length(pp)==1)
            lnsval(1) = onsets(pp);
        end
        pp = find((onsets<=lnsval(2))&(offsets>=lnsval(2)));
        if (length(pp)==1)
            lnsval(2) = offsets(pp);
        end
        
        % find all the intervals between the endpoints
        pp = find((onsets>=lnsval(1))&(offsets<=lnsval(2)));
        if (length(pp)>0)
            onsets(pp(1))  = lnsval(1);
            offsets(pp(1)) = lnsval(2);
            if (length(pp)>1)
                onsets(pp(2:end))  = [];
                offsets(pp(2:end)) = [];
                labels(pp(2:end))  = [];
            end
        else
            % this is a new non overlapping interval
            pp = find(offsets<=lnsval(1));
            if (length(pp)==0)
                if (length(onsets)<1)
                    % no intervals to begin with
                    onsets = lnsval(1);
                    offsets = lnsval(2);
                    labels = '-';
                else
                    onsets  = [lnsval(1);onsets];
                    offsets = [lnsval(2);offsets];
                    labels  = ['-',labels];
                end
            else
                pp = pp(end);
                if (pp==length(onsets))
                    onsets  = [onsets;lnsval(1)];
                    offsets = [offsets;lnsval(2)];
                    labels  = [labels,'-'];
                else
                    onsets  = [onsets(1:pp); lnsval(1);onsets(pp+1:end)];
                    offsets = [offsets(1:pp);lnsval(2);offsets(pp+1:end)];
                    labels  = [labels(1:pp),'-',labels(pp+1:end)];
                end
            end
        end
    elseif ((editfuncfix==100)||(editfuncfix==68))
        % 'd' was hit for delete
        
        %find all the intervals which are totally inside the bounds
        pp = find((onsets>=lnsval(1))&(offsets<=lnsval(2)));
        if (length(pp)>0)
            onsets(pp)  = [];
            offsets(pp) = [];
            labels(pp)  = [];
        end
        
        % find any intervals which contain one or both of the bounds inside
        pp1 = find((onsets<=lnsval(1))&(offsets>=lnsval(1)));
        pp2 = find((onsets<=lnsval(2))&(offsets>=lnsval(2)));
        if ((length(pp1)==1)&&(length(pp2)==1))
            if (pp1==pp2)
               % clipping out piece from a single segment to make 2 new
               % segments
               if (pp1<length(onsets))
                   onsets = [onsets(1:pp1);lnsval(2);onsets(pp1+1:end)];
                   labels = [labels(1:pp1),labels(pp1),labels(pp1+1:end)];
               else
                   onsets = [onsets(1:pp1);lnsval(2)];
                   labels = [labels(1:pp1),labels(pp1)];
               end
               
               if (pp1>1)
                   offsets = [offsets(1:pp1-1);lnsval(1);offsets(pp1:end)];
               else
                   offsets = [lnsval(2);offsets(1:end)];
               end
            else
                % both intervals overlap but not on the same segment
                offsets(pp1) = lnsval(1);
                onsets(pp2) = lnsval(2);
            end
        elseif (length(pp1)==1)
            offsets(pp1) = lnsval(1);
        elseif (length(pp2)==1)
            onsets(pp1) = lnsval(2);
        end
    elseif ((editfuncfix==99)||(editfuncfix==67))
        % 'c' was hit for crop
        
        %find all the intervals which are totally inside the bounds
        pp = find((offsets<lnsval(1))|(onsets>lnsval(2)));
        if (length(pp)>0)
            onsets(pp)  = [];
            offsets(pp) = [];
            labels(pp)  = [];
        end
    end

    handles.LABELS = labels;
    handles.ONSETS = onsets;
    handles.OFFSETS = offsets;
    guidata(hObject,handles);
    handles=guidata(hObject);
    axes(handles.SmoothAxes);
    delete(handles.EditBndLines);
    handles.EditBndLines=[];
    vv=axis;
    hold on;
    threshold=handles.SEGTH;
    Fs = handles.FS;
    %semilogy([1:length(handles.SMOOTHDATA)]/Fs,handles.SMOOTHDATA,'b-');hold on;
    delete(handles.SEG_HNDL);
    segs = zeros([length(onsets),3]);
    for ii = 1:length(onsets)
        segs(ii,1)=plot(onsets(ii),threshold,'k+');
        segs(ii,2)=plot(offsets(ii),threshold,'k+');
        segs(ii,3)=plot([onsets(ii),offsets(ii)],[1,1]*threshold,'k-');
    end
    axis(vv);
    handles.SEG_HNDL=reshape(segs,[numel(segs),1]);
    
    meantimes=(onsets+offsets).*0.5;
    axes(handles.LabelAxes);
    delete(handles.LABELTAGS);
    handles.LABELTAGS=text(meantimes,zeros([length(meantimes),1]),labels.');
    axis([vv(1:2),-2,1]);
    set(gca,'XTick',[],'YTick',[]);
    guidata(hObject,handles);
    handles=guidata(hObject);
    drawnow;
    
    set(handles.EditBtn,'Value',get(handles.EditBtn,'Min'));
    EditBtn_Callback(hObject, eventdata, handles);
    handles=guidata(hObject);
else
    %IF ITS NOT IN LABEL or EDIT MODE
    cmd = get(hObject,'CurrentCharacter');
    %START LABELING
    if (strcmp(lower(cmd),'l'))
        set(handles.LabelBtn,'Value',get(handles.LabelBtn,'Max'));
        LabelBtn_Callback(hObject, eventdata, handles);
    end
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SetLabelingOff(hObject, handles);
% stops labeling, sets all characters to black
set(handles.LabelBtn,'Value',get(handles.LabelBtn,'Min'));
handles.DOLABEL=0;
if (handles.CurLabelInd>0)
    set(handles.LABELTAGS(handles.CurLabelInd),'Color',[0,0,0]);
end
handles.CurLabelInd = 0;
guidata(hObject,handles);
zoom xon;
set(handles.XZoomBtn,'Value',get(handles.XZoomBtn,'Max'));
set(handles.SngleNoteLbl,'Value',get(handles.SngleNoteLbl,'Min'));
return;

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function EVSONGANAL_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to EVSONGANAL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SType=get(hObject,'SelectionType');
axisvals = get(handles.SpecGramAxes,'Position');

MousePos = get(hObject,'CurrentPoint');
onsets = handles.ONSETS; offsets = handles.OFFSETS;

if (get(handles.XZoomBtn,'Value')==get(handles.XZoomBtn,'Min'))
    zoomon=0;
else
    zoomon=1;
end

axes(handles.SpecGramAxes);
vv=axis;
dXAxis = vv(2)-vv(1);
slopev = dXAxis./axisvals(3);
interv = axisvals(1);

XVal = (MousePos(1)-axisvals(1))*slopev + vv(1);
WASAXISRESET=0;
if (((handles.DOLABEL)||(zoomon==0))&&(~handles.DOEDIT))
    %Resest the axis to the Mouse pos if needed
    axes(handles.SpecGramAxes);
    vv=axis;
    
    if ((XVal>=vv(2))||(strcmp(SType,'alt')))
        axis([vv(1:2)+0.8*dXAxis,vv(3:4)]);
        vv = axis;
        XVal = vv(1);
        WASAXISRESET=1;
    elseif (XVal<=vv(1))
        axis([vv(1:2)-0.8*dXAxis,vv(3:4)]);
        vv = axis;
        XVal = vv(1);
        WASAXISRESET=1;
    else
        if ((zoomon==0)&&(~handles.DOLABEL))
            axis([XVal-0.5*dXAxis,XVal+0.5*dXAxis,vv(3:4)]);
        end
        
    end
end

if ((handles.DOLABEL==1)||(handles.DOLABEL==2))
    vv=axis;
    curlabelind = handles.CurLabelInd;
    txtlbl = handles.LABELTAGS;

    % pick the new current label
    labelpos = find(offsets>=XVal);
    if (curlabelind>0)
        set(txtlbl(curlabelind),'Color',[0,0,0]);
    end
    curlabelind=0;
    if (~isempty(labelpos))
        if ((onsets(labelpos(1))>=vv(1))&&(onsets(labelpos(1))<=vv(2)))
            curlabelind = labelpos(1);
            if ((curlabelind>0)&&(curlabelind<=length(txtlbl)))
                set(txtlbl(curlabelind),'Color',[1,0,0]);
            else
                curlabelind=0;
            end
        end
    end

    handles.CurLabelInd = curlabelind;
    guidata(hObject,handles);
    if (handles.DOLABEL==2)
        loweraxislim = get(handles.SmoothAxes,'Position');
        if ((WASAXISRESET==0)&&(MousePos(2)>=loweraxislim(2)))
            vv=axis;
            curlabelind = handles.CurLabelInd;
            txtlbl = handles.LABELTAGS;
            if (strcmp(SType,'normal'))
                newlabel = get(handles.SnglNoteLblVal,'String');
            else
                newlabel = get(handles.SnglNoteLblVal2,'String');
            end
            %if (length(newlabel)>0)
            %    newlabel=newlabel(1);
            %end
            if ((curlabelind>0)&&(~isempty(newlabel)))
                for ijk=0:(length(newlabel)-1)
                    if ((ijk+curlabelind)<=length(txtlbl))
                        set(txtlbl(curlabelind+ijk),'String',newlabel(ijk+1));
                        handles.LABELS(curlabelind+ijk) = newlabel(ijk+1);
                    end
                end

                set(txtlbl(curlabelind),'Color',[0,0,0]);
                curlabelind = min([curlabelind + length(newlabel),length(txtlbl)]);
                set(txtlbl(curlabelind),'Color',[1,0,0]);
                handles.CurLabelInd=curlabelind;
                guidata(hObject,handles);

                if (curlabelind<=length(txtlbl))
                    lblpos = get(txtlbl(curlabelind),'Position');
                    if (lblpos(1)>=vv(2))
                        axes(handles.SpecGramAxes);
                        axis([ vv(1:2) + 0.8*dXAxis,vv(3:4)]);
                    end
                end
            end
        end
    end
elseif (handles.DOEDIT)
    btntype = get(gcf, 'SelectionType');
    if strcmp(btntype,'open')
        btnval = 1;
    elseif strcmp(btntype,'normal')
        btnval = 1;
    elseif strcmp(btntype,'extend')
        btnval = 2;
    elseif strcmp(btntype,'alt')
        btnval = 3;
    else
        % what did you press?
        btnval = 0;
    end

    axes(handles.SmoothAxes);
    vv=axis;
    
    lns = handles.EditBndLines;
    lnsval = handles.EditBnds;
    if (btnval==1)
        % left button
        delete(lns(1));
        tmp = plot([1,1]*XVal,vv(3:4),'r--');
        lns(1) = tmp;
        lnsval(1) = XVal;
    elseif (btnval==3)
        % right button
        delete(lns(2));
        tmp = plot([1,1]*XVal,vv(3:4),'r--');
        lns(2) = tmp;
        lnsval(2) = XVal;
    elseif (btnval==2)
        % middle btn
        % sets boundaries to the note cliked on
        pp=find(onsets<XVal);
        if (length(pp)>1)
            pp = pp(end);
            if ((XVal>=onsets(pp))&&(XVal<=offsets(pp)))
                % if you clicked right in the middle of one note
                %it chooses that note as the bounds
                delete(lns);
                tmp1 = plot([1,1]*onsets(pp),vv(3:4),'r--');
                tmp2 = plot([1,1]*offsets(pp),vv(3:4),'r--');
                lns = [tmp1,tmp2];
                lnsval = [onsets(pp),offsets(pp)];
            elseif (pp<length(onsets))
                if ((XVal>=onsets(pp))&&(XVal<=offsets(pp+1)))
                    delete(lns);
                    tmp1 = plot([1,1]*onsets(pp),vv(3:4),'r--');
                    tmp2 = plot([1,1]*offsets(pp+1),vv(3:4),'r--');
                    lns = [tmp1,tmp2];
                    lnsval = [onsets(pp),offsets(pp+1)];
                end
            end
        end
    end  
    
    handles.EditBndLines = lns;
    handles.EditBnds = lnsval;
    guidata(hObject,handles);
end
return;

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function EVSONGANAL_ButtonUpFcn(hObject, eventdata, handles)
% hObject    handle to EVSONGANAL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%MousePos = get(hObject,'CurrentPoint')
return;


% --- Executes on button press in UnZoomX.
function UnZoomX_Callback(hObject, eventdata, handles)
% hObject    handle to UnZoomX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

axes(handles.SpecGramAxes);
axis(handles.OrigAxis);
return;


% --- Executes on button press in MoveAxisLeft.
function MoveAxisLeft_Callback(hObject, eventdata, handles)
% hObject    handle to MoveAxisLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.SpecGramAxes);
vv=axis;
dXAxis = vv(2)-vv(1);
axis([vv(1:2)-dXAxis*0.8,vv(3:4)]);
vv=axis;
if (handles.DOLABEL)
    ResetLabelInd(hObject,handles,vv);
end

return;

% --- Executes on button press in MoveAxisRight.
function MoveAxisRight_Callback(hObject, eventdata, handles)
% hObject    handle to MoveAxisRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

axes(handles.SpecGramAxes);
vv=axis;
dXAxis = vv(2)-vv(1);
axis([vv(1:2)+dXAxis*0.8,vv(3:4)]);
vv=axis;
if (handles.DOLABEL)
    ResetLabelInd(hObject,handles,vv);
end
return;

function ResetLabelInd(hObject,handles,vv);
% sets the current label to the first one in the axes

curlabelind = handles.CurLabelInd;

txtlbl  = handles.LABELTAGS;
onsets  = handles.ONSETS;
offsets = handles.OFFSETS;

if (curlabelind>0)
    set(txtlbl(curlabelind),'Color',[0,0,0]);
end

labelpos = find((onsets>vv(1))&(onsets<vv(2)));
if (length(labelpos)>0)
    curlabelind = labelpos(1);
    set(txtlbl(curlabelind),'Color',[1,0,0]);
else
    curlabelind = 0;
end
handles.CurLabelInd = curlabelind;
guidata(hObject,handles);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SaveNotMatData(hObject,handles);
% save data to the not.mat file
Fs = handles.FS;
fname  = handles.INPUTFILES(handles.NFILE).fname;
[tmp1,tmp2,tmpext]=fileparts(fname);
	
labels  = handles.LABELS;
onsets  = handles.ONSETS*1e3; %put into ms
offsets = handles.OFFSETS*1e3;%put into ms
min_int = handles.MININT;
min_dur = handles.MINDUR;
threshold = handles.SEGTH;
sm_win = handles.SM_WIN;
filename = strsplit(fname, '/');
if (strcmp(tmpext,'.filt'))
	cmd = ['save ',filename{end},'.not.mat fname Fs labels '...
		' min_dur min_int offsets onsets sm_win threshold'];
else
	cmd = ['save ',filename{end},'.not.mat fname Fs labels min_dur min_int ',...
                      'offsets onsets sm_win threshold'];
end
eval(cmd);
return;


% --- Executes on button press in DeleteFileBtn.
function DeleteFileBtn_Callback(hObject, eventdata, handles)
% hObject    handle to DeleteFileBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

NODOT = 0;
fname  = handles.INPUTFILES(handles.NFILE).fname;
[pth,fnm,ext]=fileparts(fname);
if (strcmp(handles.FILEEXT,'.wav'))
	if (~strcmp(ext,'.wav'))
		fnm = [fnm,ext];
		NODOT = 1;
	end
end

pth=[pth,filesep];
if (NODOT == 0)
qreply=questdlg(['Do you want to delete the files :',pth,fnm,'*'],...
                'File Deletion Warning','Yes','Cancel','Cancel');
else
qreply=questdlg(['Do you want to delete the files :',pth,fnm],...
                'File Deletion Warning','Yes','Cancel','Cancel');
end
if (strcmp(qreply,'Yes'))
	if (NODOT==1)
		delete([pth,fnm]);
	else
		pp = findstr(fnm,ext);
		if (length(pp)>0)
			delete([pth,fnm(1:pp(end)),'*']);
        else
			delete([pth,fnm,'.*']);
		end
	end

	handles.INPUTFILES(handles.NFILE)=[];
	if (handles.NFILE>length(handles.INPUTFILES))
		handles.NFILE = length(handles.INPUTFILES);
	end
	guidata(hObject,handles);
	PlotDataFile(hObject,handles);
	handles=guidata(hObject);

	if (length(handles.ONSETS)>0)
		handles.CurLabelInd = 1;
	else
		handles.CurLabelInd = 0;
	end
	guidata(hObject,handles);
	handles=guidata(hObject);
	SetLabelingOff(hObject,handles);
end
return;

% --- Executes on button press in SkipToFileBtn.
function SkipToFileBtn_Callback(hObject, eventdata, handles)
% hObject    handle to SkipToFileBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[tmpout,isCancel] = SkipToFile(handles.INPUTFILES,handles.NFILE);
if (~isCancel)
    SaveNotMatData(hObject,handles);
    
	handles.NFILE=tmpout;
	guidata(hObject,handles);

	PlotDataFile(hObject,handles);
	handles=guidata(hObject);

	if (length(handles.ONSETS)>0)
		handles.CurLabelInd = 1;
	else
		handles.CurLabelInd = 0;
	end
	guidata(hObject,handles);
	handles=guidata(hObject);
	SetLabelingOff(hObject,handles);
end
return;


% --- Executes on button press in CropDataBtn.
function CropDataBtn_Callback(hObject, eventdata, handles)
% hObject    handle to CropDataBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% takes 2 data point for x and y from the specgram window and only keeps
% the data in between the two markers, saves the files back out
%zoom off;
%set(handles.XZoomBtn,'Value',get(handles.XZoomBtn,'Min'));%
%
%axes(handles.SpecGramAxes);
%[x,y]=ginput(2);
%xx = sort(x);x=xx;

%sp_sz = size(handles.SPECGRAMVALS);

%inds = floor(x*fs);
%if (inds(1)<1)
%    inds(1) = 1;
%end

%if (inds(2)>sp_sz(2))
%    inds(2) = sp_sz(2);
%end

%axes(handles.SpecGramAxes);vv=axis;
%axis([inds,vv(3:4)]);

%qreply=questdlg(['Does this look right for cropping? :',pth,fnm,'.*'],...
%                'File Crop Warning','Yes','Cancel','Cancel');
%if (strcmp(qreply,'Yes'))
 %   sptmp = handles.SPECGRAMVALS;
  %  sptmp = sptmp(:,[inds(1):inds(2)]);
   % handles.SPECGRAMVALS = sptmp;
   % clear sptmp;
    
   % fname=handles.INPUTFILES(handles.NFILE).fname;
   % [dat,fs]=ReadDataFile(fname,-1);
   % dat = dat(inds(1):inds(2),:);
   % fid2=fopen(fname,'w','b');
   % fwrite(fid2,dat,'float');
   % fclose(fid2);
    
   % recdata=readrecf(fname);
   % recdata.ttimes = recdata.ttimes-((inds(1)-1)/fs)
   % recdata.nsamp = size(dat,1);
   % wrtrecf(fname,recdata);
%end

%return;


% --- Executes on button press in ResegmBtn.
function ResegmBtn_Callback(hObject, eventdata, handles)
% hObject    handle to ResegmBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

tmpstruct.mindur = handles.MINDUR;
tmpstruct.minint = handles.MININT;
tmpstruct.segth  = handles.SEGTH;
tmpstruct.sm_win = handles.SM_WIN;

tmpstruct = ChangeSettings(tmpstruct);
if (tmpstruct.DOIT)
    handles.MINDUR=tmpstruct.mindur;
    handles.MININT=tmpstruct.minint;
    handles.SEGTH =tmpstruct.segth;
    handles.SM_WIN=tmpstruct.sm_win;
    guidata(hObject,handles);
    
    fname=handles.INPUTFILES(handles.NFILE).fname;
    %recdata=readrecf(fname);
    Fs = handles.FS;
    min_int=handles.MININT;
    min_dur=handles.MINDUR;
    threshold=handles.SEGTH;
    sm_win=handles.SM_WIN;

    %chanspec=handles.ChanSpec;
    %[dat,Fs]=ReadDataFile(fname,chanspec);
    sm=handles.SMOOTHDATA;
    sm(1)=0.0;sm(end)=0.0;

    [onsets,offsets]=SegmentNotesJC(sm,Fs,min_int,min_dur,threshold);
    labels = char(ones([1,length(onsets)])*fix('-'));

    handles.ONSETS=onsets;
    handles.OFFSETS=offsets;
    handles.SEGTH=threshold;
    handles.MININT=min_int;
    handles.MINDUR=min_dur;
    handles.LABELS=labels;
    handles.SM_WIN=sm_win;
    handles.FS = Fs;
    guidata(hObject,handles);
    handles=guidata(hObject);

    axes(handles.SmoothAxes);
    delete(handles.SEG_HNDL);
    %hold off;
    vv=axis;
    %semilogy([1:length(sm)]/Fs,sm,'b-');hold on;
    segs = zeros([length(onsets),3]);
    for ii = 1:length(onsets)
        segs(ii,1)=plot(onsets(ii),threshold,'k+');
        segs(ii,2)=plot(offsets(ii),threshold,'k+');
        segs(ii,3)=line([onsets(ii),offsets(ii)],[1,1]*threshold,'Color',[0,0,0]);
    end
    lltmp = length(sm);
    inds = [fix(0.2*lltmp):fix(0.8*lltmp)];
    inds = find(sm>0);
    mntmp = 10.^floor(log10(min(sm(inds))));
    mxtmp = 10.^ceil(log10(max(sm(inds))));
    axis([vv(1:2) mntmp mxtmp]);

    meantimes=(onsets+offsets).*0.5;
    axes(handles.LabelAxes);
    delete(handles.LABELTAGS);
    handles.LABELTAGS=text(meantimes,zeros([length(meantimes),1]),labels.');
    axis([vv(1:2),-2,1]);
    drawnow;

    handles.SEG_HNDL=reshape(segs,[numel(segs),1]);
    guidata(hObject,handles);
    
    %SaveNotMatData(hObject,handles); <-WHY WAS THIS HERE?
    
    if (get(handles.XZoomBtn,'Value')==get(handles.XZoomBtn,'Max'))
        zoom xon;
    else
        zoom off;
    end
end
return;


% --- Executes on button press in CropBtn.
function CropBtn_Callback(hObject, eventdata, handles)
% hObject    handle to CropBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if labeling was on
if (get(handles.LabelBtn,'Value')==get(handles.LabelBtn,'Max'))
    SetLabelingOff(hObject, handles);
end

% if zoom was on
zoom off;
if (get(handles.XZoomBtn,'Value')==get(handles.XZoomBtn,'Max'))
    set(handles.XZoomBtn,'Value',get(handles.XZoomBtn,'Min'));
end

axes(handles.SpecGramAxes);hold on;
axis(handles.OrigAxis);
vv=axis;
lims = vv(1:2);
p1=plot([1,1]*lims(1),vv(3:4),'k--');  
p2=plot([1,1]*lims(2),vv(3:4),'k--');set([p1,p2],'LineW',3);

while (1)
    [x,y,btn]=ginput(1);
    
    if (length(btn)==0)
        break;
    end
    
    % hit escape to end
    if (btn==27)
        break;
    end
    
    if (btn==1)
        if ((x<lims(2))&(x>0))
            lims(1) = x;
            delete(p1);
            p1=plot([1,1]*lims(1),vv(3:4),'k--');set(p1,'LineW',3);
        end
    end
    
    if (btn==3)
        if ((x>lims(1))&(x<vv(2)))
            lims(2) = x;
            delete(p2);
            p2=plot([1,1]*lims(2),vv(3:4),'k--');set(p2,'LineW',3);
        end
    end
end

qreply=questdlg(['Do you want to crop this file at these boundaries?'],...
    'File Crop Warning','Yes','Cancel','Cancel');
if (strcmp(qreply,'Yes'))
    fname = handles.INPUTFILES(handles.NFILE).fname;
    if (~strcmp(handles.FILEEXT,'.wav'))|(~strcmp(handles.ChanSpec,'w'))
	    rdata = readrecf(fname);
    
	    if (~isfield(rdata,'nchan'))
		    nchan = 2;
	    else
		    nchan = rdata.nchan;
	    end
    else
	    nchan = 1;
    end
    
    [dat,fs,ext]=ReadDataFile(fname,'',1);
    
    ilim = floor(lims*fs)+1;
    if (ilim(1)<1)
        ilim(1) = 1;
    end
    if (ilim(2)>size(dat,1))
        ilim(2) = size(dat,1);
    end
    
    dat = dat(ilim(1):ilim(2),:);
    
    if (~strcmp(handles.FILEEXT,'.wav'))
	    rdata.nsamp = size(dat,1);
	    ttimes = rdata.ttimes*1e-3;
	    ttimes = ttimes(find((ttimes>lims(1))&(ttimes<lims(2))));
	    ttimes = ttimes - lims(1);
	    ttimes = ttimes(find(ttimes>=0));
	    rdata.ttimes = ttimes*1e3;
    
	    if (isfield(rdata,'tbefore'))
		    tbefore = rdata.tbefore;
		    tbefore = tbefore - lims(1);
		    rdata.tbefore = tbefore;
	    end
    
	    if (isfield(rdata,'tafter'))
		    tafter = rdata.tafter;
		    tafter = tafter - (vv(2)-lims(2));
		    rdata.tafter = tafter;
	    end
    
	    wrtrecf(fname,rdata);
    end
    
    [pth,nm,ext]=fileparts(fname);
    if (length(ext)==0)
        ext = '.wav';
    end
    
    if (strcmp(ext,'.wav'))
        wavwrite(dat,fs,16,fname);
    elseif (strcmp(ext,'.ebin'))
        tdat = zeros([size(dat,1)*size(dat,2),1]);
        for ijk = 1:nchan
            tdat(ijk:nchan:end) = dat(:,ijk);
        end

        fid=fopen(fname,'w','b');
        fwrite(fid,tdat,'float');
        fclose(fid);
    elseif ((strcmp(ext,'.cbin')|strcmp(ext,'.bbin')))
        tdat = zeros([size(dat,1)*size(dat,2),1]);
        for ijk = 1:nchan
            tdat(ijk:nchan:end) = dat(:,ijk);
        end
        
        fid=fopen(fname,'w','b');
        fwrite(fid,tdat,'short');
        fclose(fid);
    end
    clear dat;
    
    onsets = handles.ONSETS;offsets=handles.OFFSETS;labels = handles.LABELS;
    lpos = find((onsets>=lims(1))&(offsets<=lims(2)));
    onsets = onsets(lpos)-lims(1);
    offsets = offsets(lpos)-lims(1);
    labels = labels(lpos);
    handles.ONSETS = onsets;handles.OFFSETS = offsets;handles.LABELS=labels;
    guidata(hObject,handles);
    SaveNotMatData(hObject,handles);
    DIDNEW = 1;
else
    zoom xon;
    set(handles.XZoomBtn,'Value',get(handles.XZoomBtn,'Min'));
    DIDNEW = 0;
end

delete(p1);delete(p2);
hold off;    

% reload and plot it
clear tdat;
if (DIDNEW == 1)
    PlotDataFile(hObject, handles);
end
zoom xon;
set(handles.XZoomBtn,'Value',get(handles.XZoomBtn,'Min'));
return;


% --- Executes on button press in EditBtn.
function EditBtn_Callback(hObject, eventdata, handles)
% hObject    handle to EditBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of EditBtn


if (get(handles.EditBtn,'Value')==get(handles.EditBtn,'Max'))
    %turn labeling off if it is on
    if (handles.DOLABEL~=0)
        SetLabelingOff(hObject, handles);
        handles=guidata(hObject);
    end
    
    % turn zoom off
    zoom off;
    set(handles.XZoomBtn,'Value',get(handles.XZoomBtn,'Min'));
    
    handles.DOEDIT=1;
    
    axes(handles.SmoothAxes);
    vv=axis;
    hold on;
    p1=plot([1,1]*vv(1),vv(3:4),'r--');
    p2=plot([1,1]*vv(2),vv(3:4),'r--');
    handles.EditBndLines = [p1,p2];
    handles.EditBnds = vv(1:2);
    set(gcf,'pointer','crosshair');
else
    axes(handles.SmoothAxes);
    if (length(handles.EditBndLines)>1)
        delete(handles.EditBndLines);
    end
    handles.EditBndLines=-1;
    handles.EditBnds=-1;
    handles.DOEDIT=0;

    set(gcf,'pointer','arrow');
    axes(handles.SpecGramAxes);
    zoom xon;
    
    set(handles.XZoomBtn,'Value',get(handles.XZoomBtn,'Max'));
    if (get(handles.HighLightBtn,'Value')==get(handles.HighLightBtn,'Max'))
        pp=findstr(handles.LABELS,get(handles.HighLightNoteBox,'string'));
        for ii=1:length(pp)
            set(handles.LABELTAGS(pp(ii)),'Color','b');
        end
    end


end
guidata(hObject,handles);
%handles=guidata(hObject);
return;


% --- Executes on slider movement.
function MinSpecValSlider_Callback(hObject, eventdata, handles)
% hObject    handle to MinSpecValSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

%vtmp = get(handles.MinSpecValSlider,'Value');
%vtmp = handles.MinSpVal+vtmp*(handles.MaxSpVal-handles.MinSpVal);
%vtmp = exp(vtmp);

vtmpmin = get(handles.MinSpecValSlider,'Value');
vtmpmax = get(handles.MaxSpecValSlider,'Value');

if (vtmpmin>vtmpmax)
    vtmpmin=vtmpmax-1e-10;
    set(handles.MinSpecValSlider,'Value',vtmpmax);
end
handles.SPECTH=vtmpmin*((2^8)-1);
axes(handles.SpecGramAxes);
caxis(((2^8)-1)*[vtmpmin,vtmpmax]);

%if (vtmp>=handles.MAXSPECTH)
%    set(handles.MinSpecValSlider,'Value',get(handles.MaxSpecValSlider,'Value'));
%end

%sptemp = handles.SPECGRAMVALS;
%pp = find(sptemp<=handles.SPECTH);sptemp(pp)=handles.SPECTH;
%pp = find(sptemp>=handles.MAXSPECTH);sptemp(pp)=handles.MAXSPECTH;

%top freqs already taken out
%sptemp=log(sptemp);sptemp = sptemp - min(min(sptemp));
%sptemp = uint8(2^8*(sptemp./max(max(sptemp)))); % SAVE SOME MEMORY 8X less than 64 bit double

%set(handles.SPECT_HNDL,'CData',sptemp);

%axes(handles.SpecGramAxes);
%vv=axis;hold off;
%imagesc(handles.TIMEVALS,handles.FREQVALS,log(sptemp));
%set(gca,'YDir','normal');axis(vv);
%spectitle=handles.INPUTFILES(handles.NFILE).fname;

guidata(hObject,handles);
if (get(handles.XZoomBtn,'Value')==get(handles.XZoomBtn,'Max'))
    zoom xon;
end
drawnow;
return;

% --- Executes during object creation, after setting all properties.
function MinSpecValSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MinSpecValSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
return;

% --- Executes on slider movement.
function MaxSpecValSlider_Callback(hObject, eventdata, handles)
% hObject    handle to MaxSpecValSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

%vtmp = get(handles.MaxSpecValSlider,'Value');
%vtmp = handles.MinSpVal + vtmp*(handles.MaxSpVal-handles.MinSpVal);
%vtmp = exp(vtmp);

vtmpmin = get(handles.MinSpecValSlider,'Value');
vtmpmax = get(handles.MaxSpecValSlider,'Value');

if (vtmpmax<vtmpmin)
    vtmpmax=vtmpmin+1e-10;
    set(handles.MaxSpecValSlider,'Value',vtmpmax);
end
handles.MAXSPECTH=vtmpmax*((2^8)-1);
axes(handles.SpecGramAxes);
caxis(((2^8)-1)*[vtmpmin,vtmpmax]);

%sptemp = handles.SPECGRAMVALS;
%pp = find(sptemp<=handles.SPECTH);sptemp(pp)=handles.SPECTH;
%pp = find(sptemp>=handles.MAXSPECTH);sptemp(pp)=handles.MAXSPECTH;

%top freqs already taken out
%sptemp=log(sptemp);sptemp = sptemp - min(min(sptemp));
%sptemp = uint8(2^8*(sptemp./max(max(sptemp)))); % SAVE SOME MEMORY 8X less than 64 bit double

%set(handles.SPECT_HNDL,'CData',sptemp);

guidata(hObject,handles);
if (get(handles.XZoomBtn,'Value')==get(handles.XZoomBtn,'Max'))
    zoom xon;
end
drawnow;
return;

% --- Executes during object creation, after setting all properties.
function MaxSpecValSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MaxSpecValSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
return;

% --- Executes on button press in CatchTrialBox.
function CatchTrialBox_Callback(hObject, eventdata, handles)
% hObject    handle to CatchTrialBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CatchTrialBox

return;

function SnglNoteLblVal_Callback(hObject, eventdata, handles)
% hObject    handle to SnglNoteLblVal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SnglNoteLblVal as text
%        str2double(get(hObject,'String')) returns contents of SnglNoteLblVal as a double
return;

% --- Executes during object creation, after setting all properties.
function SnglNoteLblVal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SnglNoteLblVal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'String','a');

return;

% --- Executes on button press in SngleNoteLbl.
function SngleNoteLbl_Callback(hObject, eventdata, handles)
% hObject    handle to SngleNoteLbl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SngleNoteLbl

if (get(handles.SngleNoteLbl,'Value')==get(handles.SngleNoteLbl,'Max'))
    if (handles.DOLABEL==0)
        set(handles.LabelBtn,'Value',get(handles.LabelBtn,'Max'));
        guidata(hObject,handles);
        handles=guidata(hObject);
        LabelBtn_Callback(hObject, [], handles);
    end
    handles.DOLABEL=2;
else
    handles.DOLABEL=1;
end
guidata(hObject,handles);
return;


% --- Executes on button press in CancelBtn.
function CancelBtn_Callback(hObject, eventdata, handles)
% hObject    handle to CancelBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%don't save and quit
uiresume(handles.EVSONGANAL);
return;


% --- Executes on button press in ShowTrigBox.
function ShowTrigBox_Callback(hObject, eventdata, handles)
% hObject    handle to ShowTrigBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ShowTrigBox

return;

function SnglNoteLblVal2_Callback(hObject, eventdata, handles)
% hObject    handle to SnglNoteLblVal2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SnglNoteLblVal2 as text
%        str2double(get(hObject,'String')) returns contents of SnglNoteLblVal2 as a double

return;

% --- Executes during object creation, after setting all properties.
function SnglNoteLblVal2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SnglNoteLblVal2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;


% --- Executes on button press in HighLightBtn.
function HighLightBtn_Callback(hObject, eventdata, handles)
% hObject    handle to HighLightBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of HighLightBtn

if (get(handles.HighLightBtn,'Value')==get(handles.HighLightBtn,'Max'))
    pp=findstr(handles.LABELS,get(handles.HighLightNoteBox,'string'));
    for ii=1:length(pp)
        set(handles.LABELTAGS(pp(ii)),'Color','b');
    end
end
return;


function HighLightNoteBox_Callback(hObject, eventdata, handles)
% hObject    handle to HighLightNoteBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of HighLightNoteBox as text
%        str2double(get(hObject,'String')) returns contents of HighLightNoteBox as a double


% --- Executes during object creation, after setting all properties.
function HighLightNoteBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to HighLightNoteBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in PlayAudioFullBtn.
function PlayAudioFullBtn_Callback(hObject, eventdata, handles)
    % when PlayAudioFullBtn button is pressed, plays the audio shown in the
    % spectrogram
    % CDR 2023.10.12

    nfile = handles.NFILE;
    fName = handles.INPUTFILES(nfile).fname;

    playCbinFile(fName, 0, inf, handles); % play whole clip
    


return

% --- Executes on button press in PlayAudioSegBtn.
function PlayAudioSegBtn_Callback(hObject, eventdata, handles)
    % hObject    handle to PlayAudioSegBtn (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % line selecting code copied from CropBtn_Callback
    % CDR 2023.10.13

    % TODO: add something like 'labeling mode' so you cant start a bunch of
    % these at once (oops)

    % if labeling was on

    if (get(handles.LabelBtn,'Value')==get(handles.LabelBtn,'Max'))
        SetLabelingOff(hObject, handles);
    end
    
    % if zoom was on
    zoom off;
    if (get(handles.XZoomBtn,'Value')==get(handles.XZoomBtn,'Max'))
        set(handles.XZoomBtn,'Value',get(handles.XZoomBtn,'Min'));
    end
    
    
    axis(handles.OrigAxis);
    vv=axis;

    [lims, p1, p2] = windowSelect(vv, handles.SpecGramAxes);


    % lims is of form [L_boundary, R_boundary], each in seconds of
    % recording

    nfile = handles.NFILE;
    fName = handles.INPUTFILES(nfile).fname;

    playCbinFile(fName, lims(1), lims(2), handles);

    while (get(hObject,'Value')==1) % can also end by clicking toggle button again
        % [~,~,button] = ginput(1);
        k = waitforbuttonpress;
        button = double(get(gcf,'CurrentCharacter'))

        if button==32 %spacebar
            playCbinFile(fName, lims(1), lims(2), handles);
        elseif button==27 %escape
            break;
        end
    end

    set(hObject, 'Value',0); % reset button
    delete(p1);
    delete(p2);
    return

function [lims, p1, p2] = windowSelect(vv, currentAxes)
    % prompt for 2 vertical lines, left with L mouse button and right
    % with R mouse button.
    % vv: 4-element array with axis [left boundary, right boundary, 
    % bottom boundary, top boundary
    % 
    % CDR 2023.10.13

    axes(currentAxes);hold on;

    linestyle = 'k--';
    linew = 3;

    % start with lines at the limits
    p1=plot([1,1]*vv(1),vv(3:4), linestyle);  
    p2=plot([1,1]*vv(2),vv(3:4), linestyle);
    set([p1,p2],'LineW',linew);

    lims = vv(1:2); % to store new limits

    % draw boundaries, one with L mouse button one with R mouse button
    while (1)  % only break out of loop once esc or space are hit
        [x,y,btn]=ginput(1);
        
        if (isempty(btn))
            break;
        end
        
        % hit escape or space to end
        if (btn==27 || btn==32)
            break;
        end
        
        if (btn==1)
            if ((x<vv(2))&(x>0))
                lims(1) = x;
                delete(p1);
                p1=plot([1,1]*lims(1),vv(3:4),linestyle);
                set(p1,'LineW',linew);
            end
        end
        
        if (btn==3)
            if ((x>vv(1))&(x<vv(2)))
                lims(2) = x;
                delete(p2);
                p2=plot([1,1]*lims(2),vv(3:4),linestyle);
                set(p2,'LineW',linew);
            end
        end
    end

    return


function playCbinFile(fName, t0, tf, handles)
    % play a cbin file to default audio output, from t0 to tf (in seconds).
    disp(append("Playing audio for file: ", fName));
    [y, fs] = ReadCbinFile(fName);
    y = rescale(y,-1,1);  % rescale, otherwise there's clipping

    l = length(y); %length in samples

    %convert times to samples. +1 is because you're converting from 0 index
    %(seconds) to 1 index (matlab indexing)
    s0 = (t0*fs)+1;
    sf = (tf*fs)+1;

    % check that indices are within range
    if ~(s0>=0 && s0<sf && s0<(l-1))
        s0=1;
    end

    if ~(sf<=l && sf>t0)
        sf=l;
    end

    y=y(s0:sf);

    player = audioplayer(y,fs);
    % playblocking(player);
    play(player);

    % prep play tracking line
    axes(handles.SpecGramAxes);hold on;
    axis(handles.OrigAxis);
    vv=axis; % limits of current axis

    
    while (isplaying(player))
        % get sample/timestamp
        si = get(player, 'CurrentSample');
        ti = (si-1)/fs + t0; % convert to time. add t0 to account for offset

        % delete old line & plot new
        
        
        line=plot([1,1]*ti,vv(3:4),'w',...
            'LineW',3);

        pause(0.01)
        delete(line)

        % check for esc
        
    end

    hold off;

    return


%% HELPERS

function wrtrecf(fname,recdata,ADDX)
    %wrtrecf(fname,recdata,ADDX);
    % wrtrecf(fname,recdata);
    % recdata is a structure with all the rec file fields
    
    if (~exist('ADDX'))
        ADDX=0;
    else
        if (length(ADDX)==0)
            ADDX=0;
        end
    end
    
    pp = findstr(fname,'.rec');
    if (length(pp)<1)
        pp2 = findstr(fname,'.');
        if (length(pp2)<1)
            recf = [fname,'.rec'];
        else
            recf = [fname(1:pp2(end)),'rec'];
        end
    else
        recf = fname;
    end
    
    if (ADDX==1)
        pptmp=findstr(recf,'.rec');
        recf=[recf(1:pptmp(end)-1),'X.rec'];
    end
    
    fid = fopen(recf,'w');
    if (isfield(recdata,'header'))
        for ii=1:length(recdata.header)
            fprintf(fid,'%s\n',recdata.header{ii});
        end
        fprintf(fid,'\n');
    end
    
    if (isfield(recdata,'adfreq'))
        fprintf(fid,'ADFREQ = %12.7e\n',recdata.adfreq);
    end
    
    if (isfield(recdata,'outfile'))
        fprintf(fid,'Output Sound File =%s\n',recdata.outfile);
    end
    
    if (isfield(recdata,'nchan'))
        fprintf(fid,'Chans = %d\n',recdata.nchan);
    end
    
    if (isfield(recdata,'nsamp'))
        fprintf(fid,'Samples = %d\n',recdata.nsamp);
    end
    
    if (isfield(recdata,'iscatch'))
        fprintf(fid,'Catch = %d\n',recdata.iscatch);
    end
    
    if (isfield(recdata,'tbefore'))
        fprintf(fid,'T BEFORE = %12.7e\n',recdata.tbefore);
    end
    
    if (isfield(recdata,'tafter'))
        fprintf(fid,'T AFTER = %12.7e\n',recdata.tafter);
    end
    
    if (isfield(recdata,'thresh'))
        fprintf(fid,'THRESHOLDS = ');
        for ii = 1:length(recdata.thresh)
                fprintf(fid,'\n%15.7e',recdata.thresh(ii));
        end
    end
    fprintf(fid,'\n');
    
    if (isfield(recdata,'ttimes'))
        %fprintf(fid,'Trigger times = ');
        fprintf(fid,'Feedback information:\n\n');
    
        for ii = 1:length(recdata.ttimes)
            if (recdata.ttimes(ii)>=0)
                fprintf(fid,'\n%15.7e msec : FB',recdata.ttimes(ii));
            end
        end
    end
    fclose(fid);
    return;    