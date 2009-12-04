function multiplotCC(cfg, data)

% MULTIPLOTCC visualiuzes the coherence between channels by using multiple
% topoplots. The topoplot at a given channel location shows the coherence
% of that channel with all other channels.
%
% Use as
%   multiplotCC(cfg, data)

% Undocumented local options:
% cfg.layout  = layout filename or a structure produced by prepare_layout
% cfg.xlim
% cfg.xparam
% cfg.zparam
% This function requires input from FREQSTATISTICS_SHIFTPREDICT
% This function should be rewritten, using the clean topoplot implementation

% Copyright (C) 2005-2006, Jan-Mathijs Schoffelen, Robert Oostenveld
%
% Subversion does not use the Log keyword, use 'svn log <filename>' or 'svn -v log | less' to get detailled information

fieldtripdefs

if ~isfield(cfg, 'layout'),    cfg.layout = 'CTF151s.lay';       end;
if ~isfield(cfg, 'xparam'),    cfg.xparam = 'foi';               end;
if ~isfield(cfg, 'xlim'),      cfg.xlim   = 'all';               end;
if ~isfield(cfg, 'zparam'),    cfg.zparam = 'avg.icohspctrm';    end;

% for backward compatibility with old data structures
data = checkdata(data);

if strcmp(cfg.zparam, 'avg.icohspctrm') && ~issubfield(data, 'avg.icohspctrm'),
  data.avg.icohspctrm = abs(imag(data.avg.cohspctrm));
end

if strcmp(data.dimord, 'refchan_chan_freq'),
  %reshape input-data, such that topoplotER will take it
  cnt = 1;
  siz = size(data.prob);
  data.labelcmb = cell(siz(1)*siz(2),2);
  data.prob = reshape(data.prob, [siz(1)*siz(2) siz(3)]);
  data.stat = reshape(data.stat, [siz(1)*siz(2) siz(3)]);
  for j = 1:length(data.label)
    for k = 1:length(data.reflabel)
      data.labelcmb(cnt,:) = [data.reflabel(k) data.label(j)];
      cnt = cnt + 1;
    end
  end
  tmpdata = data;
else
  dat   = getsubfield(data, cfg.zparam);
  scale = [0 max(dat(:))-0.2];
end

if isfield(cfg, 'xparam'),
  xparam = getsubfield(data, cfg.xparam);
  if ~strcmp(cfg.xlim, 'all'),
    fbin = [nearest(xparam, cfg.xlim(1)) nearest(xparam, cfg.xlim(2))];
  else
    fbin = [xparam(1) xparam(end)];
  end
end

[chNum,X,Y,Width,Height,Lbl] = textread(cfg.layout,'%f %f %f %f %f %s');

xScaleFac = 1/(max(Width)+ max(X) - min(X));
yScaleFac = 1/(max(Height)+ max(Y) - min(Y));


Xpos = xScaleFac*(X-min(X));
Ypos = 0.9*yScaleFac*(Y-min(Y));

for k=1:length(chNum) - 2
  subplotOL('position',[Xpos(k) Ypos(k)+(Height(k)*yScaleFac) Width(k)*xScaleFac*2 Height(k)*yScaleFac*2])
  config.layout     = cfg.layout;
  if exist('tmpdata'),

    config.style      = 'straight';
    config.electrodes = 'off';
    config.hlinewidth  = 0.5;
    try, config.refmarker = strmatch(Lbl(k), data.reflabel);
    catch, config.refmarker  = strmatch(Lbl(k), data.label); end
    config.maplimits  = [0 0.5];
    config.ecolor     = [1 1 1];
    config.interplimits = 'electrodes';
    if isfield(cfg, 'xparam'),
      config.xparam = cfg.xparam;
      config.xlim   = xparam;
    else
      config.xparam = 'time';
      config.xlim   = [k-0.5 k+0.5];
    end
    config.zparam = cfg.zparam;
    config.cohrefchannel = Lbl(k);
    config.showxlim = 'no';
    config.showzlim = 'no';
    config.colorbar = 'no';
    config.zlim     = scale;
    config.grid_scale = 30;
    topoplotER(config, data);
    drawnow;
  end
end


