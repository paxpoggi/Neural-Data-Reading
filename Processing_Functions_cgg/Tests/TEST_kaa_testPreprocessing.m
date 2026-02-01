%% TEST_kaa_testPreprocessing
% Master test runner for all preprocessing-related tests
%
% This script runs all preprocessing tests:
% 1. Synthetic data preprocessing tests
% 2. Individual function tests (if any)
%
% Author: kaa

clc; clear; close all;

fprintf('========================================\n');
fprintf('  Preprocessing Test Suite\n');
fprintf('  Author: kaa\n');
fprintf('========================================\n\n');

%% Add Preprocessing test directory to path
test_dir = fileparts(mfilename('fullpath'));
preprocessing_test_dir = fullfile(test_dir, 'Preprocessing');
if exist(preprocessing_test_dir, 'dir')
    addpath(preprocessing_test_dir);
else
    fprintf('ERROR: Preprocessing test directory not found: %s\n', preprocessing_test_dir);
    return;
end

%% Test Results Tracking
test_results = struct();
test_results.total = 0;
test_results.passed = 0;
test_results.failed = 0;
test_results.tests = {};

%% Test 1: Synthetic Data Preprocessing
fprintf('\n--- Test 1: Synthetic Data Preprocessing ---\n');
test_results.total = test_results.total + 1;
try
    TEST_kaa_testPreprocessingWithSyntheticData;
    test_results.passed = test_results.passed + 1;
    test_results.tests{end+1} = struct('name', 'Synthetic Data Preprocessing', 'status', 'PASSED');
    fprintf('\n✓ Test 1 PASSED\n');
catch ME
    test_results.failed = test_results.failed + 1;
    test_results.tests{end+1} = struct('name', 'Synthetic Data Preprocessing', 'status', 'FAILED', 'error', ME.message);
    fprintf('\n✗ Test 1 FAILED: %s\n', ME.message);
    fprintf('  Stack trace:\n');
    for i = 1:min(3, length(ME.stack))
        fprintf('    %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end

%% Test 2: Full Preprocessing Pipeline
fprintf('\n--- Test 2: Full Preprocessing Pipeline ---\n');
test_results.total = test_results.total + 1;
try
    TEST_kaa_testFullPreprocessingPipeline;
    test_results.passed = test_results.passed + 1;
    test_results.tests{end+1} = struct('name', 'Full Preprocessing Pipeline', 'status', 'PASSED');
    fprintf('\n✓ Test 2 PASSED\n');
catch ME
    test_results.failed = test_results.failed + 1;
    test_results.tests{end+1} = struct('name', 'Full Preprocessing Pipeline', 'status', 'FAILED', 'error', ME.message);
    fprintf('\n✗ Test 2 FAILED: %s\n', ME.message);
    fprintf('  Stack trace:\n');
    for i = 1:min(3, length(ME.stack))
        fprintf('    %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end

%% Summary
fprintf('\n========================================\n');
fprintf('  Test Summary\n');
fprintf('========================================\n');
fprintf('Total tests: %d\n', test_results.total);
fprintf('Passed: %d\n', test_results.passed);
fprintf('Failed: %d\n', test_results.failed);
fprintf('\n');

if test_results.failed == 0
    fprintf('✓ All preprocessing tests PASSED\n');
else
    fprintf('✗ Some preprocessing tests FAILED\n');
    fprintf('\nFailed tests:\n');
    for i = 1:length(test_results.tests)
        if strcmp(test_results.tests{i}.status, 'FAILED')
            fprintf('  - %s: %s\n', test_results.tests{i}.name, test_results.tests{i}.error);
        end
    end
end

fprintf('\n========================================\n');
fprintf('Test suite completed.\n');
fprintf('========================================\n');

