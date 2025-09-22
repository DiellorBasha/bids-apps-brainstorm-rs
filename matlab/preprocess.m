function preprocess(sFilesRaw, config, output_dir)
% PREPROCESS - MEG/EEG preprocessing using Brainstorm bst_process functions
% 
% Following tutorial_omega.m patterns for preprocessing pipeline
%
% Inputs:
%   sFilesRaw - Brainstorm file structure from import
%   config    - Configuration structure with preprocessing parameters
%   output_dir - Output directory for BIDS derivatives
%
% Outputs:
%   Preprocessed files saved in Brainstorm database with BIDS metadata

    fprintf('Starting preprocessing pipeline...\n');
    
    if isempty(sFilesRaw)
        warning('No files provided for preprocessing');
        return;
    end
    
    % Load default configuration if not provided
    if nargin < 2 || isempty(config)
        config = load_processing_config();
    end
    
    % Apply preprocessing steps following tutorial_omega pattern
    try
        % Step 1: Frequency filtering
        sFilesFiltered = apply_frequency_filtering(sFilesRaw, config.preprocessing);
        
        % Step 2: Artifact detection and cleaning
        sFilesClean = apply_artifact_cleaning(sFilesFiltered, config.preprocessing);
        
        % Step 3: Generate quality control outputs
        generate_preprocessing_qc(sFilesClean, config.preprocessing);
        
        % Step 4: Save preprocessed files with BIDS metadata
        if nargin >= 3
            save_preprocessed_files(sFilesClean, output_dir, config.preprocessing);
        end
        
        fprintf('Preprocessing completed successfully. Processed %d files.\n', length(sFilesClean));
        
    catch ME
        error('Preprocessing failed: %s', ME.message);
    end
end

function sFilesFiltered = apply_frequency_filtering(sFilesRaw, config)
% Apply frequency filtering using bst_process following tutorial_omega pattern

    fprintf('  Applying frequency filters...\n');
    
    % Step 1: Notch filter (following tutorial_omega)
    if ~isempty(config.notch_filter)
        fprintf('    Notch filter: %s Hz\n', mat2str(config.notch_filter));
        sFilesNotch = bst_process('CallProcess', 'process_notch', sFilesRaw, [], ...
            'freqlist',    config.notch_filter, ...
            'sensortypes', 'MEG, EEG', ...
            'read_all',    1);
    else
        sFilesNotch = sFilesRaw;
    end
    
    % Step 2: Bandpass filter (following tutorial_omega)
    fprintf('    High-pass: %.2f Hz, Low-pass: %.2f Hz\n', config.highpass_filter, config.lowpass_filter);
    
    if config.lowpass_filter > 0
        % Both high-pass and low-pass
        sFilesFiltered = bst_process('CallProcess', 'process_bandpass', sFilesNotch, [], ...
            'sensortypes', 'MEG, EEG', ...
            'highpass',    config.highpass_filter, ...
            'lowpass',     config.lowpass_filter, ...
            'attenuation', 'strict', ...  % 60dB
            'mirror',      0, ...
            'useold',      0, ...
            'read_all',    1);
    else
        % High-pass only
        sFilesFiltered = bst_process('CallProcess', 'process_bandpass', sFilesNotch, [], ...
            'sensortypes', 'MEG, EEG', ...
            'highpass',    config.highpass_filter, ...
            'lowpass',     0, ...
            'attenuation', 'strict', ...  % 60dB
            'mirror',      0, ...
            'useold',      0, ...
            'read_all',    1);
    end
    
    % Clean up intermediate files (following tutorial_omega)
    if ~isempty(config.notch_filter)
        bst_process('CallProcess', 'process_delete', sFilesNotch, [], ...
            'target', 2);  % Delete folders
    end
    
    fprintf('    Frequency filtering completed.\n');
end

