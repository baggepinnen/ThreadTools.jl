using ThreadTools, Test, Base.Threads

@show nthreads()

@testset "ThreadTools" begin
    l = SpinLock()

    times = []
    @spawnatmost 1 for i = 1:6
        push!(times, time())
        sleep(1.1)
    end
    @test all(>(1), diff(times))

    times = []
    @spawnatmost 2 for i = 1:10
        withlock(l) do
            push!(times, time())
        end
        sleep(1.1)
    end
    @show round.(diff(times), digits=2)
    @test all(<(1), sort(diff(times))[1:4])
    @test all(>(1), sort(diff(times))[6:8])

    @test tmap(identity, 1:10) == 1:10
    @test tmap(identity, 2, 1:10) == 1:10

    @test tmap(identity, enumerate(1:10)) == collect(zip(1:10,1:10))
    @test tmap(identity, 2, enumerate(1:10)) == collect(zip(1:10,1:10))

    @test tmap(+, 1:10, 21:30) == (1:10) .+ (21:30)
    @test tmap(+, 2, 1:10, 21:30) == (1:10) .+ (21:30)

    @test tmap(identity, 1:100_000) == 1:100_000
    @test tmap(identity, 2, 1:100_000) == 1:100_000

    @test tmap1(identity, 1:100_000) == 1:100_000
    @test tmap1(identity, 2, 1:100_000) == 1:100_000

    times = tmap(_->(t=time();sleep(1.1);t), 2, 1:10)
    @show round.(diff(times), digits=2)
    @test all(<(1), sort(diff(times))[1:4])


    a = [0]
    @threads for i = 1:10000
        withlock(l) do
            a[] += 1
        end
    end
    @test a[] == 10000

    a = [0]
    @threads for i = 1:10000
        ThreadTools.@withlock l (a[] += 1)
    end
    @test a[] == 10000

end
