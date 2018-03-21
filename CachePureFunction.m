function varargout = CachePureFunction(varargin)
%CACHEPUREFUNCTION Cache the results of a function call
%   y = CACHEPUREFUNCTION(@f, x) will call the function f with argument x
%   (i.e. evaluate y = f(x)) and store the result to a cache file.
%   Subsequent calls will load the result from disk instead of doing the
%   evaluation.
%
%   [y1, y2, ...] = CACHEPUREFUNCTION(@f, x1, x2, ...) will do the same,
%   but evaluating [y1, y2, ...] = f(x1, x2, ...)
%
%   [y1, y2, ...] = CACHEPUREFUNCTION(folder, @f, x1, x2, ...) will
%   generate the cache file in the specified folder. The folder will be
%   created if necessary. It can be an absolute path, or relative to the
%   current working directory.
%
%   A hash of all input arguments is used to detect different inputs, and
%   seperate cache files are generated for each different set of input
%   arguments.
%
%   Funtion dependencies are tracked, and if the function (or any function
%   it depends on) is modified, then the result is reevaluated. This check
%   is based on the modification timestamps on the function files and the
%   cache file.
%
%   If any of the input arguments are valid filenames which match existing
%   files, the modification timestamp of these files is also checked
%   against the cache timestamp.

%   Copyright 2016-2018 Ian Sheret

% Parse inputs
if nargin<1
    error('Target function not supplied.');
end
if isa(varargin{1}, 'function_handle')
    custom_folder = false;
    folder  = pwd;
    command = varargin{1};
    args    = varargin(2:end);
else
    if nargin<2
        error('Target function not supplied.');
    end
    if isa(varargin{2}, 'function_handle')
        custom_folder = true;
        folder  = varargin{1};
        command = varargin{2};
        args    = varargin(3:end);
    else
        error('Target function not supplied.');
    end
end

% Make sure the cache folder exists
if custom_folder
    [did_succeed, message, message_id] = mkdir(folder);
    if ~did_succeed
        error(message_id, message);
    end
end

% Get a hash of the arguments. Note that the number of output arguments
% (nargout) can affect what a function does, so has to be regarded as an
% input argument here.
hash = DataHash({command, args, nargout});

% Get cache filename
command_info = functions(command);
if strcmp(command_info.type, 'anonymous')
    header = 'anonymous';
else
    header = command_info.function;
end
filename = fullfile(folder, [header, '_', hash, '.mat']);

% Check if a cache exists, and if so check if it's up to date.
d = dir(filename);
update_needed = true;
if ~isempty(d)
    
    % Load the cache
    s         = load(filename);
    varargout = s.varargout;
    deps      = s.deps;
    t_cache   = d(1).datenum;
    
    % Check if any of the dependencies have been modified
    update_needed = false;
    for dep=deps'
        d = dir(dep{1});
        if d(1).datenum >= t_cache
            update_needed = true;
            break
        end
    end
    
    % Check if any of the input arguments is obviously a filename. If so,
    % check if that file has been modified.
    for arg=args
        is_text = isstring(arg{1}) || ischar(arg{1});
        if is_text && exist(arg{1}, 'file')==2
            d = dir(arg{1});
            if d(1).datenum >= t_cache
                update_needed = true;
                break
            end
        end
    end
    
end
        
% Execute the command, if needed
if update_needed
    
    % Clear all the functions in memory. After we execute the target
    % function, we'll be able to check what got loaded, and hence see the
    % dependencies.
    clear functions
    
    % Functions in current stack won't get cleared. Store these so we can
    % exclude them later.
    [M0, MEX0] = inmem('-completenames');
    
    % Execute the command. We need to treat 'no output arguments' as a
    % special case.
    if nargout==0
        command(args{:});
        varargout = {ans};
    else
        [varargout{1:nargout}] = command(args{:});
    end
    
    % Form a list of dependencies
    [M, MEX] = inmem('-completenames');
    
    % Remove spurious items (i.e. functions which are in memory because
    % they're in the current stack, not because they are dependencies).
    M   = setdiff(M, M0);
    MEX = setdiff(MEX, MEX0); 
    
    % Save
    deps = [M; MEX];
    save(filename, 'varargout', 'deps');

end

end
