module Tests exposing (all)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int)
import SafeInt exposing (SafeInt)
import SafeInt.Unchecked as Unchecked
import Test exposing (..)



-- TESTS - ALL


all =
    describe "SafeInt"
        [ -- CONSTANTS
          testConstants
        , testConstantsUnchecked

        -- CONVERSION - INT
        , testFromInt
        , testFromIntUnchecked
        , testNew
        , testToInt
        , testToIntUnchecked

        -- CONVERSION - FLOAT
        , testCeiling
        , testCeilingUnchecked
        , testFloor
        , testFloorUnchecked
        , testRound
        , testRoundUnchecked
        , testToFloat
        , testTruncate
        , testTruncateUnchecked

        -- MATH
        , testAdd
        , testAddUnchecked
        , testMul
        , testMulUnchecked
        , testPow
        , testPowUnchecked
        , testSub
        , testSubUnchecked

        -- DIVISION - BASICS
        , testDiv
        , testDivUnchecked
        , testMod
        , testModUnchecked
        , testQuotient
        , testQuotientUnchecked
        , testRemainder
        , testRemainderUnchecked

        -- DIVISION - REVERSED
        , testDivBy
        , testDivByUnchecked
        , testModBy
        , testModByUnchecked
        , testQuotientBy
        , testQuotientByUnchecked
        , testRemainderBy
        , testRemainderByUnchecked

        -- DIVISION - COMBINED
        , testDivMod
        , testDivModUnchecked
        , testDivModBy
        , testDivModByUnchecked
        , testQuotRem
        , testQuotRemUnchecked
        , testQuotRemBy
        , testQuotRemByUnchecked

        -- COMPARISON
        , testCompare

        -- SIGNS
        , testAbs
        , testAbsUnchecked
        , testNegate
        , testNegateUnchecked
        , testSign
        , testSignUnchecked

        -- INTERNALS
        , testInternals
        ]



-- TESTS - CONSTANTS


testConstants =
    describe "constants"
        [ test "maxValue" <|
            \_ ->
                SafeInt.maxValue
                    |> Expect.equal (SafeInt.new 9007199254740991)
        , test "maxValue + 1 = undefined" <|
            \_ ->
                SafeInt.add SafeInt.maxValue SafeInt.one
                    |> Expect.equal SafeInt.undefined
        , test "minValue" <|
            \_ ->
                SafeInt.minValue
                    |> Expect.equal (SafeInt.new -9007199254740991)
        , test "minValue - 1 = undefined" <|
            \_ ->
                SafeInt.sub SafeInt.minValue SafeInt.one
                    |> Expect.equal SafeInt.undefined
        , test "undefined == undefined" <|
            \_ ->
                (SafeInt.undefined == SafeInt.undefined)
                    |> Expect.equal True
        , test "undefined /= 0" <|
            \_ ->
                (SafeInt.undefined == SafeInt.new 0)
                    |> Expect.equal False
        , test "zero" <|
            \_ ->
                SafeInt.zero
                    |> Expect.equal (SafeInt.new 0)
        , test "one" <|
            \_ ->
                SafeInt.one
                    |> Expect.equal (SafeInt.new 1)
        , test "two" <|
            \_ ->
                SafeInt.two
                    |> Expect.equal (SafeInt.new 2)
        ]


testConstantsUnchecked =
    describe "constants - unchecked"
        [ test "maxValue" <|
            \_ ->
                Unchecked.maxValue
                    |> Expect.equal 9007199254740991.0
        , test "minValue" <|
            \_ ->
                Unchecked.minValue
                    |> Expect.equal -9007199254740991.0
        ]



-- TESTS - CONVERSION - SHARED


testsForCeiling =
    [ TestFloat "-3.8" -3.8 (Just -3)
    , TestFloat "3.8" 3.8 (Just 4)
    , TestFloat "works for n < -2^32" -111222333444555.66 (Just -111222333444555)
    , TestFloat "works for n > 2^32" 111222333444555.66 (Just 111222333444556)
    , TestFloat "negative overflow" -1.0e17 Nothing
    , TestFloat "positive overflow" 1.0e17 Nothing
    , TestFloat "NaN" floatNaN Nothing
    ]


