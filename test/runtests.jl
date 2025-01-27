# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

using Test
using FAME

using TimeSeriesEcon

if FAME.chli.lib === nothing

    @error "FAME CHLI library not found"
    exit()

end

@testset "workspaces" begin
    w = Workspace(; a = 1, b = TSeries(2020Q1, randn(10)),
        s = MVTSeries(2020M1, (:q, :p), randn(24, 2)),
        c = Workspace(; alpha = 0.1, beta = 0.8,
            n = Workspace(; s = "Hello World")
        ))
    writefame("data.db", w)
    @test length(listdb("data.db")) == 7

    tmp = readfame("data.db")
    @test tmp isa Workspace && length(tmp) == 7
    @test issubset(keys(tmp), (:a, :b, :c_alpha, :c_beta, :c_n_s, :s_p, :s_q))

    tmp = readfame("data.db", "s?")
    @test tmp isa Workspace && length(tmp) == 2
    @test issubset(keys(tmp), (:s_p, :s_q))

    tmp = readfame("data.db", "s?", prefix = "s")
    @test tmp isa Workspace && length(tmp) == 2
    @test issubset(keys(tmp), (:p, :q))

    tmp = readfame("data.db", "c?", collect = "c")
    @test tmp isa Workspace && length(tmp) == 1
    @test issubset(keys(tmp), (:c,))
    @test tmp.c isa Workspace && length(tmp.c) == 3
    @test issubset(keys(tmp.c), (:alpha, :beta, :n_s))

    tmp = readfame("data.db", collect = ["c" => ["n"], "s"])
    @test tmp isa Workspace && length(tmp) == 4
    @test issubset(keys(tmp), (:a, :b, :c, :s))
    @test tmp.c isa Workspace && length(tmp.c) == 3
    @test issubset(keys(tmp.c), (:alpha, :beta, :n))
    @test tmp.c.n isa Workspace && length(tmp.c.n) == 1
    @test issubset(keys(tmp.c.n), (:s,))
    @test tmp.s isa Workspace && length(tmp.s) == 2
    @test issubset(keys(tmp.s), (:p, :q))

    rm("data.db")
end

@testset "missing" begin
    FAME.init_chli()
    pr = TSeries(2020Q1, randn(Float64, 8))
    pr[2020Q4] = NaN
    nu = TSeries(2020Q1, randn(Float32, 8))
    nu[2020Q4] = NaN
    writefame(workdb(), Workspace(; pr, nu))
    for n in ("pr", "nu")
        let b = IOBuffer()
            fame(b, "disp $n")
            seek(b, 0)
            @test sum(Base.Fix1(occursin, r"20:4\s+NC"), readlines(b)) == 1
        end
    end
end
