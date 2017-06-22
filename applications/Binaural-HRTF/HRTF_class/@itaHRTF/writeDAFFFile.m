function writeDAFFFile( this, file_path, metadata_user )
% Exports itaHRTF to a DAFF file
%
% Input:    file_path (string) [optional]
%           user metadata (struct created with daff_add_metadata) [optional]
%
% Required: OpenDAFF matlab scripts, http://www.opendaff.org
%           (but included in ITA-Toolbox)
%
% Output: none

metadata = this.mMetadata;
if nargin >= 3
    metadata = metadata_user;
end

hrtf_variable_name = inputname( 1 );
file_name = [ hrtf_variable_name '_' int2str( this.nSamples ) 'samples_' int2str( this.resAzimuth ) 'x' int2str( this.resElevation ) '.daff'];
if nargin >= 2
    file_name = file_path;    
end

if nargin == 0
    error( 'Not enough input arguments' );
end


%% Inject content type indicator 'ir' or 'dft' into file name

ct_indicator = 'ir';
if strcmp( this.domain, 'freq' )
    ct_indicator = 'dft';
end

[ file_path, file_base_name, file_suffix ] = fileparts( file_name );
if ~strcmp( file_suffix, '.daff' )
    file_path = fullfile( file_path, strjoin( {file_base_name file_suffix 'v17' ct_indicator 'daff' }, '.' ) );
else
    file_path = fullfile( file_path, strjoin( {file_base_name 'v17' ct_indicator 'daff'}, '.' ) );
end


%% Prepare angle ranges and resolution

theta_start_deg = rad2deg( min( this.channelCoordinates.theta ) );
theta_end_deg = rad2deg( max( this.channelCoordinates.theta ) );
theta_num_elements = size( uniquetol( this.channelCoordinates.theta ), 1 );

phi_start_deg = rad2deg( min( mod( this.channelCoordinates.phi, 2 * pi ) ) );
phi_end_deg = rad2deg( max( mod( this.channelCoordinates.phi, 2 * pi ) ) );
phi_num_elements = size( uniquetol( this.channelCoordinates.phi ), 1 );

assert( phi_num_elements ~= 0 );
alphares = ( phi_end_deg - phi_start_deg ) / phi_num_elements; % phi end does not cover entire circle in this case
alphares_full_circle = ( phi_end_deg - phi_start_deg ) / ( phi_num_elements - 1 ); % phi end does not cover entire circle in this case
if phi_end_deg + alphares_full_circle >= 360.0
    alpharange = [ phi_start_deg 360 ]; % Account for full circle and force end of range to 360 deg
    alphares = alphares_full_circle;
else
    alpharange = [ phi_start_deg phi_end_deg ];
end

assert( alpharange( 1 ) >= 0.0 )
assert( alpharange( 2 ) <= 360.0 )

assert( theta_num_elements ~= 0 );
betares = ( theta_end_deg - theta_start_deg ) / ( theta_num_elements - 1 ); % phi end does not cover entire circle
betarange = 180 - [ theta_start_deg theta_end_deg ]; % Flip poles (DAFF starts at south pole)

assert( betarange( 2 ) >= 0.0 )
assert( betarange( 1 ) <= 180.0 )


%% Assemble metadata

metadata = daffv17_add_metadata( metadata, 'Generation script', 'String', 'writeDAFFFile.m' );
metadata = daffv17_add_metadata( metadata, 'Generation toolkit', 'String', 'ITA-Toolkit' );
metadata = daffv17_add_metadata( metadata, 'Generation date', 'String', date );
metadata = daffv17_add_metadata( metadata, 'Web resource', 'String', 'http://www.ita-toolkit.org' );
channels=this.nChannels/this.nDirections;
if(channels<1)
    warning('Number of channels per record was not detected correctly, assuming 2 channel records');
    channels = 2;
end

% Content type switcher between time domain (ir) and frequency domain (dft)
% (requires different data functions)
if strcmp( this.domain, 'time' )

    daffv17_write('filename', file_path, ...
               'content', 'ir', ...
               'datafunc', @dfitaHRIRDAFFDataFunc, ...
               'channels', channels, ...
               'alphares', alphares, ...
               'alpharange', alpharange, ...
               'betares', betares, ...
               'betarange', betarange, ...
               'orient', [ 0 0 0 ], ...
               'metadata', metadata, ...
               'userdata', this, ...
               'quantization', 'float32' );
           
elseif strcmp( this.domain, 'freq' )
    
    daffv17_write('filename', file_path, ...
               'content', 'dft', ...
               'datafunc', @dfitaHRTFDAFFDataFunc, ...
               'channels', channels, ...
               'alphares', alphares, ...
               'alpharange', alpharange, ...
               'betares', betares, ...
               'betarange', betarange, ...
               'orient', [ 0 0 0 ], ...
               'metadata', metadata, ...
               'userdata', this, ...
               'quantization', 'float32' );
           
end