testsForFloor =
    [ TestFloat "-3.8" -3.8 (Just -4)
    , TestFloat "3.8" 3.8 (Just 3)
    , TestFloat "works for n < -2^32" -111222333444555.66 (Just -111222333444556)
    , TestFloat "works for n > 2^32" 111222333444555.66 (Just 111222333444555)
    , TestFloat "negative overflow" -1.0e17 Nothing
    , TestFloat "positive overflow" 1.0e17 Nothing
    , TestFloat "NaN" floatNaN Nothing
    ]


testsForFromInt =
    -- used with fromInt, new
    [ ( "max", 9007199254740991, SafeInt.maxValue )
    , ( "min", -9007199254740991, SafeInt.minValue )
    , ( "negative overflow", -9007199254740992, SafeInt.undefined )
    , ( "positive overflow", 9007199254740992, SafeInt.undefined )
    , ( "NaN", intNaN, SafeInt.undefined )
    , ( "negative infinity", intNegInf, SafeInt.undefined )
    , ( "positive infinity", intNegInf, SafeInt.undefined )
    , ( "works for non-integer n < -2^32", negate int111222333444_5, SafeInt.new -111222333444 )
    , ( "works for non-integer n > 2^32", int111222333444_5, SafeInt.fromInt 111222333444 )
    ]


testsForRound =
    [ TestFloat "-3.8" -3.8 (Just -4)
    , TestFloat "-3.5" -3.5 (Just -3)
    , TestFloat "-3.2" -3.2 (Just -3)
    , TestFloat "3.2" 3.2 (Just 3)
    , TestFloat "3.5" 3.5 (Just 4)
    , TestFloat "3.8" 3.8 (Just 4)
    , TestFloat "works for n < -2^32" -111222333444555.66 (Just -111222333444556)
    , TestFloat "works for n > 2^32" 111222333444555.66 (Just 111222333444556)
    , TestFloat "negative overflow" -1.0e17 Nothing
    , TestFloat "positive overflow" 1.0e17 Nothing
    , TestFloat "NaN" floatNaN Nothing
    ]


testsForTruncate =
    [ TestFloat "-3.8" -3.8 (Just -3)
    , TestFloat "3.8" 3.8 (Just 3)
    , TestFloat "works for n < -2^32" -111222333444555.66 (Just -111222333444555)
    , TestFloat "works for n > 2^32" 111222333444555.66 (Just 111222333444555)
    , TestFloat "negative overflow" -1.0e17 Nothing
    , TestFloat "positive overflow" 1.0e17 Nothing
    , TestFloat "NaN" floatNaN Nothing
    ]



-- TESTS - CONVERSION - INT


testFromInt =
    describe "fromInt" <|
        List.map
            (\( description, input, expected ) ->
                test description <|
                    \_ -> SafeInt.fromInt input |> Expect.equal expected
            )
            testsForFromInt


testFromIntUnchecked =
    describe "fromInt - unchecked"
        [ test "max" <|
            \_ ->
                Unchecked.fromInt 9007199254740991
                    |> Expect.equal Unchecked.maxValue
        , test "min" <|
            \_ ->
                Unchecked.fromInt -9007199254740991
                    |> Expect.equal Unchecked.minValue
        ]


testNew =
    describe "new" <|
        List.map
            (\( description, input, expected ) ->
                test description <|
                    \_ -> SafeInt.new input |> Expect.equal expected
            )
            testsForFromInt


testToInt =
    describe "toInt"
        [ test "works for n < -2^32" <|
            \_ ->
                SafeInt.new -111222333444555
                    |> SafeInt.toInt
                    |> Expect.equal (Just -111222333444555)
        , test "works for n > 2^32" <|
            \_ ->
                SafeInt.new 111222333444555
                    |> SafeInt.toInt
                    |> Expect.equal (Just 111222333444555)
        , test "undefined" <|
            \_ ->
                SafeInt.undefined
                    |> SafeInt.toInt
                    |> Expect.equal Nothing
        ]


