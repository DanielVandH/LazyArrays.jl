using LazyArrays, Test

@testset "BroadcastArray" begin
    a = randn(6)
    b = BroadcastArray(exp, a)
    @test BroadcastArray(b) == BroadcastVector(b) == b

    @test b ==  Vector(b) == exp.(a)
    @test b[2:5] isa BroadcastVector
    @test b[2:5] == exp.(a[2:5])

    @test exp.(b) isa BroadcastVector
    @test b .+ SVector(1,2,3,4,5,6) isa BroadcastVector
    @test SVector(1,2,3,4,5,6) .+ b isa BroadcastVector

    A = randn(6,6)
    B = BroadcastArray(exp, A)
    
    @test Matrix(B) == exp.(A)


    C = BroadcastArray(+, A, 2)
    @test C == A .+ 2
    D = BroadcastArray(+, A, C)
    @test D == A + C

    @test sum(B) ≈ sum(exp, A)
    @test sum(C) ≈ sum(A .+ 2)
    @test prod(B) ≈ prod(exp, A)
    @test prod(C) ≈ prod(A .+ 2)

    x = Vcat([3,4], [1,1,1,1,1], 1:3)
    @test x .+ (1:10) isa Vcat
    @test (1:10) .+ x isa Vcat
    @test x + (1:10) isa Vcat
    @test (1:10) + x isa Vcat
    @test x .+ (1:10) == (1:10) .+ x == (1:10) + x == x + (1:10) == Vector(x) + (1:10)

    @test exp.(x) isa Vcat
    @test exp.(x) == exp.(Vector(x))
    @test x .+ 2 isa Vcat
    @test (x .+ 2).args[end] ≡ x.args[end] .+ 2 ≡ 3:5
    @test x .* 2 isa Vcat
    @test 2 .+ x isa Vcat
    @test 2 .* x isa Vcat

    A = Vcat([[1 2; 3 4]], [[4 5; 6 7]])
    @test A .+ Ref(I) == Ref(I) .+ A == Vcat([[2 2; 3 5]], [[5 5; 6 8]])

    @test_broken BroadcastArray(*,1.1,[1 2])[1] == 1.1

    B = BroadcastArray(*, Diagonal(randn(5)), randn(5,5))
    @test B == broadcast(*,B.args...)
    @test colsupport(B,1) == rowsupport(B,1) == 1:1
    @test colsupport(B,3) == rowsupport(B,3) == 3:3
    @test colsupport(B,5) == rowsupport(B,5) == 5:5
    B = BroadcastArray(*, Diagonal(randn(5)), 2)
    @test B == broadcast(*,B.args...)
    @test colsupport(B,1) == rowsupport(B,1) == 1:1
    @test colsupport(B,3) == rowsupport(B,3) == 3:3
    @test colsupport(B,5) == rowsupport(B,5) == 5:5
    B = BroadcastArray(*, Diagonal(randn(5)), randn(5))
    @test B == broadcast(*,B.args...)
    @test colsupport(B,1) == rowsupport(B,1) == 1:1
    @test colsupport(B,3) == rowsupport(B,3) == 3:3
    @test colsupport(B,5) == rowsupport(B,5) == 5:5

    B = BroadcastArray(+, Diagonal(randn(5)), 2)
    @test colsupport(B,1) == rowsupport(B,1) == 1:5
    @test colsupport(B,3) == rowsupport(B,3) == 1:5
    @test colsupport(B,5) == rowsupport(B,5) == 1:5
end

@testset "vector*matrix broadcasting #27" begin
    H = [1., 0.]
    @test Mul(H, H') .+ 1 == H*H' .+ 1
    B =  randn(2,2)
    @test Mul(H, H') .+ B == H*H' .+ B
end

@testset "BroadcastArray +" begin
    a = BroadcastArray(+, randn(400), randn(400))
    b = similar(a)
    copyto!(b, a)
    @test @allocated(copyto!(b, a)) == 0
    @test b == a
end

@testset "Lazy range" begin
    @test broadcasted(LazyArrayStyle{1}(), +, 1:5) ≡ 1:5
    @test broadcasted(LazyArrayStyle{1}(), +, 1, 1:5) ≡ 2:6
    @test broadcasted(LazyArrayStyle{1}(), +, 1:5, 1) ≡ 2:6

    @test broadcasted(LazyArrayStyle{1}(), +, Fill(2,5)) ≡ Fill(2,5)
    @test broadcasted(LazyArrayStyle{1}(), +, 1, Fill(2,5)) ≡ Fill(3,5)
    @test broadcasted(LazyArrayStyle{1}(), +, Fill(2,5), 1) ≡ Fill(3,5)
    @test broadcasted(LazyArrayStyle{1}(), +, Ref(1), Fill(2,5)) ≡ Fill(3,5)
    @test broadcasted(LazyArrayStyle{1}(), +, Fill(2,5), Ref(1)) ≡ Fill(3,5)
    @test broadcasted(LazyArrayStyle{1}(), +, 1, Fill(2,5)) ≡ Fill(3,5)
    @test broadcasted(LazyArrayStyle{1}(), +, Fill(2,5), Fill(3,5)) ≡ Fill(5,5)

    @test broadcasted(LazyArrayStyle{1}(), *, Zeros(5), Zeros(5)) ≡ Zeros(5)
    b = BroadcastArray(exp, randn(5))
    @test b .* Zeros(5) ≡ Zeros(5)
    @test Zeros(5) .* b ≡ Zeros(5)
end