function source_space(sFilesPreprocessed, config, output_dir)
% SOURCE_SPACE - Source-level analysis using Brainstorm bst_process functions
% 
% Following tutorial_omega.m patterns for source estimation and power mapping
%
% Inputs:
%   sFilesPreprocessed - Brainstorm file structure from preprocessing
%   config             - Configuration structure with source analysis parameters
%   output_dir         - Output directory for BIDS derivatives
%
% Outputs:
%   Source analysis results saved in Brainstorm database with BIDS metadata

    fprintf('Starting source space analysis...\n');
    
    if isempty(sFilesPreprocessed)
        warning('No files provided for source analysis');
        return;
    end
    
    % Load default configuration if not provided
    if nargin < 2 || isempty(config)
        config = load_source_config();
    end
    
    try
        % Step 1: Compute noise covariance (following tutorial_omega)
        compute_noise_covariance(sFilesPreprocessed, config.source_analysis);
        
        % Step 2: Compute head model (following tutorial_omega)
        compute_head_model(sFilesPreprocessed, config.source_analysis);
        
        % Step 3: Compute inverse solution (following tutorial_omega)
        sSrcFiles = compute_inverse_solution(sFilesPreprocessed, config.source_analysis);
        
        % Step 4: Compute source power maps (following tutorial_omega)
        sSrcPowerMaps = compute_source_power_maps(sSrcFiles, config.source_analysis);
        
        % Step 5: Generate quality control outputs
        generate_source_qc(sSrcPowerMaps, config.source_analysis);
        
        % Step 6: Save source analysis results with BIDS metadata
        if nargin >= 3
            save_source_results(sSrcPowerMaps, output_dir, config.source_analysis);
        end
        
        fprintf('Source space analysis completed successfully.\n');
        
    catch ME
        error('Source space analysis failed: %s', ME.message);
    end
end

function compute_noise_covariance(sFiles, config)
% Compute noise covariance using bst_process following tutorial_omega pattern

    fprintf('  Computing noise covariance...\n');
    
    try
        % Select files for noise covariance computation
        % Look for noise/baseline segments or use resting state data
        sFilesNoise = sFiles;
        
        % If specific noise recordings exist, select them
        if isfield(config, 'noise_tag') && ~isempty(config.noise_tag)
            sFilesNoise = bst_process('CallProcess', 'process_select_tag', sFiles, [], ...
                'tag',    config.noise_tag, ...
                'search', 1, ...  % Search the file names
                'select', 1);     % Select only the files with the tag
        end
        
        % Process: Compute covariance (noise or data) - following tutorial_omega
        bst_process('CallProcess', 'process_noisecov', sFilesNoise, [], ...
            'baseline',       [], ...
            'sensortypes',    'MEG', ...
            'target',         1, ...  % Noise covariance (covariance over baseline time window)
            'dcoffset',       1, ...  % Block by block, to avoid effects of slow shifts in data
            'identity',       0, ...
            'copycond',       1, ...
            'copysubj',       1, ...
            'copymatch',      1, ...
            'replacefile',    1);     % Replace
        
        fprintf('    Noise covariance computation completed.\n');
        
    catch ME
        warning('BST:NoiseCovariance', 'Noise covariance computation failed: %s', ME.message);
    end
end

function compute_head_model(sFiles, ~)
% Compute head model using bst_process following tutorial_omega pattern

    fprintf('  Computing head model...\n');
    
    try
        % Process: Compute head model - following tutorial_omega
        bst_process('CallProcess', 'process_headmodel', sFiles, [], ...
            'sourcespace', 1, ...  % Cortex surface
            'meg',         3);     % Overlapping spheres
        
        fprintf('    Head model computation completed.\n');
        
    catch ME
        warning('BST:HeadModel', 'Head model computation failed: %s', ME.message);
    end
end