testToIntUnchecked =
    describe "toInt - unchecked"
        [ test "works for n < -2^32" <|
            \_ ->
                Unchecked.toInt -111222333444555.0
                    |> Expect.equal -111222333444555
        , test "works for n > 2^32" <|
            \_ ->
                Unchecked.toInt 111222333444555.0
                    |> Expect.equal 111222333444555
        ]



-- TESTS - CONVERSION - FLOAT


testCeiling =
    describe "ceiling" <| testFloatToSafeInt SafeInt.ceiling testsForCeiling


testCeilingUnchecked =
    describe "ceiling - unchecked" <| testFloatToFloat Unchecked.ceiling testsForCeiling


testFloor =
    describe "floor" <| testFloatToSafeInt SafeInt.floor testsForFloor


testFloorUnchecked =
    describe "floor - unchecked" <| testFloatToFloat Unchecked.floor testsForFloor


testRound =
    describe "round" <| testFloatToSafeInt SafeInt.round testsForRound


testRoundUnchecked =
    describe "round - unchecked" <| testFloatToFloat Unchecked.round testsForRound


testToFloat =
    describe "toFloat"
        [ test "works for n < -2^32" <|
            \_ ->
                SafeInt.new -111222333444555
                    |> SafeInt.toFloat
                    |> Expect.equal (Just -111222333444555.0)
        , test "works for n > 2^32" <|
            \_ ->
                SafeInt.new 111222333444555
                    |> SafeInt.toFloat
                    |> Expect.equal (Just 111222333444555.0)
        , test "undefined" <|
            \_ ->
                SafeInt.undefined
                    |> SafeInt.toFloat
                    |> Expect.equal Nothing
        ]


testTruncate =
    describe "truncate" <| testFloatToSafeInt SafeInt.truncate testsForTruncate


testTruncateUnchecked =
    describe "truncate - unchecked" <| testFloatToFloat Unchecked.truncate testsForTruncate



-- TESTS - MATH - SHARED


testsForAdd =
    [ TestInt "works for a,b > 2^32" 111222333444555 111111111111111 222333444555666
    , TestMaybeInt "negative overflow" (Just -5111222333444555) (Just -5111222333444555) Nothing
    , TestMaybeInt "positive overflow" (Just 5111222333444555) (Just 5111222333444555) Nothing
    , TestMaybeInt "undefined + _ = undefined" Nothing (Just 1) Nothing
    , TestMaybeInt "_ + undefined = undefined" (Just 1) Nothing Nothing
    ]


testsForMul =
    [ TestInt "works for a*b > 2^32" 12345678 87654321 1082152022374638
    , TestInt "works for a > 2^32" 111222333444555 2 222444666889110
    , TestInt "works for b > 2^32" 2 111222333444555 222444666889110
    , TestMaybeInt "negative overflow" (Just -123456789) (Just 987654321) Nothing
    , TestMaybeInt "positive overflow" (Just 123456789) (Just 987654321) Nothing
    , TestMaybeInt "undefined * _ = undefined" Nothing (Just 1) Nothing
    , TestMaybeInt "_ * undefined = undefined" (Just 1) Nothing Nothing
    ]


testsForPow =
    [ TestInt "works for a*b > 2^32" 10 15 1000000000000000
    , TestMaybeInt "negative overflow" (Just -10) (Just 17) Nothing
    , TestMaybeInt "positive overflow" (Just 10) (Just 17) Nothing
    , TestMaybeInt "undefined ^ 0 = undefined" Nothing (Just 0) Nothing
    , TestMaybeInt "1 ^ undefined = undefined" (Just 1) Nothing Nothing
    ]
        ++ testsForPowNearZero


