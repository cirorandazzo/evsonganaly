function replotSegments(hObject)
% plot segmented syllables as points with line between them
% separated out by CDR 2024.08 - was previously in like 4 separate places
% in the code??

handles = guidata(hObject);

n_notes = length(handles.ONSETS);

assert( n_notes == length(handles.OFFSETS) & n_notes == length(handles.LABELS))

segs = zeros([n_notes, 3]);
colors = lines(n_notes);

axes(handles.SmoothAxes);  % select wave axes
hold on;

to_clear = ["SEG_HNDL"  % current segments
    "EditBndLines"];  % remove lines from 'edit'. may not exist

for i=to_clear
    % may not exist, so need this in try block
    try
        delete(handles.(i));
    catch
    end
end
handles.EditBndLines=[];

guidata(hObject, handles);

for ii = 1:n_notes
    mstyle = '|';
    msize = 30;
    lstyle = '-.';
    lw=1.5;
    color = colors(ii, :);

    % onset point
    segs(ii,1) = plot(handles.ONSETS(ii), handles.SEGTH, 'Marker', mstyle, 'Color', color, 'MarkerSize', msize);

    % offset point
    segs(ii,2) = plot(handles.OFFSETS(ii), handles.SEGTH, 'Marker', mstyle, 'Color', color, 'MarkerSize', msize);

    % line between points
    segs(ii,3) = line( ...
        [handles.ONSETS(ii), handles.OFFSETS(ii)], ...
        [1,1] * handles.SEGTH, ...
        'Color', color, ...
        'LineStyle', lstyle, ...
        'LineWidth', lw ...
        );
end
hold off
% save segment annotations
handles.SEG_HNDL = reshape(segs,[numel(segs),1]);

% labels centered between onset/offset.
% TODO: decide how to show interrupting notes
axes(handles.LabelAxes);
hold on;

set(gca,'XTick',[],'YTick',[]);

if isfield(handles, 'LABELTAGS')
    delete(handles.LABELTAGS);
end

handles.LABELTAGS = text( ...
    handles.ONSETS, ... % (handles.ONSETS + handles.OFFSETS) .* 0.5, ...
    zeros([n_notes,1]), ...
    handles.LABELS.' ...
    );

% normalize label axis
vv=axis;
axis([vv(1:2),-2,1]);

hold off;
guidata(hObject, handles);
return
