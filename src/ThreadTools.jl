module ThreadTools

using Base.Threads

export @spawnatmost, tmap, tmap1

export @threads, ReentrantLock, nthreads, @spawn, threadid

"""
    @spawnatmost n for-loop

Spawn at most `n` threads to carry out for-loop
"""
macro spawnatmost(n, ex)
    @assert ex.head == :for
    sem = Base.Semaphore(n)
    tasks = Task[]
    quote
        for $(esc(ex.args[1].args[1])) = $(esc(ex.args[1].args[2]))
            __t = @async begin
                Base.acquire($sem)
                f = Threads.@spawn $(esc(ex.args[2]))
                ff = fetch(f)
                Base.release($sem)
                ff
            end
            push!($tasks, __t)
        end
        wait.($tasks)
    end
end


"""
    tmap(f, args...)
    tmap(f, v, T::DataType)
    tmap(f, nthreads::Int, args...)
    tmap1(f, args...)
    tmap1(f, nthreads::Int, args...)

Threaded map. The optional argument `nthreads` limits the number of threads used in parallel.
`tmap1` is the same as `tmap`, but falls back to a regular `map` if julia only has access to one thread.
If the eltype `T` of the output is specified the call will be type stable.
"""
function tmap(f,nt::Int,args...)
    sem = Base.Semaphore(nt)
    results = map(args...) do (args...)
        @async begin
            Base.acquire(sem)
            rf = Threads.@spawn f(args...)
            r = fetch(rf)
            Base.release(sem)
            r
        end
    end
    fetch.(results)
end

function tmap(f,args...)
    tasks = map(args...) do (args...)
        Threads.@spawn f(args...)
    end
    fetch.(tasks)
end

function tmap(f, v, T::DataType)
    results = Vector{T}(undef, length(v))
    tasks = map(v) do vi
        Threads.@spawn f(vi)
    end
    for i in 1:length(tasks)
        results[i] = fetch(tasks[i])
    end
    results
end

function tmap1(f,nt::Int,args...)
    nthreads() == 1 && (return map(f,args...))
    tmap(f,nt,args...)
end

function tmap1(f,args...)
    nthreads() == 1 && (return map(f,args...))
    tmap(f,args...)
end

"""
    @maybe_threads cond ex

Like `Threads.@threads` except threading can be turned on or off by `cond`
"""
macro maybe_threads(cond, ex)
    return esc(:(
        if $cond
            Threads.@threads $ex
        else
            $ex
        end
    ))
end


end # module