testsForPowNearZero =
    -- exhaustive checking of inputs -2 to +2
    let
        text x y =
            String.fromInt x ++ " ^ " ++ String.fromInt y
    in
    List.map (\( x, y, r ) -> TestMaybeInt (text x y) (Just x) (Just y) r)
        [ ( -2, -2, Just 0 )
        , ( -2, -1, Just 0 )
        , ( -2, 0, Just 1 )
        , ( -2, 1, Just -2 )
        , ( -2, 2, Just 4 )
        , ( -1, -2, Just 1 )
        , ( -1, -1, Just -1 )
        , ( -1, 0, Just 1 )
        , ( -1, 1, Just -1 )
        , ( -1, 2, Just 1 )
        , ( 0, -2, Nothing )
        , ( 0, -1, Nothing )
        , ( 0, 0, Nothing )
        , ( 0, 1, Just 0 )
        , ( 0, 2, Just 0 )
        , ( 1, -2, Just 1 )
        , ( 1, -1, Just 1 )
        , ( 1, 0, Just 1 )
        , ( 1, 1, Just 1 )
        , ( 1, 2, Just 1 )
        , ( 2, -2, Just 0 )
        , ( 2, -1, Just 0 )
        , ( 2, 0, Just 1 )
        , ( 2, 1, Just 2 )
        , ( 2, 2, Just 4 )
        ]


testsForSub =
    [ TestInt "works for a,b,result > 2^32" 222333444555666 111111111111111 111222333444555
    , TestMaybeInt "negative overflow" (Just -5111222333444555) (Just 5111222333444555) Nothing
    , TestMaybeInt "positive overflow" (Just 5111222333444555) (Just -5111222333444555) Nothing
    , TestMaybeInt "undefined - _ = undefined" Nothing (Just 1) Nothing
    , TestMaybeInt "_ - undefined = undefined" (Just 1) Nothing Nothing
    ]



-- TESTS - MATH


testAdd =
    describe "add" <| testSafeInt2 SafeInt.add testsForAdd


testAddUnchecked =
    describe "add - unchecked" <| testFloat2 Unchecked.add testsForAdd


testMul =
    describe "mul" <| testSafeInt2 SafeInt.mul testsForMul


testMulUnchecked =
    describe "mul - unchecked" <| testFloat2 Unchecked.mul testsForMul


testPow =
    describe "pow" <| testSafeInt2 SafeInt.pow testsForPow


testPowUnchecked =
    describe "pow - unchecked" <| testFloat2 Unchecked.pow testsForPow


testSub =
    describe "sub" <| testSafeInt2 SafeInt.sub testsForSub


testSubUnchecked =
    describe "sub - unchecked" <| testFloat2 Unchecked.sub testsForSub



-- TESTS - DIVISION - SHARED


testsForDiv =
    -- used with div, divBy, divMod, divModBy
    [ TestInt "dividend  10 ; divisor  3" 10 3 3
    , TestInt "dividend -10 ; divisor  3" -10 3 -4
    , TestInt "dividend  10 ; divisor -3" 10 -3 -4
    , TestInt "dividend -10 ; divisor -3" -10 -3 3
    , TestInt "works for dividend & divisor > 2^32" 111222333444555 111222333444 1000
    , TestInt "works for result > 2^32" 111222333444555 1000 111222333444
    , TestMaybeInt "dividend undefined" Nothing (Just 1) Nothing
    , TestMaybeInt "divisor undefined" (Just 1) Nothing Nothing
    , TestMaybeInt "divisor 0" (Just 1) (Just 0) Nothing
    ]


testsForMod =
    -- used with mod, modBy, divMod, divModBy
    [ TestInt "dividend  10 ; divisor  3" 10 3 1
    , TestInt "dividend -10 ; divisor  3" -10 3 2
    , TestInt "dividend  10 ; divisor -3" 10 -3 -2
    , TestInt "dividend -10 ; divisor -3" -10 -3 -1
    , TestInt "works for dividend & divisor & result > 2^32" 555444333222111 100000000000 44333222111
    , TestMaybeInt "dividend undefined" Nothing (Just 1) Nothing
    , TestMaybeInt "divisor undefined" (Just 1) Nothing Nothing
    , TestMaybeInt "divisor 0" (Just 1) (Just 0) Nothing
    ]


