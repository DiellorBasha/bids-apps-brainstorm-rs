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

    % Add Brainstorm to path if available
    if exist('brainstorm', 'file')
        brainstorm nogui
    else
        warning('Brainstorm not found in path. Some functionality may be limited.');
    end
    
    % Parse inputs
    if nargin < 4
        participant_label = '';
    end
    
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
        % Import BIDS dataset
        fprintf('Importing BIDS dataset...\n');
        import_bids_data(bids_dir, output_dir, participant_label);
        
        switch lower(analysis_level)
            case 'participant'
                fprintf('Running participant-level analysis...\n');
                run_participant_analysis(bids_dir, output_dir, participant_label);
                
            case 'group'
                fprintf('Running group-level analysis...\n');
                run_group_analysis(bids_dir, output_dir);
                
            otherwise
                error('Unknown analysis level: %s', analysis_level);
        end
        
        fprintf('Processing completed successfully.\n');
        
    catch ME
        fprintf('Error during processing: %s\n', ME.message);
        rethrow(ME);
    end
end

function run_participant_analysis(bids_dir, output_dir, participant_label)
% Run participant-level preprocessing and source analysis

    % Get list of participants
    if isempty(participant_label)
        participants = get_participants(bids_dir);
    else
        participants = {participant_label};
    end
    
    for i = 1:length(participants)
        participant = participants{i};
        fprintf('Processing participant: %s\n', participant);
        
        try
            % Preprocessing
            preprocess_participant(bids_dir, output_dir, participant);
            
            % Sensor space analysis
            sensor_space_analysis(bids_dir, output_dir, participant);
            
            % Source space analysis
            source_space_analysis(bids_dir, output_dir, participant);
            
            fprintf('Completed participant: %s\n', participant);
            
        catch ME
            fprintf('Error processing participant %s: %s\n', participant, ME.message);
            continue;
        end
    end
end

function run_group_analysis(bids_dir, output_dir)
% Run group-level analysis across all participants

    fprintf('Group-level analysis not yet implemented.\n');
    % TODO: Implement group-level statistics and comparisons
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