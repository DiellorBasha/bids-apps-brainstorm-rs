function import_bids_data(bids_dir, output_dir, participant_label)
% IMPORT_BIDS_DATA Import BIDS dataset into Brainstorm database
%
% Usage:
%   import_bids_data(bids_dir, output_dir, participant_label)
%
% Inputs:
%   bids_dir         - Path to BIDS dataset
%   output_dir       - Path to output directory
%   participant_label - Specific participant to import (optional)

    fprintf('Importing BIDS data from: %s\n', bids_dir);
    
    % Validate BIDS dataset
    if ~validate_bids_structure(bids_dir)
        error('Invalid BIDS dataset structure');
    end
    
    % Create Brainstorm database structure
    db_dir = fullfile(output_dir, 'derivatives', 'brainstorm');
    if ~exist(db_dir, 'dir')
        mkdir(db_dir);
    end
    
    % Read dataset description
    dataset_desc_file = fullfile(bids_dir, 'dataset_description.json');
    if exist(dataset_desc_file, 'file')
        dataset_desc = read_json(dataset_desc_file);
        fprintf('Dataset: %s\n', dataset_desc.Name);
    end
    
    % Get participants to import
    if isempty(participant_label)
        participants = get_all_participants(bids_dir);
    else
        participants = {participant_label};
    end
    
    % Import each participant
    for i = 1:length(participants)
        participant = participants{i};
        fprintf('Importing participant: %s\n', participant);
        
        try
            import_participant_data(bids_dir, db_dir, participant);
        catch ME
            warning('Failed to import participant %s: %s', participant, ME.message);
        end
    end
    
    % Create derivatives dataset description
    create_derivatives_description(db_dir);
    
    fprintf('BIDS import completed.\n');
end

function valid = validate_bids_structure(bids_dir)
% Validate basic BIDS dataset structure

    valid = true;
    
    % Check for required files
    required_files = {'dataset_description.json'};
    for i = 1:length(required_files)
        if ~exist(fullfile(bids_dir, required_files{i}), 'file')
            fprintf('Missing required file: %s\n', required_files{i});
            valid = false;
        end
    end
    
    % Check for participant directories
    participant_dirs = dir(fullfile(bids_dir, 'sub-*'));
    if isempty(participant_dirs)
        fprintf('No participant directories found\n');
        valid = false;
    end
end

function participants = get_all_participants(bids_dir)
% Get list of all participants in BIDS dataset

    participant_dirs = dir(fullfile(bids_dir, 'sub-*'));
    participants = {};
    
    for i = 1:length(participant_dirs)
        if participant_dirs(i).isdir
            participants{end+1} = participant_dirs(i).name;
        end
    end
end

function import_participant_data(bids_dir, db_dir, participant)
% Import data for a single participant

    participant_dir = fullfile(bids_dir, participant);
    
    % Find MEG/EEG sessions
    session_dirs = dir(fullfile(participant_dir, 'ses-*'));
    if isempty(session_dirs)
        % No sessions - look directly in participant directory
        import_session_data(participant_dir, db_dir, participant, '');
    else
        % Multiple sessions
        for i = 1:length(session_dirs)
            if session_dirs(i).isdir
                session = session_dirs(i).name;
                session_dir = fullfile(participant_dir, session);
                import_session_data(session_dir, db_dir, participant, session);
            end
        end
    end
end

function import_session_data(session_dir, db_dir, participant, session)
% Import MEG/EEG data for a single session

    % Look for MEG data
    meg_dir = fullfile(session_dir, 'meg');
    if exist(meg_dir, 'dir')
        import_meg_data(meg_dir, db_dir, participant, session);
    end
    
    % Look for EEG data  
    eeg_dir = fullfile(session_dir, 'eeg');
    if exist(eeg_dir, 'dir')
        import_eeg_data(eeg_dir, db_dir, participant, session);
    end
    
    % Look for anatomical data
    anat_dir = fullfile(session_dir, 'anat');
    if exist(anat_dir, 'dir')
        import_anat_data(anat_dir, db_dir, participant, session);
    end
end

function import_meg_data(meg_dir, db_dir, participant, session)
% Import MEG data files

    % Find MEG files (various formats)
    meg_files = [dir(fullfile(meg_dir, '*.ds')); ...  % CTF
                 dir(fullfile(meg_dir, '*.fif')); ... % Neuromag
                 dir(fullfile(meg_dir, '*.pdf'))];    % BTi
    
    for i = 1:length(meg_files)
        meg_file = fullfile(meg_dir, meg_files(i).name);
        fprintf('  Importing MEG file: %s\n', meg_files(i).name);
        
        % TODO: Implement actual Brainstorm import
        % This would use Brainstorm's in_data_bids function
    end
end

function import_eeg_data(eeg_dir, db_dir, participant, session)
% Import EEG data files

    % Find EEG files
    eeg_files = [dir(fullfile(eeg_dir, '*.edf')); ...   % EDF
                 dir(fullfile(eeg_dir, '*.vhdr')); ... % BrainVision
                 dir(fullfile(eeg_dir, '*.set'))];     % EEGLAB
    
    for i = 1:length(eeg_files)
        eeg_file = fullfile(eeg_dir, eeg_files(i).name);
        fprintf('  Importing EEG file: %s\n', eeg_files(i).name);
        
        % TODO: Implement actual Brainstorm import
    end
end

function import_anat_data(anat_dir, db_dir, participant, session)
% Import anatomical data

    % Find T1w images
    t1_files = dir(fullfile(anat_dir, '*T1w.nii*'));
    
    for i = 1:length(t1_files)
        t1_file = fullfile(anat_dir, t1_files(i).name);
        fprintf('  Importing T1w: %s\n', t1_files(i).name);
        
        % TODO: Implement anatomical import
    end
end

function data = read_json(filename)
% Read JSON file

    text = fileread(filename);
    data = jsondecode(text);
end

function create_derivatives_description(db_dir)
% Create dataset_description.json for derivatives

    desc = struct();
    desc.Name = 'BIDS Apps Brainstorm';
    desc.BIDSVersion = '1.8.0';
    desc.GeneratedBy.Name = 'BIDS Apps Brainstorm';
    desc.GeneratedBy.Version = '0.1.0';
    desc.GeneratedBy.CodeURL = 'https://github.com/DiellorBasha/bids-apps-brainstorm-rs';
    
    desc_file = fullfile(db_dir, 'dataset_description.json');
    write_json(desc_file, desc);
end

function write_json(filename, data)
% Write data to JSON file

    json_text = jsonencode(data, 'PrettyPrint', true);
    fid = fopen(filename, 'w');
    fprintf(fid, '%s', json_text);
    fclose(fid);
end