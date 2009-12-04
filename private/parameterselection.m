function [select] = parameterselection(param, data);

% PARAMETERSELECTION selects the parameters that are present as a volume in the data
% add that have a dimension that is compatible with the specified dimensions of the
% volume, i.e. either as a vector or as a 3D volume.
%
% Use as
%   [select] = parameterselection(param, data)
% where
%   param    cell-array, or single string, can be 'all'
%   data     structure with anatomical or functional data
%   select   returns the selected parameters as a cell-array

% Copyright (C) 2005-2008, Robert oostenveld
%
% Subversion does not use the Log keyword, use 'svn log <filename>' or 'svn -v log | less' to get detailled information

if ischar(param)
  param = {param};   % it should be a cell-array
elseif isempty(param)
  param = {};        % even being empty, it should be a cell-array
end

sel = find(strcmp(param, 'all'));
if ~isempty(sel)
  % the old default was a list of all known volume parameters
  % the new default is to try all fields present in the data
  allparam = fieldnames(data);
  % fields can be nested in source.avg
  if isfield(data, 'avg')
    tmp = fieldnames(data.avg);
    for i=1:length(tmp)
      tmp{i} = ['avg.' tmp{i}];
    end
    allparam = cat(1, allparam, tmp);
  end
  % fields can be nested in source.trial
  if isfield(data, 'trial')
    tmp = fieldnames(data.trial);
    for i=1:length(tmp)
      tmp{i} = ['trial.' tmp{i}];
    end
    allparam = cat(1, allparam, tmp);
  end
  param(sel) = [];                          % remove the 'all'
  param      = [param(:)' allparam(:)'];    % add the list of all possible parameters, these will be tested later
else
  % check all specified parameters and give support for some parameters like 'pow' and 'coh'
  % which most often will indicate 'avg.pow' and 'avg.coh'
  for i=1:length(param)
    if ~issubfield(data, param{i}) && issubfield(data, ['avg.' param{i}])
      % replace the parameter xxx by avg.xxx
      param{i} = ['avg.' param{i}];
    end
  end
end

% remove empty fields
param(find(cellfun('isempty', param))) = [];

% ensure that there are no double entries
param = unique(param);

select = {};
for i=1:length(param)
  if issubfield(data, param{i})
    % the field is present, check whether the dimension is correct
    dim = size(getsubfield(data, param{i}));
    if isfield(data, 'dim') && isequal(dim(:), data.dim(:))
      select{end+1} = param{i}; 
    elseif isfield(data, 'dim') && prod(dim)==prod(data.dim)
      select{end+1} = param{i}; 
    elseif isfield(data, 'pos') && prod(dim)==size(data.pos, 1)
      select{end+1} = param{i}; 
    end
  end
end