testsForQuotient =
    -- used with quotient, quotientBy, quotRem, quotRemBy
    [ TestInt "dividend  10 ; divisor  3" 10 3 3
    , TestInt "dividend -10 ; divisor  3" -10 3 -3
    , TestInt "dividend  10 ; divisor -3" 10 -3 -3
    , TestInt "dividend -10 ; divisor -3" -10 -3 3
    , TestInt "works for dividend & divisor > 2^32" 111222333444555 111222333444 1000
    , TestInt "works for result > 2^32" 111222333444555 1000 111222333444
    , TestMaybeInt "dividend undefined" Nothing (Just 1) Nothing
    , TestMaybeInt "divisor undefined" (Just 1) Nothing Nothing
    , TestMaybeInt "divisor 0" (Just 1) (Just 0) Nothing
    ]


testsForRemainder =
    -- used with remainder, remainderBy, quotRem, quotRemBy
    [ TestInt "dividend  10 ; divisor  3" 10 3 1
    , TestInt "dividend -10 ; divisor  3" -10 3 -1
    , TestInt "dividend  10 ; divisor -3" 10 -3 1
    , TestInt "dividend -10 ; divisor -3" -10 -3 -1
    , TestInt "works for dividend & divisor & result > 2^32" 555444333222111 100000000000 44333222111
    , TestMaybeInt "dividend undefined" Nothing (Just 1) Nothing
    , TestMaybeInt "divisor undefined" (Just 1) Nothing Nothing
    , TestMaybeInt "divisor 0" (Just 1) (Just 0) Nothing
    ]



-- TESTS - DIVISION - BASICS


testDiv =
    describe "div" <| testSafeInt2 SafeInt.div testsForDiv


testDivUnchecked =
    describe "div - unchecked" <| testFloat2 Unchecked.div testsForDiv


testMod =
    describe "mod" <| testSafeInt2 SafeInt.mod testsForMod


testModUnchecked =
    describe "mod - unchecked" <| testFloat2 Unchecked.mod testsForMod


testQuotient =
    describe "quotient" <| testSafeInt2 SafeInt.quotient testsForQuotient


testQuotientUnchecked =
    describe "quotient - unchecked" <| testFloat2 Unchecked.quotient testsForQuotient


testRemainder =
    describe "remainder" <| testSafeInt2 SafeInt.remainder testsForRemainder


testRemainderUnchecked =
    describe "remainder - unchecked" <| testFloat2 Unchecked.remainder testsForRemainder



-- TESTS - DIVISION - REVERSED


testDivBy =
    describe "divBy" <| testSafeInt2 (\a b -> SafeInt.divBy b a) testsForDiv


testDivByUnchecked =
    describe "divBy - unchecked" <| testFloat2 (\a b -> Unchecked.divBy b a) testsForDiv


testModBy =
    describe "modBy" <| testSafeInt2 (\a b -> SafeInt.modBy b a) testsForMod


testModByUnchecked =
    describe "modBy - unchecked" <| testFloat2 (\a b -> Unchecked.modBy b a) testsForMod


testQuotientBy =
    describe "quotientBy" <| testSafeInt2 (\a b -> SafeInt.quotientBy b a) testsForQuotient


testQuotientByUnchecked =
    describe "quotientBy - unchecked" <| testFloat2 (\a b -> Unchecked.quotientBy b a) testsForQuotient


testRemainderBy =
    describe "remainderBy" <| testSafeInt2 (\a b -> SafeInt.remainderBy b a) testsForRemainder


testRemainderByUnchecked =
    describe "remainderBy - unchecked" <| testFloat2 (\a b -> Unchecked.remainderBy b a) testsForRemainder



-- TESTS - DIVISION - COMBINED


testDivMod =
    describe "divMod"
        [ describe "- div" <|
            testSafeInt2 (\a b -> SafeInt.divMod a b |> Tuple.first) testsForDiv
        , describe "- mod" <|
            testSafeInt2 (\a b -> SafeInt.divMod a b |> Tuple.second) testsForMod
        ]


