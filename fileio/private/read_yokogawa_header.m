function hdr = read_yokogawa_header(filename);


% READ_YOKOGAWA_HEADER reads the header information from continuous,
% epoched or averaged MEG data that has been generated by the Yokogawa
% MEG system and software and allows that data to be used in combination
% with FieldTrip.
%
% Use as
%  [hdr] = read_yokogawa_header(filename)
%
% This is a wrapper function around the functions
%   GetMeg160SystemInfoM
%   GetMeg160ChannelCountM
%   GetMeg160ChannelInfoM
%   GetMeg160CalibInfoM
%   GetMeg160AmpGainM
%   GetMeg160DataAcqTypeM
%   GetMeg160ContinuousAcqCondM
%   GetMeg160EvokedAcqCondM
%
% See also READ_YOKOGAWA_DATA, READ_YOKOGAWA_EVENT

% this function also calls
%   GetMeg160MriInfoM
%   GetMeg160MatchingInfoM
%   GetMeg160SourceInfoM
% but I don't know whether to use the information provided by those

% Copyright (C) 2005, Robert Oostenveld
%
% Subversion does not use the Log keyword, use 'svn log <filename>' or 'svn -v log | less' to get detailled information

% FIXED
%  txt -> m
%  fopen iee-le

handles = definehandles;
fid = fopen(filename, 'rb', 'ieee-le');

% these are always present
[id ver rev sys_name] = GetMeg160SystemInfoM(fid);
channel_count   = GetMeg160ChannelCountM(fid);
channel_info    = GetMeg160ChannelInfoM(fid);
calib_info      = GetMeg160CalibInfoM(fid);
amp_gain        = GetMeg160AmpGainM(fid);
acq_type        = GetMeg160DataAcqTypeM(fid);

% these depend on the data type
sample_rate        = [];
sample_count       = [];
pretrigger_length  = [];
averaged_count     = [];
actual_epoch_count = [];

switch acq_type
  case handles.AcqTypeContinuousRaw
    [sample_rate, sample_count] = GetMeg160ContinuousAcqCondM(fid);
    if isempty(sample_rate) | isempty(sample_count)
      fclose(fid);
      return;
    end
    pretrigger_length = 0;
    averaged_count = 1;
    
  case handles.AcqTypeEvokedAve
    [sample_rate, sample_count, pretrigger_length, averaged_count] = GetMeg160EvokedAcqCondM( fid );
    if isempty(sample_rate) | isempty(sample_count) | isempty(pretrigger_length) | isempty(averaged_count)
      fclose(fid);
      return;
    end
    
  case handles.AcqTypeEvokedRaw
    [sample_rate, sample_count, pretrigger_length, actual_epoch_count] = GetMeg160EvokedAcqCondM( fid );
    if isempty(sample_rate) | isempty(sample_count) | isempty(pretrigger_length) | isempty(actual_epoch_count)
      fclose(fid);
      return;
    end

  otherwise
    error('unknown data type');
end

% these are always present
mri_info      = GetMeg160MriInfoM(fid);
matching_info = GetMeg160MatchingInfoM(fid);
source_info   = GetMeg160SourceInfoM(fid);

fclose(fid);

% put all local variables into a structure, this is a bit unusual matlab programming style
tmp = whos;
orig = [];
for i=1:length(tmp)
  if isempty(strmatch(tmp(i).name, {'tmp', 'fid', 'ans', 'handles'}))
    orig = setfield(orig, tmp(i).name, eval(tmp(i).name));
  end
end

% convert the original header information into something that FieldTrip understands
hdr = [];
hdr.orig         = orig;                % also store the original full header information
hdr.Fs           = orig.sample_rate;    % sampling frequency
hdr.nChans       = orig.channel_count;  % number of channels
hdr.nSamples     = [];                  % number of samples per trial
hdr.nSamplesPre  = [];                  % number of pre-trigger samples in each trial
hdr.nTrials      = [];                  % number of trials

switch orig.acq_type
  case handles.AcqTypeEvokedAve
    hdr.nSamples    = orig.sample_count;
    hdr.nSamplesPre = orig.pretrigger_length;
    hdr.nTrials     = 1;                % only the average, which can be considered as a single trial
  case handles.AcqTypeContinuousRaw
    hdr.nSamples    = orig.sample_count;
    hdr.nSamplesPre = 0;                % there is no fixed relation between triggers and data
    hdr.nTrials     = 1;                % the continuous data can be considered as a single very long trial
  case handles.AcqTypeEvokedRaw
    hdr.nSamples    = orig.sample_count;
    hdr.nSamplesPre = orig.pretrigger_length;
    hdr.nTrials     = orig.actual_epoch_count;
  otherwise
    error('unknown acquisition type');
end

% construct a cell-array with labels of each channel
for i=1:hdr.nChans
  hdr.label{i}        = sprintf('%03d', i);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this defines some usefull constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function handles = definehandles;
handles.output = [];
handles.sqd_load_flag = false;
handles.mri_load_flag = false;
handles.NullChannel         = 0;
handles.MagnetoMeter        = 1;
handles.AxialGradioMeter    = 2;
handles.PlannerGradioMeter  = 3;
handles.RefferenceChannelMark = hex2dec('0100');
handles.RefferenceMagnetoMeter       = bitor( handles.RefferenceChannelMark, handles.MagnetoMeter );
handles.RefferenceAxialGradioMeter   = bitor( handles.RefferenceChannelMark, handles.AxialGradioMeter );
handles.RefferencePlannerGradioMeter = bitor( handles.RefferenceChannelMark, handles.PlannerGradioMeter );
handles.TriggerChannel      = -1;
handles.EegChannel          = -2;
handles.EcgChannel          = -3;
handles.EtcChannel          = -4;
handles.NonMegChannelNameLength = 32;
handles.DefaultMagnetometerSize       = (4.0/1000.0);       % Square of 4.0mm in length
handles.DefaultAxialGradioMeterSize   = (15.5/1000.0);      % Circle of 15.5mm in diameter
handles.DefaultPlannerGradioMeterSize = (12.0/1000.0);      % Square of 12.0mm in length
handles.AcqTypeContinuousRaw = 1;
handles.AcqTypeEvokedAve     = 2;
handles.AcqTypeEvokedRaw     = 3;
handles.sqd = [];
handles.sqd.selected_start  = [];
handles.sqd.selected_end    = [];
handles.sqd.axialgradiometer_ch_no      = [];
handles.sqd.axialgradiometer_ch_info    = [];
handles.sqd.axialgradiometer_data       = [];
handles.sqd.plannergradiometer_ch_no    = [];
handles.sqd.plannergradiometer_ch_info  = [];
handles.sqd.plannergradiometer_data     = [];
handles.sqd.eegchannel_ch_no   = [];
handles.sqd.eegchannel_data    = [];
handles.sqd.nullchannel_ch_no   = [];
handles.sqd.nullchannel_data    = [];
handles.sqd.selected_time       = [];
handles.sqd.sample_rate         = [];
handles.sqd.sample_count        = [];
handles.sqd.pretrigger_length   = [];
handles.sqd.matching_info   = [];
handles.sqd.source_info     = [];
handles.sqd.mri_info        = [];
handles.mri                 = [];
