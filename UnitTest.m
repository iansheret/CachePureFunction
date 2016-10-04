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

function MakeCallingFunction()
fid = fopen('TopLevelFunction.m', 'w');
fprintf(fid, 'function TopLevelFunction\n');
fprintf(fid, 'y = CachePureFunction(@CallOffset, 7);\n');
fprintf(fid, 'end\n');
fclose(fid);
pause(1);
end

function RemoveFunctions
delete('Offset.m');
delete('CallOffset.m');
delete('TopLevelFunction.m');
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
rmdir('Cache', 's');
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

function TestSpecifiedFolderIsUsedFromObjectWrapper(testCase)
MakeOffsetFunction(1);
cache = CustomCache('Cache');
a = cache(@CallOffset, 7);
b = cache(@CallOffset, 7);
verifyEqual(testCase, a, 8);
verifyEqual(testCase, b, 8);
d = dir(fullfile('Cache', 'CallOffset_*.mat'));
verifyEqual(testCase, length(d), 1);
rmdir('Cache', 's');
end

function TestCallingFunctionIsNotADependency(testCase)
global function_evaluated

MakeCallingFunction();
MakeOffsetFunction(1);

function_evaluated = false;
TopLevelFunction();
verifyEqual(testCase, function_evaluated, true);

function_evaluated = false;
MakeCallingFunction();
TopLevelFunction();
verifyEqual(testCase, function_evaluated, false);

end


