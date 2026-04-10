%% PHASE 1 & 2: Calibration
clear; clc;

% --- SETTINGS ---
filename = "C:\Users\Admin\Documents\OpenSignals (r)evolution\files\PierreLouisTruth.txt"; % Change to 'lie_base.txt' for the second run
saveName = 'truth_profile.mat'; % Change to 'lie_profile.mat' for the second run
fs = 1000;

% 1. Import
% Skip the first 3 lines of OpenSignals header
try
    data = readmatrix(filename, 'HeaderLines', 3); 
catch
   
    data = dlmread(filename, '\t', 3, 0); 
end

% 2. Auto-select column with most variance (the sensor)
vars = std(data);
[~, col_idx] = max(vars(2:end)); 
signal = data(:, col_idx + 1);

% 3. Normalize and Find Peaks
signal_norm = (signal - mean(signal)) / std(signal);
if skewness(signal_norm) < 0, signal_norm = -signal_norm; end

[pks, locs] = findpeaks(signal_norm, 'MinPeakHeight', 0.5, 'MinPeakDistance', fs*0.5);
avg_bpm = mean(60 ./ diff(locs/fs));

% 4. Save
save(saveName, 'avg_bpm');
fprintf('Profile saved to %s: %.2f BPM\n', saveName, avg_bpm);
%% PHASE 3: Stimulus (Ask) and Response (Calculate) Logic
clear; clc; close all;

% 1. Load your Saved Baselines
if exist('truth_profile.mat', 'file') && exist('lie_profile.mat', 'file')
    load('truth_profile.mat'); truth_base = avg_bpm;
    load('lie_profile.mat');   lie_base   = avg_bpm;
else
    error('Missing calibration files! Run Phase 1 & 2 first.');
end

% 2. Import TEST session file
test_file = "C:\Users\Admin\Documents\OpenSignals (r)evolution\files\PierreLouisTest.txt"; 
fs = 1000;
try
    data = readmatrix(test_file, 'HeaderLines', 3);
catch
    data = dlmread(test_file, '\t', 3, 0);
end

% 3. Extract Heart Rate Signal
[~, col_idx] = max(std(data(:, 2:end)));
sig = data(:, col_idx + 1);
sig_norm = (sig - mean(sig)) / std(sig);
if skewness(sig_norm) < 0, sig_norm = -sig_norm; end

% Find peaks and calculate BPM
[~, locs] = findpeaks(sig_norm, 'MinPeakHeight', 0.5, 'MinPeakDistance', fs*0.5);
peak_times = locs/fs;
bpm = 60 ./ diff(peak_times);
bpm_time = peak_times(2:end);

% 4. Define your Timeline Segments
% Columns: [Start_Ask, End_Ask, Start_Response, End_Response]
timeline = [
     0, 10, 10, 15;  % Q1: Ask 0-10s, Calculate 10-15s
    15, 25, 25, 30;  % Q2: Ask 15-25s, Calculate 25-30s
    30, 40, 40, 45   % Q3: Ask 30-40s, Calculate 40-45s
];
labels = {'Question 1', 'Question 2', 'Question 3'};

% 5. Comparison Logic
stress_span = lie_base - truth_base;
results_scores = zeros(1, size(timeline,1)); 
response_bpms = zeros(1, size(timeline,1));

fprintf('\n--- SEGMENTED RESPONSE RESULTS ---\n');
for i = 1:size(timeline, 1)
    % Extract BPM only during the RESPONSE window (the 5s after asking)
    resp_start = timeline(i, 3);
    resp_end   = timeline(i, 4);
    
    idx = (bpm_time >= resp_start & bpm_time <= resp_end);
    q_bpm = mean(bpm(idx));
    response_bpms(i) = q_bpm;
    
    % Lie Probability Calculation
    score = ((q_bpm - truth_base) / stress_span) * 100;
    score = max(0, min(100, score)); 
    results_scores(i) = score; 
    
    fprintf('%s: Response Window %d-%ds | Avg BPM: %.2f | Lie Prob: %.1f%%\n', ...
            labels{i}, resp_start, resp_end, q_bpm, score);
end

%% 6. Visualization with Phase Shading
figure('Color', 'w', 'Name', 'Segmented Polygraph', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);

subplot(2,1,1);
plot(bpm_time, bpm, 'k', 'LineWidth', 1.5); hold on;
yline(truth_base, 'g--', 'Truth Base', 'LineWidth', 2);
yline(lie_base, 'r--', 'Lie Base', 'LineWidth', 2);

% Shading logic
y_lims = ylim;
for i = 1:size(timeline,1)
    % Gray Shade for "Asking" phase
    patch([timeline(i,1) timeline(i,2) timeline(i,2) timeline(i,1)], ...
          [y_lims(1) y_lims(1) y_lims(2) y_lims(2)], [0.8 0.8 0.8], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    % Yellow Shade for "Response/Calculation" phase
    patch([timeline(i,3) timeline(i,4) timeline(i,4) timeline(i,3)], ...
          [y_lims(1) y_lims(1) y_lims(2) y_lims(2)], [1 0.9 0], 'FaceAlpha', 0.4, 'EdgeColor', 'none');
      
    text(timeline(i,1), y_lims(2)*0.95, ['Ask ', num2str(i)], 'FontSize', 8);
    text(timeline(i,3), y_lims(2)*0.85, 'CALC', 'Color', 'r', 'FontWeight', 'bold');
end

ylabel('BPM'); title('BPM Analysis: Asking Phase (Gray) vs Response Phase (Yellow)');
grid on; xlim([0, 50]);

subplot(2,1,2);
b = bar(results_scores, 'FaceColor', [0.2 0.6 0.8]);
set(gca, 'XTickLabel', labels);
ylabel('Lie Probability %'); ylim([0 100]);
title('Probability Score based on 5-Second Response Windows');
grid on;
