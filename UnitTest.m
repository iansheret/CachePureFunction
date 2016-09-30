function tests = UnitTest
tests = functiontests(localfunctions);
end


% Fixtures
function setupOnce(testCase)
fid = fopen('CallOffset.m', 'w');
fprintf(fid, 'function y = CallOffset(x)\n');
fprintf(fid, 'global function_evaluated\n');
fprintf(fid, 'y = Offset(x);\n');
fprintf(fid, 'function_evaluated = true;\n');
fprintf(fid, 'end\n');
fclose(fid);

end

function teardownOnce(testCase)
rmdir('Cache', 's');
RemoveFunctions();
RemoveHashFiles();
end


% Setup and teardown example function.
function MakeOffsetFunction(offset)
fid = fopen('Offset.m', 'w');
fprintf(fid, 'function y = Offset(x)\n');
fprintf(fid, 'y = x + %i;\n', offset);
fprintf(fid, 'end\n');
fclose(fid);
pause(1);
end

function RemoveFunctions
delete('Offset.m');
delete('CallOffset.m');
end

function RemoveHashFiles
files = dir('CallOffset_*.mat');
for file=files'
    delete(file.name);
end
end

% The actual tests
function TestChangingArgumentsChangesResult(testCase)
MakeOffsetFunction(1);
a = CachePureFunction(@CallOffset, 7);
b = CachePureFunction(@CallOffset, 8);
verifyEqual(testCase, a, 8);
verifyEqual(testCase, b, 9);
end

function TestChangingDependencyChangesResult(testCase)
MakeOffsetFunction(1);
a = CachePureFunction(@CallOffset, 7);
MakeOffsetFunction(2);
b = CachePureFunction(@CallOffset, 7);
verifyEqual(testCase, a, 8);
verifyEqual(testCase, b, 9);
end

function TestChangingNothingDoesNotCauseEvaluation(testCase)
global function_evaluated

MakeOffsetFunction(1);

function_evaluated = false;
a = CachePureFunction(@CallOffset, 7);
verifyEqual(testCase, a, 8);
verifyEqual(testCase, function_evaluated, true);

function_evaluated = false;
b = CachePureFunction(@CallOffset, 7);
verifyEqual(testCase, b, 8);
verifyEqual(testCase, function_evaluated, false);

end

function TestSpecifiedFolderIsUsed(testCase)
MakeOffsetFunction(1);
a = CachePureFunction('Cache', @CallOffset, 7);
b = CachePureFunction('Cache', @CallOffset, 7);
verifyEqual(testCase, a, 8);
verifyEqual(testCase, b, 8);
d = dir(fullfile('Cache', 'CallOffset_*.mat'));
verifyEqual(testCase, length(d), 1);
end

function TestCacheUpdatesWithNoReturnArgs(testCase)
MakeOffsetFunction(1);
CachePureFunction(@CallOffset, 7);
a = ans;
MakeOffsetFunction(2);
CachePureFunction(@CallOffset, 7);
b = ans;
verifyEqual(testCase, a, 8);
verifyEqual(testCase, b, 9);
end
