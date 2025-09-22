function end_to_end(bids_dir, output_dir, analysis_level, participant_label)
% END_TO_END Main entry point for BIDS Apps Brainstorm processing
%
% Usage:
%   end_to_end(bids_dir, output_dir, analysis_level, participant_label)
%
% Inputs:
%   bids_dir         - Path to BIDS dataset
%   output_dir       - Path to output directory  
%   analysis_level   - 'participant' or 'group'
%   participant_label - Participant label (optional)

    % Initialize Brainstorm (following tutorial_omega pattern)
    if ~brainstorm('status')
        brainstorm nogui
    end
    
    % Parse inputs
    if nargin < 4
        participant_label = '';
    end
    
    % Load configuration
    config = load_processing_config();
    
    % Initialize logging
    log_file = fullfile(output_dir, 'logs', sprintf('brainstorm_%s.log', datestr(now, 'yyyymmdd_HHMMSS')));
    if ~exist(fileparts(log_file), 'dir')
        mkdir(fileparts(log_file));
    end
    
    % Start processing
    fprintf('Starting BIDS Apps Brainstorm processing...\n');
    fprintf('BIDS directory: %s\n', bids_dir);
    fprintf('Output directory: %s\n', output_dir);
    fprintf('Analysis level: %s\n', analysis_level);
    
    try
        switch lower(analysis_level)
            case 'participant'
                fprintf('Running participant-level analysis...\n');
                run_participant_analysis(bids_dir, output_dir, participant_label, config);
                
            case 'group'
                fprintf('Running group-level analysis...\n');
                run_group_analysis(bids_dir, output_dir, config);
                
            otherwise
                error('Unknown analysis level: %s', analysis_level);
        end
        
        fprintf('Processing completed successfully.\n');
        
    catch ME
        fprintf('Error during processing: %s\n', ME.message);
        rethrow(ME);
    end
end

function run_participant_analysis(bids_dir, output_dir, participant_label, config)
% Run participant-level preprocessing and source analysis using Brainstorm bst_process

    % Get list of participants
    if isempty(participant_label)
        participants = get_participants(bids_dir);
    else
        participants = {participant_label};
    end
    
    % Import BIDS dataset once (following tutorial_omega pattern)
    fprintf('Importing BIDS dataset...\n');
    sFilesRaw = import_bids_dataset(bids_dir, config);
    
    for i = 1:length(participants)
        participant = participants{i};
        fprintf('Processing participant: %s\n', participant);
        
        try
            % Filter files for current participant
            sFilesParticipant = filter_files_by_participant(sFilesRaw, participant);
            
            if isempty(sFilesParticipant)
                warning('No files found for participant: %s', participant);
                continue;
            end
            
            % Step 1: Preprocessing (following new bst_process pattern)
            fprintf('  Running preprocessing...\n');
            preprocess(sFilesParticipant, config, output_dir);
            
            % Step 2: Sensor space analysis (if implemented)
            if exist('sensor_space', 'file')
                fprintf('  Running sensor space analysis...\n');
                sensor_space(sFilesParticipant, config, output_dir);
            end
            
            % Step 3: Source space analysis (following new bst_process pattern)
            fprintf('  Running source space analysis...\n');
            source_space(sFilesParticipant, config, output_dir);
            
            fprintf('Completed participant: %s\n', participant);
            
        catch ME
            fprintf('Error processing participant %s: %s\n', participant, ME.message);
            % Continue with next participant instead of stopping
            continue;
        end
    end
end

function run_group_analysis(~, ~, ~)
% Run group-level analysis across all participants

    fprintf('Group-level analysis not yet implemented.\n');
    % TODO: Implement group-level statistics and comparisons
    % This would typically involve:
    % - Loading individual participant results
    % - Statistical comparisons between conditions/groups
    % - Population-level source analysis
    % - Report generation
end

function participants = get_participants(bids_dir)
% Get list of participants from BIDS dataset

    participant_dirs = dir(fullfile(bids_dir, 'sub-*'));
    participants = {};
    
    for i = 1:length(participant_dirs)
        if participant_dirs(i).isdir
            participants{end+1} = participant_dirs(i).name;
        end
    end
end

function sFilesRaw = import_bids_dataset(bids_dir, config)
% Import BIDS dataset using new Brainstorm bst_process function

    try
        % Call the updated import function (returns sFilesRaw)
        sFilesRaw = import(bids_dir, config);
        
        fprintf('BIDS dataset imported successfully. Found %d files.\n', length(sFilesRaw));
        
    catch ME
        error('Failed to import BIDS dataset: %s', ME.message);
    end
end

function sFilesFiltered = filter_files_by_participant(sFiles, participant)
% Filter Brainstorm file structures by participant label

    if isempty(sFiles)
        sFilesFiltered = [];
        return;
    end
    
    sFilesFiltered = [];
    
    for i = 1:length(sFiles)
        % Check if file belongs to the specified participant
        if contains(sFiles(i).FileName, participant) || contains(sFiles(i).Comment, participant)
            sFilesFiltered = [sFilesFiltered; sFiles(i)];
        end
    end
    
    fprintf('Filtered to %d files for participant %s\n', length(sFilesFiltered), participant);
end

function config = load_processing_config()
% Load processing configuration (placeholder - should load from YAML)

    config = struct();
    
    % Import configuration
    config.import.nvertices = 15000;
    config.import.channelalign = 0;
    
    % Preprocessing configuration
    config.preprocessing.notch_filter = [60, 120, 180, 240, 300];  % Line noise
    config.preprocessing.highpass_filter = 0.3;  % High-pass filter (Hz)
    config.preprocessing.lowpass_filter = 0;     % Low-pass filter (Hz, 0=disabled)
    config.preprocessing.auto_artifact_detection = true;
    config.preprocessing.generate_qa_plots = true;
    
    % Source analysis configuration
    config.source_analysis.noise_tag = 'task-noise';
    config.source_analysis.inverse_method = 'dspm2018';
    config.source_analysis.snr = 3;
    config.source_analysis.time_window = [0, 100];
    config.source_analysis.generate_qa_plots = true;
    
    % Frequency bands (following tutorial_omega)
    config.source_analysis.freq_bands = {
        'delta', '2, 4', 'mean';
        'theta', '5, 7', 'mean';
        'alpha', '8, 12', 'mean';
        'beta', '15, 29', 'mean';
        'gamma1', '30, 59', 'mean';
        'gamma2', '60, 90', 'mean'
    };
    
    % TODO: Load from actual YAML configuration files
    % config_file = fullfile(fileparts(mfilename('fullpath')), '..', 'config', 'default.yaml');
    % if exist(config_file, 'file')
    %     config = yaml.loadFile(config_file);
    % end
end