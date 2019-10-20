module ThreadTools

using Base.Threads

export @spawnatmost, tmap, tmap1, withlock, @withlock

export @threads, SpinLock, nthreads, @spawn, threadid

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
        Base.sync_end($tasks)
    end
end


"""
    tmap(f, args...)
    tmap(f, nthreads::Int,args...)
    tmap1(f, args...)
    tmap1(f, nthreads::Int,args...)

Threaded map. The optional argument `nthreads` limits the number of threads used in parallel.
`tmap1` is the same as `tmap`, but falls back to a regular `map` if julia only has access to one thread.
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

function tmap1(f,nt::Int,args...)
    nthreads() == 1 && (return map(f,args...))
    tmap(f,nt,args...)
end

function tmap1(f,args...)
    nthreads() == 1 && (return map(f,args...))
    tmap(f,args...)
end


"""
    @withlock(lock, ex)
Places calss to `lock` and `unlock` around an expression. This macro does not unlock the lock if the expression throws and exception. See also Function `withlock`
"""
macro withlock(l, ex)
    quote
        lock($(esc(l)))
        res = $(esc(ex))
        unlock($(esc(l)))
        res
    end
end

"""
     withlock(f, l::AbstractLock)
Executes Function `f` with a call to `lock` before and `unlock` after. The lock is unlocked even if `f` throws an exception.
"""
function withlock(f, l::Base.AbstractLock)
    lock(l)
    try
        return f()
    finally
        unlock(l)
    end
end

end # module
