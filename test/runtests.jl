using ThreadTools, Test, Base.Threads

@testset "ThreadTools" begin
times = []
@spawnatmost 1 for i = 1:10
    push!(times, time())
    sleep(1)
end
@test all(>(1), diff(times))

times = []
@spawnatmost 2 for i = 1:10
    push!(times, time())
    sleep(1)
end
@test (nthreads() > 1 && all(<(1), sort(diff(times))[1:4])) || (nthreads() == 1 && all(>(1), sort(diff(times))[1:4]))
@test all(>(1), sort(diff(times))[5:8])

@test tmap(identity, 1:10) == 1:10
@test tmap(identity, 2, 1:10) == 1:10

@test tmap(identity, 1:100_000) == 1:100_000
@test tmap(identity, 2, 1:100_000) == 1:100_000

times = tmap(_->(t=time();sleep(0.3);t), 3, 1:10)
round.(diff(times), digits=2)


l = SpinLock()
a = [0]
@threads for i = 1:10000
    withlock(l) do
        a[] += 1
    end
end
@test a[] == 10000

end
