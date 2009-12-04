function data = leaveoneout(data)

dimtok = tokenize(data.dimord, '_');
rptdim = find(strcmp('rpt', dimtok)); % the selected dimension as number

if length(rptdim)<1
  error('the "%s" dimension is not present in the data', avgdim);
elseif length(rptdim)>1
  error('cannot jackknife over multiple dimensions at the same time');
elseif rptdim~=1
  error('jackknife only works if replicates are in the first dimension of the data');
end

reduceddim = dimlength(data);
reduceddim(rptdim) = 1;

param = selparam(data);
for i=1:length(param)
  fprintf('computing jackknife %s\n', param{i});
  tmp    = data.(param{i});
  nrpt   = size(tmp, rptdim);
  sumtmp = reshape(nansum(tmp, rptdim), reduceddim);
  for k = 1:nrpt
    tmp(k,:,:,:,:,:,:) = (sumtmp - tmp(k,:,:,:,:,:,:))./(nrpt-1);
  end  
  data.(param{i}) = tmp;
end

data.method = 'jackknife';