function sFilesClean = apply_artifact_cleaning(sFilesFiltered, config)
% Apply artifact detection and cleaning using bst_process following tutorial_omega pattern

    fprintf('  Applying artifact cleaning...\n');
    
    sFilesClean = sFilesFiltered;
    
    if ~config.auto_artifact_detection
        fprintf('    Auto artifact detection disabled.\n');
        return;
    end
    
    try
        % Process: Detect heartbeats (following tutorial_omega)
        fprintf('    Detecting cardiac artifacts...\n');
        bst_process('CallProcess', 'process_evt_detect_ecg', sFilesClean, [], ...
            'channelname', 'ECG', ...
            'timewindow',  [], ...
            'eventname',   'cardiac');
        
        % Process: SSP ECG removal (following tutorial_omega)
        fprintf('    Applying cardiac SSP...\n');
        bst_process('CallProcess', 'process_ssp_ecg', sFilesClean, [], ...
            'eventname',   'cardiac', ...
            'sensortypes', 'MEG', ...
            'usessp',      1, ...
            'select',      1);
        
        % Process: Detect eye movements (if EOG available)
        fprintf('    Detecting ocular artifacts...\n');
        bst_process('CallProcess', 'process_evt_detect_eog', sFilesClean, [], ...
            'channelname', 'EOG', ...
            'timewindow',  [], ...
            'eventname',   'blink');
        
        % Process: SSP EOG removal
        fprintf('    Applying ocular SSP...\n');
        bst_process('CallProcess', 'process_ssp_eog', sFilesClean, [], ...
            'eventname',   'blink', ...
            'sensortypes', 'MEG, EEG', ...
            'usessp',      1, ...
            'select',      1);
        
    catch ME
        warning('BST:ArtifactCleaning', 'Artifact cleaning failed: %s. Continuing without artifact removal.', ME.message);
    end
    
    fprintf('    Artifact cleaning completed.\n');
end

function generate_preprocessing_qc(sFiles, config)
% Generate quality control outputs following tutorial_omega pattern

    if ~config.generate_qa_plots
        return;
    end
    
    fprintf('  Generating quality control outputs...\n');
    
    try
        % Process: Power spectrum density after preprocessing (following tutorial_omega)
        sFilesPsd = bst_process('CallProcess', 'process_psd', sFiles, [], ...
            'timewindow',  [], ...
            'win_length',  4, ...
            'win_overlap', 50, ...
            'sensortypes', 'MEG, EEG', ...
            'edit',        struct(...
                 'Comment',         'Power', ...
                 'TimeBands',       [], ...
                 'Freqs',           [], ...
                 'ClusterFuncTime', 'none', ...
                 'Measure',         'power', ...
                 'Output',          'all', ...
                 'SaveKernel',      0));
        
        % Process: Snapshot of frequency spectrum (following tutorial_omega)
        bst_process('CallProcess', 'process_snapshot', sFilesPsd, [], ...
            'target',         10, ...  % Frequency spectrum
            'modality',       1);      % MEG (All)
        
        % Process: Snapshot of sensors/MRI registration (following tutorial_omega)
        bst_process('CallProcess', 'process_snapshot', sFiles, [], ...
            'target',         1, ...  % Sensors/MRI registration
            'modality',       1, ...  % MEG (All)
            'orient',         1);     % left
        
        % Process: Snapshot of SSP projectors (following tutorial_omega)
        bst_process('CallProcess', 'process_snapshot', sFiles, [], ...
            'target',         2, ...  % SSP projectors
            'modality',       1);     % MEG (All)
        
    catch ME
        warning('BST:QualityControl', 'Quality control output generation failed: %s', ME.message);
    end
    
    fprintf('    Quality control outputs generated.\n');
end