testDivModUnchecked =
    describe "divMod - unchecked"
        [ describe "- div" <|
            testFloat2 (\a b -> Unchecked.divMod a b |> Tuple.first) testsForDiv
        , describe "- mod" <|
            testFloat2 (\a b -> Unchecked.divMod a b |> Tuple.second) testsForMod
        ]


testDivModBy =
    describe "divModBy"
        [ describe "- div" <|
            testSafeInt2 (\a b -> SafeInt.divModBy b a |> Tuple.first) testsForDiv
        , describe "- mod" <|
            testSafeInt2 (\a b -> SafeInt.divModBy b a |> Tuple.second) testsForMod
        ]


testDivModByUnchecked =
    describe "divModBy - unchecked"
        [ describe "- div" <|
            testFloat2 (\a b -> Unchecked.divModBy b a |> Tuple.first) testsForDiv
        , describe "- mod" <|
            testFloat2 (\a b -> Unchecked.divModBy b a |> Tuple.second) testsForMod
        ]


testQuotRem =
    describe "quotRem"
        [ describe "- quotient" <|
            testSafeInt2 (\a b -> SafeInt.quotRem a b |> Tuple.first) testsForQuotient
        , describe "- remainder" <|
            testSafeInt2 (\a b -> SafeInt.quotRem a b |> Tuple.second) testsForRemainder
        ]


testQuotRemUnchecked =
    describe "quotRem - unchecked"
        [ describe "- quotient" <|
            testFloat2 (\a b -> Unchecked.quotRem a b |> Tuple.first) testsForQuotient
        , describe "- remainder" <|
            testFloat2 (\a b -> Unchecked.quotRem a b |> Tuple.second) testsForRemainder
        ]


testQuotRemBy =
    describe "quotRemBy"
        [ describe "- quotient" <|
            testSafeInt2 (\a b -> SafeInt.quotRemBy b a |> Tuple.first) testsForQuotient
        , describe "- remainder" <|
            testSafeInt2 (\a b -> SafeInt.quotRemBy b a |> Tuple.second) testsForRemainder
        ]


testQuotRemByUnchecked =
    describe "quotRemBy - unchecked"
        [ describe "- quotient" <|
            testFloat2 (\a b -> Unchecked.quotRemBy b a |> Tuple.first) testsForQuotient
        , describe "- remainder" <|
            testFloat2 (\a b -> Unchecked.quotRemBy b a |> Tuple.second) testsForRemainder
        ]



-- TESTS - COMPARISON


type TestCompare
    = TestCompare Bool SafeInt SafeInt Order


testCompare =
    describe "compare" <|
        List.map
            (\(TestCompare undefinedIsSmallest a b expected) ->
                let
                    description =
                        (if undefinedIsSmallest then
                            "True"

                         else
                            "False"
                        )
                            ++ " "
                            ++ safeIntToString a
                            ++ " "
                            ++ safeIntToString b
                in
                test description <|
                    \_ ->
                        SafeInt.compare undefinedIsSmallest a b
                            |> Expect.equal expected
            )
            [ TestCompare True SafeInt.undefined SafeInt.undefined EQ
            , TestCompare True SafeInt.undefined (SafeInt.new 123) LT
            , TestCompare True (SafeInt.new 123) SafeInt.undefined GT
            , TestCompare True (SafeInt.new 123) (SafeInt.new 123) EQ
            , TestCompare True (SafeInt.new 123) (SafeInt.new 456) LT
            , TestCompare True (SafeInt.new 456) (SafeInt.new 123) GT
            , TestCompare False SafeInt.undefined SafeInt.undefined EQ
            , TestCompare False SafeInt.undefined (SafeInt.new 123) GT
            , TestCompare False (SafeInt.new 123) SafeInt.undefined LT
            , TestCompare False (SafeInt.new 123) (SafeInt.new 123) EQ
            , TestCompare False (SafeInt.new 123) (SafeInt.new 456) LT
            , TestCompare False (SafeInt.new 456) (SafeInt.new 123) GT
            ]



-- TESTS - SIGNS


