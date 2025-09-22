function sFilesRaw = import_bids_data(bids_dir, output_dir, participant_label)
% IMPORT_BIDS_DATA Import BIDS dataset into Brainstorm database using bst_process
%
% Usage:
%   sFilesRaw = import_bids_data(bids_dir, output_dir, participant_label)
%
% Inputs:
%   bids_dir         - Path to BIDS dataset
%   output_dir       - Path to output directory
%   participant_label - Specific participant to import (optional)
%
% Outputs:
%   sFilesRaw        - Structure array of imported raw files

    fprintf('Importing BIDS data from: %s\n', bids_dir);
    
    % Validate BIDS dataset
    if ~validate_bids_structure(bids_dir)
        error('Invalid BIDS dataset structure');
    end
    
    % Read dataset description
    dataset_desc_file = fullfile(bids_dir, 'dataset_description.json');
    if exist(dataset_desc_file, 'file')
        dataset_desc = read_json(dataset_desc_file);
        fprintf('Dataset: %s\n', dataset_desc.Name);
        protocol_name = generate_protocol_name(dataset_desc.Name, participant_label);
    else
        protocol_name = generate_protocol_name('BIDSDataset', participant_label);
    end
    
    % Create Brainstorm protocol
    create_brainstorm_protocol(protocol_name);
    
    % Import BIDS dataset using Brainstorm's process_import_bids
    sFilesRaw = import_bids_with_brainstorm(bids_dir, participant_label);
    
    % Create derivatives dataset description
    db_dir = fullfile(output_dir, 'derivatives', 'brainstorm');
    if ~exist(db_dir, 'dir')
        mkdir(db_dir);
    end
    create_derivatives_description(db_dir);
    
    fprintf('BIDS import completed. Imported %d files.\n', length(sFilesRaw));
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

function protocol_name = generate_protocol_name(dataset_name, participant_label)
% Generate a valid protocol name for Brainstorm

    % Clean dataset name to be a valid folder name
    protocol_name = regexprep(dataset_name, '[^a-zA-Z0-9_]', '_');
    
    % Add participant label if specified
    if nargin > 1 && ~isempty(participant_label)
        protocol_name = [protocol_name '_' participant_label];
    end
    
    % Ensure it starts with a letter
    if ~isempty(protocol_name) && ~isletter(protocol_name(1))
        protocol_name = ['Protocol_' protocol_name];
    end
    
    % Limit length
    if length(protocol_name) > 50
        protocol_name = protocol_name(1:50);
    end
end

function create_brainstorm_protocol(protocol_name)
% Create or recreate Brainstorm protocol following tutorial_omega pattern

    fprintf('Creating Brainstorm protocol: %s\n', protocol_name);
    
    % Start Brainstorm without GUI if not already running
    if ~brainstorm('status')
        brainstorm nogui
    end
    
    % Delete existing protocol if it exists
    gui_brainstorm('DeleteProtocol', protocol_name);
    
    % Create new protocol
    % Parameters: ProtocolName, UseDefaultAnat, UseDefaultChannel
    gui_brainstorm('CreateProtocol', protocol_name, 0, 0);
    
    % Start a new report
    bst_report('Start');
    
    fprintf('Protocol created successfully.\n');
end

function sFilesRaw = import_bids_with_brainstorm(bids_dir, participant_label)
% Import BIDS dataset using Brainstorm's process_import_bids

    fprintf('Importing BIDS dataset using bst_process...\n');
    
    % Prepare BIDS import options
    import_options = struct();
    
    % Set vertex count for cortical surface (following tutorial_omega)
    import_options.nvertices = 15000;
    
    % Disable automatic channel alignment (can be done later)
    import_options.channelalign = 0;
    
    % If specific participant is requested, we'll filter after import
    % (process_import_bids doesn't have direct participant filtering)
    
    try
        % Process: Import BIDS dataset
        sFilesRaw = bst_process('CallProcess', 'process_import_bids', [], [], ...
            'bidsdir',      {bids_dir, 'BIDS'}, ...
            'nvertices',    import_options.nvertices, ...
            'channelalign', import_options.channelalign);
        
        fprintf('Successfully imported %d files from BIDS dataset.\n', length(sFilesRaw));
        
        % If specific participant requested, filter the imported files
        if ~isempty(participant_label)
            sFilesRaw = filter_participant_files(sFilesRaw, participant_label);
            fprintf('Filtered to %d files for participant: %s\n', length(sFilesRaw), participant_label);
        end
        
        % Apply post-import processing following tutorial_omega pattern
        sFilesRaw = apply_post_import_processing(sFilesRaw);
        
    catch ME
        error('Failed to import BIDS dataset: %s', ME.message);
    end
end

function sFilesFiltered = filter_participant_files(sFiles, participant_label)
% Filter imported files to specific participant

    if isempty(sFiles)
        sFilesFiltered = sFiles;
        return;
    end
    
    % Get subject names from the imported files
    subjects = {sFiles.SubjectName};
    
    % Find files matching the participant label
    participant_mask = contains(subjects, participant_label);
    
    sFilesFiltered = sFiles(participant_mask);
end

function sFilesProcessed = apply_post_import_processing(sFilesRaw)
% Apply post-import processing following tutorial_omega pattern

    fprintf('Applying post-import processing...\n');
    
    if isempty(sFilesRaw)
        sFilesProcessed = sFilesRaw;
        return;
    end
    
    try
        % Process: Remove head points (following tutorial_omega)
        sFilesProcessed = bst_process('CallProcess', 'process_headpoints_remove', sFilesRaw, [], ...
            'zlimit', 0);
        
        % Process: Refine registration (following tutorial_omega)
        sFilesProcessed = bst_process('CallProcess', 'process_headpoints_refine', sFilesProcessed, []);
        
        % Process: Convert to continuous for CTF data (following tutorial_omega)
        % This will only affect CTF datasets, others will be unchanged
        sFilesProcessed = bst_process('CallProcess', 'process_ctf_convert', sFilesProcessed, [], ...
            'rectype', 2);  % Continuous
        
        fprintf('Post-import processing completed.\n');
        
    catch ME
        warning('BST:ImportPostProcessing', 'Post-import processing failed: %s. Returning original files.', ME.message);
        sFilesProcessed = sFilesRaw;
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