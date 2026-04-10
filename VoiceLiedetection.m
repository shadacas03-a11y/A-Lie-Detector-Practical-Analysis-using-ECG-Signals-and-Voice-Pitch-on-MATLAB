% --- RUN THIS FOR YOUR TEST ---
[audioTruth, fs] = audioread("C:\Users\CAMILA CASTRO\Downloads\true6.mp4");
[audioLie, ~]   = audioread("C:\Users\CAMILA CASTRO\Downloads\lie6.mp4");
[audioTest, ~]  = audioread("C:\Users\CAMILA CASTRO\Downloads\test6.mp4");

segLen = 10 * fs;

% Updated helper: ignores silence (NaNs) and finds median
analyzeSeg = @(data, startIdx, endIdx, rate) median(pitch(data(startIdx:endIdx), rate), 'omitnan');

% 1. Get Truth Reference (from 3 segments)
avgTruth = mean([analyzeSeg(audioTruth, 1, segLen, fs); ...
                 analyzeSeg(audioTruth, segLen+1, 2*segLen, fs); ...
                 analyzeSeg(audioTruth, 2*segLen+1, 3*segLen, fs)]);

% 2. Get Lie Reference (from 3 segments)
avgLie = mean([analyzeSeg(audioLie, 1, segLen, fs); ...
               analyzeSeg(audioLie, segLen+1, 2*segLen, fs); ...
               analyzeSeg(audioLie, 2*segLen+1, 3*segLen, fs)]);

% 3. Process the Test File
numQ = floor(length(audioTest) / segLen);
results = zeros(numQ, 1);
for i = 1:numQ
    results(i) = analyzeSeg(audioTest, ((i-1)*segLen)+1, i*segLen, fs);
end

% 4. Quick Report
figure('Color', 'w');
bar(results);
hold on;
yline(avgTruth, 'g--', 'Truth Ref');
yline(avgLie, 'r--', 'Lie Ref');
title('Real-Time Voice Analysis');
ylabel('Pitch (Hz)');
xlabel('Question Number');

%%Code modifications for filtering

% 1. Settings
targetFs = 16000; % Downsampling to 16kHz to save memory
segLenSec = 10;
segLen = segLenSec * targetFs;

% Helper function to load, downsample, and filter in one go
% This prevents loading massive files into RAM
prepareAudio = @(path) bandpass(resample(mean(audioread(path), 2), targetFs, ...
    audioinfo(path).SampleRate), [70 450], targetFs);

fprintf('Loading and processing files... (this may take a moment)\n');

% 2. Load and Process one by one to save RAM
audioTruth = prepareAudio("C:\Users\CAMILA CASTRO\Downloads\true6.mp4");
audioLie   = prepareAudio("C:\Users\CAMILA CASTRO\Downloads\lie6.mp4");
audioTest  = prepareAudio("C:\Users\CAMILA CASTRO\Downloads\test6.mp4");

% 3. Updated Analysis Function
% Changed method to 'PEF' (Pitch Estimation Filter) - much faster and uses less RAM than SRH
analyzeSeg = @(data, s, e, fs) median(pitch(data(s:e), fs, ...
    'Method', 'PEF', 'Range', [70 400]), 'omitnan');

% 4. Get References
avgTruth = mean([analyzeSeg(audioTruth, 1, segLen, targetFs); ...
                 analyzeSeg(audioTruth, segLen+1, 2*segLen, targetFs); ...
                 analyzeSeg(audioTruth, 2*segLen+1, 3*segLen, targetFs)]);

avgLie = mean([analyzeSeg(audioLie, 1, segLen, targetFs); ...
               analyzeSeg(audioLie, segLen+1, 2*segLen, targetFs); ...
               analyzeSeg(audioLie, 2*segLen+1, 3*segLen, targetFs)]);

% 5. Process Test File
numQ = floor(length(audioTest) / segLen);
results = zeros(numQ, 1);
for i = 1:numQ
    sIdx = ((i-1)*segLen) + 1;
    eIdx = i * segLen;
    results(i) = analyzeSeg(audioTest, sIdx, eIdx, targetFs);
end

% 6. Generate Report
figure('Color', 'w', 'Name', 'Final Voice Analysis');
bar(results, 'FaceColor', [0.4 0.6 0.8]);
hold on;
yline(avgTruth, 'g--', 'Truth Baseline', 'LineWidth', 2);
yline(avgLie, 'r--', 'Lie Baseline', 'LineWidth', 2);
title('Comparison: Questions vs. Truth/Lie Baselines Participant 6');
ylabel('Pitch (Hz)');
xlabel('Question Number');
grid on;

fprintf('Processing Complete!\nTruth: %.2f Hz | Lie: %.2f Hz\n', avgTruth, avgLie);