testAbs =
    describe "abs"
        [ test "works for n < -2^32" <|
            \_ ->
                SafeInt.abs (SafeInt.new -111222333444555)
                    |> Expect.equal (SafeInt.new 111222333444555)
        , test "works for n > 2^32" <|
            \_ ->
                SafeInt.abs (SafeInt.new 111222333444555)
                    |> Expect.equal (SafeInt.new 111222333444555)
        , test "zero" <|
            \_ ->
                SafeInt.abs SafeInt.zero
                    |> Expect.equal SafeInt.zero
        ]


testAbsUnchecked =
    describe "abs - unchecked"
        [ test "works for n < -2^32" <|
            \_ ->
                Unchecked.abs -111222333444555.0
                    |> Expect.equal 111222333444555.0
        , test "works for n > 2^32" <|
            \_ ->
                Unchecked.abs 111222333444555.0
                    |> Expect.equal 111222333444555.0
        , test "zero" <|
            \_ ->
                Unchecked.abs 0.0
                    |> Expect.equal 0.0
        ]


testNegate =
    describe "negate"
        [ test "works for n < -2^32" <|
            \_ ->
                SafeInt.negate (SafeInt.new -111222333444555)
                    |> Expect.equal (SafeInt.new 111222333444555)
        , test "works for n > 2^32" <|
            \_ ->
                SafeInt.negate (SafeInt.new 111222333444555)
                    |> Expect.equal (SafeInt.new -111222333444555)
        , test "zero" <|
            \_ ->
                SafeInt.negate SafeInt.zero
                    |> Expect.equal SafeInt.zero
        ]


testNegateUnchecked =
    describe "negate - unchecked"
        [ test "works for n < -2^32" <|
            \_ ->
                Unchecked.negate -111222333444555.0
                    |> Expect.equal 111222333444555.0
        , test "works for n > 2^32" <|
            \_ ->
                Unchecked.negate 111222333444555.0
                    |> Expect.equal -111222333444555.0
        , test "zero" <|
            \_ ->
                Unchecked.negate 0.0
                    |> Expect.equal 0.0
        ]


testSign =
    describe "sign"
        [ test "works for n < -2^32" <|
            \_ ->
                SafeInt.sign (SafeInt.new -111222333444555)
                    |> Expect.equal (SafeInt.new -1)
        , test "works for n > 2^32" <|
            \_ ->
                SafeInt.sign (SafeInt.new 111222333444555)
                    |> Expect.equal (SafeInt.new 1)
        , test "zero" <|
            \_ ->
                SafeInt.sign SafeInt.zero
                    |> Expect.equal SafeInt.zero
        ]


testSignUnchecked =
    describe "sign - unchecked"
        [ test "works for n < -2^32" <|
            \_ ->
                Unchecked.sign -111222333444555.0
                    |> Expect.equal -1.0
        , test "works for n > 2^32" <|
            \_ ->
                Unchecked.sign 111222333444555.0
                    |> Expect.equal 1.0
        , test "zero" <|
            \_ ->
                Unchecked.sign 0.0
                    |> Expect.equal 0.0
        ]



-- TESTS - INTERNALS


testInternals =
    describe "internal helpers, some using undocumented behavior"
        [ test "floatNaN" <|
            \_ -> isNaN floatNaN |> Expect.equal True
        , test "floatNegInf" <|
            \_ -> isInfinite floatNegInf && floatNegInf < 0 |> Expect.equal True
        , test "floatPosInf" <|
            \_ -> isInfinite floatPosInf && floatPosInf > 0 |> Expect.equal True
        , test "1234.5 as Int" <|
            \_ -> toFloat int111222333444_5 |> Expect.within (Expect.Absolute 0) 111222333444.5
        , test "intNaN" <|
            \_ -> isNaN (toFloat intNaN) |> Expect.equal True
        , test "intNegInf" <|
            \_ -> isInfinite (toFloat intNegInf) && intNegInf < 0 |> Expect.equal True
        , test "intPosInf" <|
            \_ -> isInfinite (toFloat intPosInf) && intPosInf > 0 |> Expect.equal True
        ]



