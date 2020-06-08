module Benchmarks exposing (main)

import Benchmark exposing (..)
import Benchmark.Runner exposing (BenchmarkProgram, program)
import SafeInt exposing (SafeInt)
import SafeInt.Unchecked as Unchecked


main : BenchmarkProgram
main =
    program <|
        describe "All"
            [ -- benchmarkAddModBy
              benchmarkAddMul

            -- benchmarkAddPow
            -- benchmarkAddRemainderBy
            -- benchmarkDiv
            -- benchmarkDivMod
            -- benchmarkFromInt
            -- benchmarkQuotient
            ]



-- BENCHMARK SETS


benchmarkAddMul =
    describe "add & mul (1*1 + 2*2 + ... + 100*100)"
        [ benchmark "Int" <|
            \_ ->
                List.foldl
                    (\x sum -> sum + x * x)
                    0
                    oneToHundredInt
        , benchmark "Float" <|
            \_ ->
                List.foldl
                    (\x sum -> sum + x * x)
                    0.0
                    oneToHundredFloat
        , benchmark "Unchecked" <|
            \_ ->
                List.foldl
                    (\x sum -> Unchecked.add sum (Unchecked.mul x x))
                    0.0
                    oneToHundredFloat
        , benchmark "SafeInt" <|
            \_ ->
                List.foldl
                    (\x sum -> SafeInt.add sum (SafeInt.mul x x))
                    SafeInt.zero
                    oneToHundredSafeInt
        ]


benchmarkAddPow =
    describe "add & pow (1^3 + 2^3 + ... + 100^3)"
        [ benchmark "Int" <|
            \_ ->
                List.foldl
                    (\x sum -> sum + x ^ 3)
                    0
                    oneToHundredInt
        , benchmark "Float" <|
            \_ ->
                List.foldl
                    (\x sum -> sum + x ^ 3.0)
                    0.0
                    oneToHundredFloat
        , benchmark "Unchecked" <|
            \_ ->
                List.foldl
                    (\x sum -> Unchecked.add sum (Unchecked.pow x 3.0))
                    0.0
                    oneToHundredFloat
        , benchmark "SafeInt" <|
            \_ ->
                List.foldl
                    (\x sum -> SafeInt.add sum (SafeInt.pow x safe_3))
                    SafeInt.zero
                    oneToHundredSafeInt
        ]


benchmarkAddModBy =
    describe "add & modBy (1e9 % 2 + 1e9 % 3 + ... 1e9 % 100)"
        [ benchmark "Int" <|
            \_ ->
                List.foldl
                    (\x accum -> accum + Basics.modBy x 1000000000)
                    0
                    oneToHundredInt
        , benchmark "Unchecked" <|
            \_ ->
                List.foldl
                    (\x accum -> Unchecked.add accum (Unchecked.modBy x 1.0e9))
                    0.0
                    oneToHundredFloat
        , benchmark "SafeInt" <|
            \_ ->
                List.foldl
                    (\x accum -> SafeInt.add accum (SafeInt.modBy x safe_1000000000))
                    SafeInt.zero
                    oneToHundredSafeInt
        ]


benchmarkAddRemainderBy =
    describe "add & remainderBy (1e9 % 2 + 1e9 % 3 + ... 1e9 % 100)"
        [ benchmark "Int" <|
            \_ ->
                List.foldl
                    (\x accum -> accum + Basics.remainderBy x 1000000000)
                    0
                    oneToHundredInt
        , benchmark "Unchecked" <|
            \_ ->
                List.foldl
                    (\x accum -> Unchecked.add accum (Unchecked.remainderBy x 1.0e9))
                    0.0
                    oneToHundredFloat
        , benchmark "SafeInt" <|
            \_ ->
                List.foldl
                    (\x accum -> SafeInt.add accum (SafeInt.remainderBy x safe_1000000000))
                    SafeInt.zero
                    oneToHundredSafeInt
        ]


benchmarkDivMod =
    describe "divMod (((1e9 / 3 + mod_) / 5 + mod_) / ... / 23 + mod_)"
        [ benchmark "Unchecked - divMod" <|
            \_ ->
                List.foldl
                    (\x accum ->
                        let
                            ( div_, mod_ ) =
                                Unchecked.divMod accum x
                        in
                        Unchecked.add div_ mod_
                    )
                    1000000000.0
                    somePrimesFloat
        , benchmark "Unchecked - div & mod" <|
            \_ ->
                List.foldl
                    (\x accum -> Unchecked.add (Unchecked.div accum x) (Unchecked.mod accum x))
                    1000000000.0
                    somePrimesFloat
        , benchmark "SafeInt - divMod" <|
            \_ ->
                List.foldl
                    (\x accum ->
                        let
                            ( div_, mod_ ) =
                                SafeInt.divMod accum x
                        in
                        SafeInt.add div_ mod_
                    )
                    safe_1000000000
                    somePrimesSafeInt
        , benchmark "SafeInt - div & mod" <|
            \_ ->
                List.foldl
                    (\x accum -> SafeInt.add (SafeInt.div accum x) (SafeInt.mod accum x))
                    safe_1000000000
                    somePrimesSafeInt
        ]


benchmarkFromInt =
    describe "convert from Int x100"
        [ benchmark "Basics.toFloat" <|
            \_ -> List.map Basics.toFloat oneToHundredInt
        , benchmark "Unchecked.fromInt" <|
            \_ -> List.map Unchecked.fromInt oneToHundredInt
        , benchmark "SafeInt.fromInt" <|
            \_ -> List.map SafeInt.fromInt oneToHundredInt
        ]


benchmarkQuotient =
    describe "quotient (1e9 / 3 / 5 / ... / 23)"
        [ benchmark "Int" <|
            \_ ->
                List.foldl
                    (\x accum -> accum // x)
                    1000000000
                    somePrimesInt
        , benchmark "Float" <|
            \_ ->
                List.foldl
                    -- NOTE: Basics.truncate only works for 32-bit integers
                    (\x accum -> Basics.toFloat <| Basics.truncate <| accum / x)
                    1000000000.0
                    somePrimesFloat
        , benchmark "Unchecked" <|
            \_ ->
                List.foldl
                    (\x accum -> Unchecked.quotient accum x)
                    1000000000.0
                    somePrimesFloat
        , benchmark "SafeInt" <|
            \_ ->
                List.foldl
                    (\x accum -> SafeInt.quotient accum x)
                    safe_1000000000
                    somePrimesSafeInt
        ]



-- 1 to 100


oneToHundredInt =
    [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100 ]


oneToHundredFloat =
    List.map Basics.toFloat oneToHundredInt


oneToHundredSafeInt =
    List.map SafeInt.new oneToHundredInt



-- SOME PRIMES


somePrimesInt =
    -- chose so that multiplying these together < 2^31
    [ 3, 5, 7, 11, 13, 17, 19, 23 ]


somePrimesFloat =
    List.map Basics.toFloat somePrimesInt


somePrimesSafeInt =
    List.map SafeInt.new somePrimesInt



-- VALUES


safe_3 : SafeInt
safe_3 =
    SafeInt.new 3


safe_1000000000 : SafeInt
safe_1000000000 =
    SafeInt.new 1000000000
