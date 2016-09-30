# CachePureFunction

### What is it?

CachePureFunction is a simple tool for caching the results of expensive calculations. Any function call can be wrapped up; the first time it's evaluated a cache file will be created, and on subsequent calls the result will be read from disk instead of calculated. Calling the same function with different arguments is fine, separate cache files will be maintained.

CachePureFunction takes special care to detect when the source code changes, and it will reevaluate the function if needed. This doesn't just apply to the top level function, all of the functions which are involved in a calculation are tracked.

### Example

Say we have slow calculation to do.

```matlab
function y = SlowFunction(x)
pause(3);
y = x + 1;
end
```

Instead of calling it directly, we can wrap it in CachePureFunction

```
>> tic; y = CachePureFunction(@SlowFunction, 5); fprintf('y = %i\n', y); toc;
y = 6
Elapsed time is 3.146340 seconds.
```

The first call is still slow, but if we make the same call again:

```
>> tic; y = CachePureFunction(@SlowFunction, 5); fprintf('y = %i\n', y); toc;
y = 6
Elapsed time is 0.074329 seconds.
```

This time it's much faster. The result has been read from the cache file, not calculated.

Changing the function argument will make a new cache file. The previous result is still stored.

```
>> tic; y = CachePureFunction(@SlowFunction, 6); fprintf('y = %i\n', y); toc;
y = 7
Elapsed time is 3.033608 seconds.
>> tic; y = CachePureFunction(@SlowFunction, 6); fprintf('y = %i\n', y); toc;
y = 7
Elapsed time is 0.077687 seconds.
>> tic; y = CachePureFunction(@SlowFunction, 5); fprintf('y = %i\n', y); toc;
y = 6
Elapsed time is 0.013021 seconds.
```
### Detecting source code changes
Lets change the source code of the target function:

```matlab
function y = SlowFunction(x)
pause(3);
y = 2*x + 1;
end
```

CachePureFunction will detect that and reevaluate the function.

```
>> tic; y = CachePureFunction(@SlowFunction, 5); fprintf('y = %i\n', y); toc;
y = 11
Elapsed time is 3.088573 seconds.
```

A more tricky example is if we change a dependency, but leave the actual target function alone. Set up a function with a dependency:


```matlab
function y = ScaleAndOffset(x)
y = Scale(x) + 2;
end
```

```matlab
function y = Scale(x)
y = 3*x;
end
```

Note these functions are in separate files. On the first evaluation, a cache file will be created.

```
>> y = CachePureFunction(@ScaleAndOffset, 2); fprintf('y = %i\n', y);
y = 8
```

Now, modify the dependency:

```matlab
function y = Scale(x)
y = 4*x;
end
```

CachePureFunction will detect the change, and reevaluate the function.

```
>> y = CachePureFunction(@ScaleAndOffset, 2); fprintf('y = %i\n', y);
y = 8
```

### Specifying a cache directory
By default, all these cache files are placed in the current working directory. It's generally neater to put them in a special directory, like this:

```matlab
y = CachePureFunction('Cache', @ScaleAndOffset, 2);
```
This will place the cache file in a folder named `Cache`. If this folder doesn't already exist it will be created.

If I'm going cache a few results in sequence, I make an anonymous function so I don't have to keep repeating the name of the cache folder:

```matlab
cache = @(varargin) CachePureFunction('Cache', varargin{:});
y = cache(@SlowFunction_1, x);
z = cache(@SlowFunction_2, y);
...
```

### How does it work?
The target function and input arguments are hashed (using [DataHash](https://www.mathworks.com/matlabcentral/fileexchange/31272-datahash) by Jan Simon), and this is used to generate a cache filename. If the file doesn't exist, the target function is evaluated, and the results are saved. If it does exist, the result is loaded from file.

To check for changes in the source code, the first evaluation makes list of all the functions which are used , and stores this in the cache file. When the cache data is loaded, the modification timestamp on each function is checked; if it's been modified since the cache file was created, then the cache must be out of date.

To get the list of all functions used, `clear functions` is called before the evaluation, and `inmem` is called after. Clearing all the functions like this will cost some time, but since the target function is slow anyway I think it's a reasonable trade off.

### Related code
There's a similar function called [cache_results](https://mathworks.com/matlabcentral/fileexchange/37465-cache-results) by Dan Ellis on the File Exchange, though this doesn't have detection of source code changes.
