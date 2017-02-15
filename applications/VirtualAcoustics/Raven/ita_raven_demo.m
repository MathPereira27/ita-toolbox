% 1. set/check matlab paths


% <ITA-Toolbox>
% This file is part of the application Raven for the ITA-Toolbox. All rights reserved.
% You can find the license for this m-file in the application folder.
% </ITA-Toolbox>

%% Projektdatei einlesen
% load ita raven project
rpf = itaRavenProject('..\RavenInput\Classroom\Classroom.rpf');

%% Simulationsparameter einstellen
% Image sources up to second order
rpf.setISOrder_PS(2);

% 20000 ray tracing partikel
rpf.setNumParticles(200);

% set impulse response length in ms (at least length of reverberation time)
rpf.setFilterLength(2800);  %[ms]
% rpf.setFilterLengthToReverbTime();    % estimates reverberation time and
% sets rpf.filterLength to this value

% set room temperature
rpf.setTemperature(21); %�C


%% Define simulation outputs
% create monaural room impulse response
rpf.setGenerateRIR(1);

% create binaural room impulse response
rpf.setGenerateBRIR(1);

% create and export energy histograms
rpf.setExportHistogram(1);  % histogramme z.B. ben�tigt f�r schnelle Nachhallzeitauswertung (RavenProject.getT30)


%% Quell- und Empf�ngerdaten
% set source positions
rpf.setSourcePositions([9 1.7 -2.5]);
rpf.setSourceViewVectors([-1 0 0]);
rpf.setSourceUpVectors([0 1 0]);

% set receiver positions
rpf.setReceiverPositions([4.4500    1.0000   -3.9000]);

% set sound source names
rpf.setSourceNames('Speaker Left');

% set source directivity 
rpf.setSourceDirectivity('KH_O100_Oli_5x5_3rd_relativiert_auf_azi0_ele0.daff');

%% start simulation 
% run simulation
rpf.run;

%% Ergebnisse abholen
% get room impulse responses
mono_ir = rpf.getMonauralImpulseResponseItaAudio();     % rpf.getMonauralImpulseResponse() without ITA-Toolbox
binaural = rpf.getBinauralImpulseResponseItaAudio();
reverb_time = rpf.getT30();


%% ITA-Toolbox......
mono_ir.plot_time;      % plot monaural RIR in time domain
binaural.plot_freq;     % plot binaural RIR in time domain

%% Example: Include loudspeaer frequency response in RIR (for comparisons with measurements)
ls_O100 = ita_read('..\RavenDatabase\FrequencyResponse\KH_O100_reference_holesclosed_final_at1V1m_fft14.ita');
ir_mit_lautsprecher = ita_convolve(mono_ir, ls_O100);

%% Additional features
% show room model including sound sources
 rpf.plotModel;
 
 % show absorption coefficients
 rpf.plotMaterialsAbsorption;