function sSrcFiles = compute_inverse_solution(sFiles, config)
% Compute inverse solution using bst_process following tutorial_omega pattern

    fprintf('  Computing inverse solution...\n');
    
    try
        % Set default inverse method if not specified
        if ~isfield(config, 'inverse_method')
            config.inverse_method = 'dspm2018';
        end
        if ~isfield(config, 'snr')
            config.snr = 3;
        end
        
        % Process: Compute sources [2018] - following tutorial_omega
        sSrcFiles = bst_process('CallProcess', 'process_inverse_2018', sFiles, [], ...
            'output',  2, ...  % Kernel only: one per file
            'inverse', struct(...
                 'Comment',        ['dSPM: MEG (SNR=', num2str(config.snr), ')'], ...
                 'InverseMethod',  'minnorm', ...
                 'InverseMeasure', config.inverse_method, ...
                 'SourceOrient',   {{'fixed'}}, ...
                 'Loose',          0.2, ...
                 'UseDepth',       1, ...
                 'WeightExp',      0.5, ...
                 'WeightLimit',    10, ...
                 'NoiseMethod',    'reg', ...
                 'NoiseReg',       0.1, ...
                 'SnrMethod',      'fixed', ...
                 'SnrRms',         1e-06, ...
                 'SnrFixed',       config.snr, ...
                 'ComputeKernel',  1, ...
                 'DataTypes',      {{'MEG'}}));
        
        fprintf('    Inverse solution computation completed.\n');
        
    catch ME
        error('Inverse solution computation failed: %s', ME.message);
    end
end

function sSrcPowerMaps = compute_source_power_maps(sSrcFiles, config)
% Compute source power maps using bst_process following tutorial_omega POWER MAPS pattern

    fprintf('  Computing source power maps...\n');
    
    try
        % Set default frequency bands if not specified
        if ~isfield(config, 'freq_bands')
            freq_bands = {
                'delta', '2, 4', 'mean';
                'theta', '5, 7', 'mean';
                'alpha', '8, 12', 'mean';
                'beta', '15, 29', 'mean';
                'gamma1', '30, 59', 'mean';
                'gamma2', '60, 90', 'mean'
            };
        else
            freq_bands = config.freq_bands;
        end
        
        % Set default time window
        if isfield(config, 'time_window')
            time_window = config.time_window;
        else
            time_window = [0, 100];  % Use all available time
        end
        
        % Step 1: Process: Power spectrum density (Welch) - following tutorial_omega
        sSrcPsd = bst_process('CallProcess', 'process_psd', sSrcFiles, [], ...
            'timewindow',  time_window, ...
            'win_length',  4, ...
            'win_overlap', 50, ...
            'clusters',    {}, ...
            'scoutfunc',   1, ...  % Mean
            'edit',        struct(...
                 'Comment',         'Power,FreqBands', ...
                 'TimeBands',       [], ...
                 'Freqs',           {freq_bands}, ...
                 'ClusterFuncTime', 'none', ...
                 'Measure',         'power', ...
                 'Output',          'all', ...
                 'SaveKernel',      0));
        
        % Step 2: Process: Spectrum normalization - following tutorial_omega
        sSrcPsdNorm = bst_process('CallProcess', 'process_tf_norm', sSrcPsd, [], ...
            'normalize', 'relative', ...  % Relative power (divide by total power)
            'overwrite', 0);
        
        % Step 3: Process: Project on default anatomy: surface - following tutorial_omega
        sSrcPsdProj = bst_process('CallProcess', 'process_project_sources', sSrcPsdNorm, [], ...
            'headmodeltype', 'surface');  % Cortex surface
        
        % Step 4: Process: Spatial smoothing - following tutorial_omega
        sSrcPsdSmooth = bst_process('CallProcess', 'process_ssmooth_surfstat', sSrcPsdProj, [], ...
            'fwhm',      3, ...     % 3mm FWHM
            'overwrite', 1);
        
        % Step 5: Process: Average: Everything - following tutorial_omega
        sSrcPowerMaps = bst_process('CallProcess', 'process_average', sSrcPsdSmooth, [], ...
            'avgtype',   1, ...  % Everything
            'avg_func',  1, ...  % Arithmetic average: mean(x)
            'weighted',  0, ...
            'matchrows', 0, ...
            'iszerobad', 0);
        
        fprintf('    Source power maps computation completed.\n');
        
    catch ME
        error('Source power maps computation failed: %s', ME.message);
    end
end

