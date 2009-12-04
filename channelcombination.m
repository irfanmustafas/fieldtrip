function [collect] = channelcombination(channelcmb, datachannel, includeauto)

% CHANNELCOMBINATION creates a cell-array with combinations of EEG/MEG
% channels for subsequent cross-spectral-density and coherence analysis
%
% You should specify channel combinations as a two-column cell array,
%   cfg.channelcmb = {  'EMG' 'MLF31'
%                       'EMG' 'MLF32'
%                       'EMG' 'MLF33' };
% to compare EMG with these three sensors, or
%   cfg.channelcmb = { 'MEG' 'MEG' };
% to make all MEG combinations, or
%   cfg.channelcmb = { 'EMG' 'MEG' };
% to make all combinations between the EMG and all MEG channels.
%
% For each column, you can specify a mixture of real channel labels
% and of special strings that will be replaced by the corresponding
% channel labels. Channels that are not present in the raw datafile
% are automatically removed from the channel list.
%
% See also CHANNELSELECTION

% Undocumented local options:
% optional third input argument includeauto, specifies to include the 
% auto-combinations

% Copyright (C) 2003-2006, Robert Oostenveld
%
% Subversion does not use the Log keyword, use 'svn log <filename>' or 'svn -v log | less' to get detailled information

fieldtripdefs

if nargin==2,
  includeauto = 0;
end

if ischar(channelcmb) && strcmp(channelcmb, 'all')
  % make all possible combinations of all channels
  channelcmb = {'all' 'all'};
end

% it should have a selection of two channels or channelgroups in each row
if size(channelcmb,1)==2 && size(channelcmb,2)~=2
  warning('transposing channelcombination matrix');
end

% this will hold the output
collect = {};

if isempty(setdiff(channelcmb(:), datachannel))
  % there is nothing to do, since there are no channelgroups with special names
  % each element of the input therefore already contains a proper channel name
  collect = channelcmb;

else
  % a combination is made for each row of the input selection after
  % translating the channel group (such as 'all') to the proper channel names
  % and within each set, double occurences and autocombinations are removed

  for sel=1:size(channelcmb,1)
    % translate both columns and subsequently make all combinations
    channelcmb1 = channelselection(channelcmb(sel,1), datachannel);
    channelcmb2 = channelselection(channelcmb(sel,2), datachannel);

    % compute indices of channelcmb1 and channelcmb2 relative to datachannel
    [dum,indx,indx1]=intersect(channelcmb1,datachannel);
    [dum,indx,indx2]=intersect(channelcmb2,datachannel);

    % remove double occurrences of channels in either set of signals
    indx1   = unique(indx1);
    indx2   = unique(indx2);

    % create a matrix in which all possible combinations are set to one
    cmb = zeros(length(datachannel));
    for ch1=1:length(indx1)
      for ch2=1:length(indx2)
        cmb(indx1(ch1),indx2(ch2))=1;
      end
    end
    
    % remove auto-combinations
    cmb = cmb & ~eye(size(cmb));
    
    % remove double occurences
    cmb = cmb & ~tril(cmb, -1)';
    
    [indx1,indx2] = find(cmb);

    % extend the previously allocated cell-array to also hold the new
    % channel combinations (this is done to prevent memory allocation and
    % copying in each iteration in the for-loop below)
    num = size(collect,1);               % count the number of existing combinations
    dum = cell(num + length(indx1), 2);  % allocate space for the existing+new combinations
    if num>0
      dum(1:num,:) = collect(:,:);       % copy the exisisting combinations into the new array
    end
    collect = dum;
    clear dum

    % convert to channel-names
    for ch=1:length(indx1)
      collect{num+ch,1}=datachannel{indx1(ch)};
      collect{num+ch,2}=datachannel{indx2(ch)};
    end
  end
  
  if includeauto
    cmb           = eye(length(datachannel));
    [indx1,indx2] = find(cmb);
    num           = size(collect,1);
    dum           = cell(num + length(indx1), 2);
    if num>0,
      dum(1:num,:) = collect(:,:);
    end
    collect = dum;
    clear dum
  
    % convert to channel-names for the auto-combinations
    for ch=1:length(indx1)
      collect{num+ch,1} = datachannel{indx1(ch)};
      collect{num+ch,2} = datachannel{indx2(ch)};
    end
  end
end