-- HELPERS - LITERALS


floatNaN : Float
floatNaN =
    0 / 0


floatNegInf : Float
floatNegInf =
    -1 / 0


floatPosInf : Float
floatPosInf =
    1 / 0


{-| Int value over 2^32 that is not an integer
-}
int111222333444_5 : Int
int111222333444_5 =
    111222333444 + round 2 ^ -1


intNaN : Int
intNaN =
    Basics.round floatNaN


intNegInf : Int
intNegInf =
    Basics.round floatNegInf


intPosInf : Int
intPosInf =
    Basics.round floatPosInf



-- HELPERS - MISC


fromMaybeInt : Maybe Int -> SafeInt
fromMaybeInt x =
    case x of
        Just int ->
            SafeInt.new int

        Nothing ->
            SafeInt.undefined


safeIntToString : SafeInt -> String
safeIntToString x =
    case SafeInt.toInt x of
        Nothing ->
            "Undefined"

        Just int ->
            String.fromInt int



-- HELPERS - TestFloat


type TestFloat
    = TestFloat String Float (Maybe Int)


{-|

  - Input : Float
  - Output: Float -- converted from given Maybe Int, ignore test if Nothing

-}
testFloatToFloat : (Float -> Float) -> List TestFloat -> List Test
testFloatToFloat fn data =
    data
        |> List.concatMap
            (\(TestFloat description a expected) ->
                case expected of
                    Just expected_ ->
                        [ test description <|
                            \_ -> fn a |> Expect.equal (Basics.toFloat expected_)
                        ]

                    Nothing ->
                        []
            )


{-|

  - Input : Float
  - Output: SafeInt -- converted from given Maybe Int

-}
testFloatToSafeInt : (Float -> SafeInt) -> List TestFloat -> List Test
testFloatToSafeInt fn data =
    data
        |> List.map
            (\(TestFloat description a expected) ->
                test description <|
                    \_ -> fn a |> Expect.equal (fromMaybeInt expected)
            )



-- HELPERS - TestInt


type TestInt
    = TestInt String Int Int Int
    | TestMaybeInt String (Maybe Int) (Maybe Int) (Maybe Int)


{-|

  - TestInt
      - Input : SafeInt SafeInt -- converted from given Int:s
      - Output: SafeInt -- converted from given Int
  - TestMaybeInt
      - Input : SafeInt SafeInt -- converted from given Maybe Int:s
      - Output: SafeInt -- converted from given Maybe Int

-}
testSafeInt2 : (SafeInt -> SafeInt -> SafeInt) -> List TestInt -> List Test
testSafeInt2 fn data =
    data
        |> List.map
            (\testData ->
                case testData of
                    TestInt description a b expected ->
                        test description <|
                            \_ ->
                                fn (SafeInt.new a) (SafeInt.new b)
                                    |> Expect.equal (SafeInt.new expected)

                    TestMaybeInt description a b expected ->
                        test description <|
                            \_ ->
                                fn (fromMaybeInt a) (fromMaybeInt b)
                                    |> Expect.equal (fromMaybeInt expected)
            )


{-|

  - TestInt
      - Input : Float Float -- converted from given Int:s
      - Output: Float -- converted from given Int
  - TestMaybeInt
      - if all are Just, then like TestInt, otherwise ignore the test

-}
testFloat2 : (Float -> Float -> Float) -> List TestInt -> List Test
testFloat2 fn data =
    data
        |> List.concatMap
            (\testData ->
                case testData of
                    TestInt description a b expected ->
                        [ test description <|
                            \_ ->
                                fn (Basics.toFloat a) (Basics.toFloat b)
                                    |> Expect.equal (Basics.toFloat expected)
                        ]

                    TestMaybeInt description (Just a) (Just b) (Just expected) ->
                        [ test description <|
                            \_ ->
                                fn (Basics.toFloat a) (Basics.toFloat b)
                                    |> Expect.equal (Basics.toFloat expected)
                        ]

                    TestMaybeInt _ _ _ _ ->
                        []
            )
