function [data,fs]=ReadCbinFile(fname);
%[data,fs]=ReadCbinFile(fname);
%

if (exist(fname,'file'))
    fid=fopen(fname,'r','b');
    RData=fread(fid,inf,'short');
    fclose(fid);

    % load evtaf defaults
    fs = 32000.000;
    Nchan = 2;
    Ndata = floor(length(RData)/Nchan);

    pos = strfind(fname,'.cbin');
    if (length(pos)==0)
        pos = strfind(fname,'.bbin');
    end
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
        warning(['Data size does not match REC file-',...
            'Returning EMPTY MATRIX!']);
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