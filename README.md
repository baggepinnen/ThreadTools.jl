[![Build Status](https://travis-ci.org/baggepinnen/ThreadTools.jl.svg?branch=master)](https://travis-ci.org/baggepinnen/ThreadTools.jl)
[![codecov](https://codecov.io/gh/baggepinnen/ThreadTools.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/baggepinnen/ThreadTools.jl)

# ThreadTools
This package implements some utilities for using threads in Julia v1.3.

The utilities provided are:
```julia
"""
    @spawnatmost n for-loop

Spawn at most `n` threads to carry out for-loop
"""
macro spawnatmost(n, ex)

"""
    tmap(f, args...)
    tmap(f, nthreads::Int,args...)

Threaded map. The optional argument `nthreads` limits the number of threads used in parallel.
"""
function tmap(f,nt::Int,args...)

"""
     withlock(f, l::AbstractLock)
Executes Function `f` with a call to `lock` before and `unlock` after. The lock is unlocked even if `f` throws an exception.
"""
function withlock(f, l::Base.AbstractLock)
```

# Examples
```julia
using ThreadTools

julia> times = [];
julia> @spawnatmost 3 for i = 1:10 # This will use only three parallel threads, even if more are avilable
           push!(times, time())
           println(i)
           sleep(1)
       end

julia> round.(diff(times), digits=3)
7-element Array{Float64,1}:
 1.002
 0.0  
 0.0  
 1.002
 0.0  
 0.0  
 1.002

julia> tmap(_->threadid(), 1:5) # A threaded version of map
5-element Array{Int64,1}:
 2
 6
 3
 4
 5

 julia> times = tmap(_->(t=time();sleep(0.3);t), 3, 1:10); # The second argument limits the number of threads used
 julia> round.(diff(times), digits=2)
 9-element Array{Float64,1}:
  0.0
  0.0
  0.3
  0.0
  0.0
  0.3
  0.0
  0.0
  0.3

julia> l = SpinLock();
julia> a = [0];
julia> @threads for i = 1:10000 # If we protect the access to a using a lock, this works as expected
           withlock(l) do
               a[] += 1
           end
       end

julia> a[] == 10000
true

julia> a = [0];
julia> @threads for i = 1:10000 # If we do not protect access, we get a nondeterministic result
           a[] += 1
       end
julia> a[] == 10000
false
```
