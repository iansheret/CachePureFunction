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
>> tic; y = CachePureFunction(@SlowFunction, 5); toc;
Elapsed time is 3.025737 seconds.
```

The first call is still slow, but if we make the same call again:

```
tic; y = CachePureFunction(@SlowFunction, 5); toc;
Elapsed time is 0.074931 seconds.
```

This time it's much faster. The result has been read from the cache file, not calculated.

Changing the function argument will make a new cache file. The previous result is still stored.

```
>> tic; y = CachePureFunction(@SlowFunction, 6); toc;
Elapsed time is 3.099549 seconds.
>> tic; y = CachePureFunction(@SlowFunction, 6); toc;
Elapsed time is 0.075752 seconds.
>> tic; y = CachePureFunction(@SlowFunction, 5); toc;
Elapsed time is 0.010843 seconds.
```
### Detecting source code changes
Lets change the source code of the target function:

```matlab
function y = SlowFunction(x)
pause(3);
y = x + 2;
end
```

CachePureFunction will detect that and reevaluate the function.

```
>> tic; y = CachePureFunction(@SlowFunction, 5); toc;
Elapsed time is 3.030285 seconds.
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
>> CachePureFunction(@ScaleAndOffset, 2)

ans =

     8
```

Now, modify the dependency:

```matlab
function y = Scale(x)
y = 4*x;
end
```

CachePureFunction will detect the change, and reevaluate the function.

```
>> CachePureFunction(@ScaleAndOffset, 2)

ans =

    10
```