function generate_source_qc(sSrcPowerMaps, config)
% Generate quality control outputs for source analysis following tutorial_omega pattern

    if ~isfield(config, 'generate_qa_plots') || ~config.generate_qa_plots
        return;
    end
    
    fprintf('  Generating source space quality control outputs...\n');
    
    try
        % Generate snapshots of source power maps for different frequency bands
        for i = 1:length(sSrcPowerMaps)
            % Screen capture of source results - following tutorial_omega
            hFig = view_surface_data([], sSrcPowerMaps(i).FileName);
            if ~isempty(hFig)
                set(hFig, 'Position', [200 200 200 200]);
                hFigContact = view_contactsheet(hFig, 'freq', 'fig');
                bst_report('Snapshot', hFigContact, sSrcPowerMaps(i).FileName, 'Source Power Maps');
                close([hFig, hFigContact]);
            end
        end
        
        fprintf('    Source quality control outputs generated.\n');
        
    catch ME
        warning('BST:SourceQC', 'Source quality control output generation failed: %s', ME.message);
    end
end

function save_source_results(sSrcPowerMaps, output_dir, config)
% Save source analysis results with BIDS derivatives compliance
% Following Brainstorm's file structure and metadata

    if isempty(sSrcPowerMaps)
        return;
    end
    
    fprintf('  Saving source analysis results...\n');
    
    for i = 1:length(sSrcPowerMaps)
        try
            % Get file information
            [sStudy, ~] = bst_get('AnyFile', sSrcPowerMaps(i).FileName);
            [sSubject, ~] = bst_get('Subject', sStudy.BrainStormSubject);
            
            % Create output filename with BIDS naming
            [~, file_base, ~] = fileparts(sSrcPowerMaps(i).FileName);
            output_filename = [file_base '_space-source_power.mat'];
            
            % Create output directory structure (BIDS derivatives)
            if contains(sSubject.Name, 'ses-')
                % Extract subject and session from name
                name_parts = strsplit(sSubject.Name, {'sub-', 'ses-'});
                sub_id = name_parts{2};
                ses_id = strsplit(name_parts{3}, '/');
                ses_id = ses_id{1};
                
                out_dir = fullfile(output_dir, 'derivatives', 'brainstorm', ...
                    ['sub-' sub_id], ['ses-' ses_id], 'source');
            else
                % Subject only
                sub_id = strrep(sSubject.Name, 'sub-', '');
                out_dir = fullfile(output_dir, 'derivatives', 'brainstorm', ...
                    ['sub-' sub_id], 'source');
            end
            
            if ~exist(out_dir, 'dir')
                mkdir(out_dir);
            end
            
            % Create JSON sidecar
            json_file = fullfile(out_dir, strrep(output_filename, '.mat', '.json'));
            metadata = create_source_metadata(config);
            write_json(json_file, metadata);
            
            fprintf('    Saved source analysis metadata: %s\n', json_file);
            
        catch ME
            warning('BST:SaveSource', 'Failed to save metadata for file %s: %s', ...
                sSrcPowerMaps(i).FileName, ME.message);
        end
    end
end

function config = load_source_config()
% Load default source analysis configuration

    config = struct();
    
    % Source analysis parameters
    config.source_analysis.noise_tag = 'task-noise';  % Tag for noise recordings
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
end

function metadata = create_source_metadata(config)
% Create source analysis metadata for JSON sidecar following BIDS derivatives

    metadata = struct();
    metadata.Description = 'Source-level power maps computed using Brainstorm';
    metadata.GeneratedBy = struct( ...
        'Name', 'bids-apps-brainstorm', ...
        'Version', '1.0.0', ...
        'Container', struct('Type', 'docker'));
    
    % Processing parameters
    metadata.ProcessingSteps = {};
    
    metadata.ProcessingSteps{end+1} = struct( ...
        'Name', 'NoiseCovariance', ...
        'Parameters', struct('method', 'empirical'));
    
    metadata.ProcessingSteps{end+1} = struct( ...
        'Name', 'HeadModel', ...
        'Parameters', struct('method', 'overlapping_spheres'));
    
    metadata.ProcessingSteps{end+1} = struct( ...
        'Name', 'InverseSolution', ...
        'Parameters', struct( ...
            'method', config.inverse_method, ...
            'snr', config.snr));
    
    metadata.ProcessingSteps{end+1} = struct( ...
        'Name', 'PowerSpectrumDensity', ...
        'Parameters', struct( ...
            'method', 'Welch', ...
            'window_length', 4, ...
            'overlap', 50));
    
    metadata.ProcessingSteps{end+1} = struct( ...
        'Name', 'SpectrumNormalization', ...
        'Parameters', struct('method', 'relative'));
    
    metadata.ProcessingSteps{end+1} = struct( ...
        'Name', 'SpatialSmoothing', ...
        'Parameters', struct('fwhm', 3));
    
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