function config = load_processing_config()
% Load processing configuration

    % Default configuration
    config.preprocessing.highpass_filter = 1.0;
    config.preprocessing.lowpass_filter = 100.0;
    config.preprocessing.notch_filter = [50, 100];
    config.preprocessing.auto_artifact_detection = true;
    config.preprocessing.amplitude_threshold = 150e-12;
    config.preprocessing.gradient_threshold = 3000e-12;
    config.preprocessing.epoch_length = 2.0;
    config.preprocessing.epoch_overlap = 0.5;
    config.preprocessing.baseline_correction = [-0.2, 0];
    
    % TODO: Load from YAML configuration file
end

function metadata = create_processing_metadata(config)
% Create processing metadata for JSON sidecar following BIDS derivatives

    metadata = struct();
    metadata.Description = 'MEG/EEG data preprocessed using Brainstorm';
    metadata.GeneratedBy = struct( ...
        'Name', 'bids-apps-brainstorm', ...
        'Version', '1.0.0', ...
        'Container', struct('Type', 'docker'));
    
    % Processing parameters
    metadata.ProcessingSteps = {};
    
    if ~isempty(config.notch_filter)
        metadata.ProcessingSteps{end+1} = struct( ...
            'Name', 'NotchFilter', ...
            'Parameters', struct('frequencies', config.notch_filter));
    end
    
    metadata.ProcessingSteps{end+1} = struct( ...
        'Name', 'BandpassFilter', ...
        'Parameters', struct( ...
            'highpass', config.highpass_filter, ...
            'lowpass', config.lowpass_filter));
    
    if config.auto_artifact_detection
        metadata.ProcessingSteps{end+1} = struct( ...
            'Name', 'ArtifactDetection', ...
            'Parameters', struct('method', 'SSP'));
    end
    
    metadata.ProcessingDate = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
end

function write_json(filename, data)
% Write data structure to JSON file

    json_str = jsonencode(data, 'PrettyPrint', true);
    
    fid = fopen(filename, 'w');
    if fid == -1
        error('Could not open file for writing: %s', filename);
    end
    
    fprintf(fid, '%s', json_str);
    fclose(fid);
end

function save_preprocessed_files(sFiles, output_dir, config)
% Save preprocessed files with BIDS derivatives compliance
% Following Brainstorm's file structure and metadata

    if isempty(sFiles)
        return;
    end
    
    fprintf('  Saving preprocessed files...\n');
    
    for i = 1:length(sFiles)
        try
            % Get file information
            [sStudy, ~] = bst_get('AnyFile', sFiles(i).FileName);
            [sSubject, ~] = bst_get('Subject', sStudy.BrainStormSubject);
            
            % Create output filename with BIDS naming
            [~, file_base, ~] = fileparts(sFiles(i).FileName);
            output_filename = [file_base '_proc-brainstorm.mat'];
            
            % Create output directory structure (BIDS derivatives)
            if contains(sSubject.Name, 'ses-')
                % Extract subject and session from name
                name_parts = strsplit(sSubject.Name, {'sub-', 'ses-'});
                sub_id = name_parts{2};
                ses_id = strsplit(name_parts{3}, '/');
                ses_id = ses_id{1};
                
                out_dir = fullfile(output_dir, 'derivatives', 'brainstorm', ...
                    ['sub-' sub_id], ['ses-' ses_id], 'meg');
            else
                % Subject only
                sub_id = strrep(sSubject.Name, 'sub-', '');
                out_dir = fullfile(output_dir, 'derivatives', 'brainstorm', ...
                    ['sub-' sub_id], 'meg');
            end
            
            if ~exist(out_dir, 'dir')
                mkdir(out_dir);
            end
            
            % Create JSON sidecar
            json_file = fullfile(out_dir, strrep(output_filename, '.mat', '.json'));
            metadata = create_processing_metadata(config);
            write_json(json_file, metadata);
            
            fprintf('    Saved preprocessing metadata: %s\n', json_file);
            
        catch ME
            warning('BST:SavePreprocessed', 'Failed to save metadata for file %s: %s', ...
                sFiles(i).FileName, ME.message);
        end
    end
end