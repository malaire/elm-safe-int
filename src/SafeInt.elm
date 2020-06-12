module SafeInt exposing
    ( SafeInt
    , minValue, maxValue, undefined, zero, one, two
    , new, fromInt, toInt
    , round, ceiling, truncate, floor, toFloat
    , add, sub, mul, pow
    , div, mod, quotient, remainder
    , divBy, modBy, quotientBy, remainderBy
    , divMod, quotRem, divModBy, quotRemBy
    , compare
    , abs, negate, sign
    )

{-| A safe 54-bit signed integer for use cases where normal `Int` isn't sufficient and 54-bit range will suffice.

@docs SafeInt


# Constants

@docs minValue, maxValue, undefined, zero, one, two


# Conversion from/to Int

@docs new, fromInt, toInt


# Conversion from/to Float

Comparison of `Float` to [`SafeInt`](#SafeInt) conversion functions:

```text
          -3.8 -3.5 -3.2   ~    3.2  3.5  3.8
          ---- ---- ----       ---- ---- ----
round     -4   -3   -3          3    4    4
ceiling   -3   -3   -3          4    4    4
truncate  -3   -3   -3          3    3    3
floor     -4   -4   -4          3    3    3
```

@docs round, ceiling, truncate, floor, toFloat


# Math

@docs add, sub, mul, pow


# Division Basics

[`SafeInt`](#SafeInt) has four basic division functions:
[`div`](#div), [`mod`](#mod), [`quotient`](#quotient) and [`remainder`](#remainder).

Both [`div`](#div) and [`quotient`](#quotient) calculate integer division, the difference is in rounding:
[`div`](#div) rounds the result towards negative infinity while [`quotient`](#quotient) rounds towards zero.

The `//` operator is similar to [`quotient`](#quotient).

    -- -10 divided by 3 is -3.333..., rounded to -4
    SafeInt.div (SafeInt.new -10) (SafeInt.new 3)
        |> SafeInt.toInt
        --> Just -4

    -- -10 divided by 3 is -3.333..., rounded to -3
    SafeInt.quotient (SafeInt.new -10) (SafeInt.new 3)
        |> SafeInt.toInt
        --> Just -3

Likewise both [`mod`](#mod) and [`remainder`](#remainder) calculate remainder after integer division:
[`mod`](#mod) calculates remainder after [`div`](#div)
and [`remainder`](#remainder) calculates remainder after [`quotient`](#quotient).

    -- -10 divided by 3 is -3.333..., rounded to -4
    -- then remainder is -10 - (3 * -4) = 2
    SafeInt.mod (SafeInt.new -10) (SafeInt.new 3)
        |> SafeInt.toInt
        --> Just 2

    -- -10 divided by 3 is -3.333..., rounded to -3
    -- then remainder is -10 - (3 * -3) = -1
    SafeInt.remainder (SafeInt.new -10) (SafeInt.new 3)
        |> SafeInt.toInt
        --> Just -1


## Division compared

The table below shows a comparison of [`div`](#div), [`mod`](#mod), [`quotient`](#quotient) and [`remainder`](#remainder),
with `dividend` from `-7` to `7` and `divisor` either `3` or `-3`.

```text

dividend:   -7 -6 -5 -4 -3 -2 -1  0  1  2  3  4  5  6  7
            -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
divisor = 3
div         -3 -2 -2 -2 -1 -1 -1  0  0  0  1  1  1  2  2
mod          2  0  1  2  0  1  2  0  1  2  0  1  2  0  1

quotient    -2 -2 -1 -1 -1  0  0  0  0  0  1  1  1  2  2
remainder   -1  0 -2 -1  0 -2 -1  0  1  2  0  1  2  0  1

divisor = -3
div          2  2  1  1  1  0  0  0 -1 -1 -1 -2 -2 -2 -3
mod         -1  0 -2 -1  0 -2 -1  0 -2 -1  0 -2 -1  0 -2

quotient     2  2  1  1  1  0  0  0  0  0 -1 -1 -1 -2 -2
remainder   -1  0 -2 -1  0 -2 -1  0  1  2  0  1  2  0  1
```


## Division undefined

All division functions return [`undefined`](#undefined) if divisor is `0`
or either argument is [`undefined`](#undefined).

    -- `1 / 0` is undefined
    SafeInt.div SafeInt.one SafeInt.zero
        |> SafeInt.toInt
        --> Nothing

@docs div, mod, quotient, remainder


# Division Reversed

Functions [`divBy`](#divBy), [`modBy`](#modBy), [`quotientBy`](#quotientBy) and [`remainderBy`](#remainderBy)
are same as basic division functions, except with reversed arguments.

[`modBy`](#modBy) is similar to `Basics.modBy` and [`remainderBy`](#remainderBy) to `Basics.remainderBy`.

    -- `2^40 / 10`
    SafeInt.pow SafeInt.two (SafeInt.new 40)
        |> SafeInt.divBy (SafeInt.new 10)
        |> SafeInt.toInt
        --> Just 109951162777

@docs divBy, modBy, quotientBy, remainderBy


# Division Combined

@docs divMod, quotRem, divModBy, quotRemBy


# Comparison

Operators `==` and `/=` consider [`undefined`](#undefined) to be equal to itself and unequal to any defined value.

@docs compare


# Signs

@docs abs, negate, sign

-}

import SafeInt.Unchecked as Unchecked


{-| A safe 54-bit signed integer.

A [`SafeInt`](#SafeInt) is either defined integer value from [`minValue`](#minValue) to [`maxValue`](#maxValue),
or [`undefined`](#undefined).

-}
type SafeInt
    = Defined Float
    | Undefined



-- CONSTANTS


{-| Maximum possible defined value, `2^53 - 1 = 9 007 199 254 740 991`.

Equal to `Number.MAX_SAFE_INTEGER` in JavaScript.

    SafeInt.maxValue
        |> SafeInt.toInt
        --> Just 9007199254740991

-}
maxValue : SafeInt
maxValue =
    Defined maxFloat


{-| Minimum possible defined value, `- (2^53 - 1) = - 9 007 199 254 740 991`.

Equal to `Number.MIN_SAFE_INTEGER` in JavaScript.

    SafeInt.minValue
        |> SafeInt.toInt
        --> Just -9007199254740991

-}
minValue : SafeInt
minValue =
    Defined minFloat


{-| Undefined value.

Functions return [`undefined`](#undefined) when result can't be represented using an integer
between [`minValue`](#minValue) and [`maxValue`](#maxValue).
For example division by zero or when result is above [`maxValue`](#maxValue).

    -- `1 / 0` is undefined
    SafeInt.div SafeInt.one SafeInt.zero
        |> SafeInt.toInt
        --> Nothing

    -- `2 ^ 55` is undefined
    SafeInt.pow SafeInt.two (SafeInt.new 55)
        |> SafeInt.toInt
        --> Nothing

Operators `==` and `/=` consider [`undefined`](#undefined) to be equal to itself and unequal to any defined value,
so to find out whether [`SafeInt`](#SafeInt) is [`undefined`](#undefined) or not,
you can just compare it to [`undefined`](#undefined).

    SafeInt.div SafeInt.one SafeInt.zero
        == SafeInt.undefined
        --> True

    SafeInt.div SafeInt.one SafeInt.one
        == SafeInt.undefined
        --> False

-}
undefined : SafeInt
undefined =
    Undefined


{-| Number `0`
-}
zero : SafeInt
zero =
    Defined 0.0


{-| Number `1`
-}
one : SafeInt
one =
    Defined 1.0


{-| Number `2`
-}
two : SafeInt
two =
    Defined 2.0



-- CONVERSION - INT


{-| Convert `Int` to [`SafeInt`](#SafeInt), rounding towards zero.

Return [`undefined`](#undefined) if argument is `NaN`,
below [`minValue`](#minValue) or above [`maxValue`](#maxValue).

**Note:** Strange cases where argument is `NaN`, `-Infinity`, `+Infinity` or
non-integer like `1234.5` are supported.

**Note:** Behavior of `Int` for values below `-2^31` and above `2^31 - 1` is undefined in Elm.
As of Elm 0.19.1 conversion from/to `Int` works for full [`SafeInt`](#SafeInt) range
from [`minValue`](#minValue) to [`maxValue`](#maxValue), but this could change in the future.

-}
fromInt : Int -> SafeInt
fromInt x =
    -- OPTIMIZATION NOTE: inlining `truncate` doesn't give speed benefit (tested 2020-06-07)
    truncate <| Basics.toFloat x


{-| Same as [`fromInt`](#fromInt).
-}
new : Int -> SafeInt
new x =
    -- OPTIMIZATION NOTE: inlining `truncate` doesn't give speed benefit (tested 2020-06-07)
    truncate <| Basics.toFloat x


{-| Convert [`SafeInt`](#SafeInt) to `Maybe Int`.

Return `Just value` if [`SafeInt`](#SafeInt) is defined,
and `Nothing` if [`SafeInt`](#SafeInt) is [`undefined`](#undefined).

**Note:** Behavior of `Int` for values below `-2^31` and above `2^31 - 1` is undefined in Elm.
As of Elm 0.19.1 conversion from/to `Int` works for full [`SafeInt`](#SafeInt) range
from [`minValue`](#minValue) to [`maxValue`](#maxValue), but this could change in the future.

-}
toInt : SafeInt -> Maybe Int
toInt x =
    case x of
        Defined value ->
            Just <| Basics.round value

        Undefined ->
            Nothing



-- CONVERSION - FLOAT


{-| Convert `Float` to [`SafeInt`](#SafeInt), rounding towards positive infinity.

Return [`undefined`](#undefined) if argument is `NaN`,
below [`minValue`](#minValue) or above [`maxValue`](#maxValue).

    SafeInt.ceiling 3.8
        |> SafeInt.toInt
        --> Just 4

    SafeInt.ceiling -3.8
        |> SafeInt.toInt
        --> Just -3

-}
ceiling : Float -> SafeInt
ceiling x =
    if Basics.isNaN x || x < minFloat || x > maxFloat then
        Undefined

    else
        Defined <| Basics.toFloat <| Basics.ceiling x


{-| Convert `Float` to [`SafeInt`](#SafeInt), rounding towards negative infinity.

Return [`undefined`](#undefined) if argument is `NaN`,
below [`minValue`](#minValue) or above [`maxValue`](#maxValue).

    SafeInt.floor 3.8
        |> SafeInt.toInt
        --> Just 3

    SafeInt.floor -3.8
        |> SafeInt.toInt
        --> Just -4

-}
floor : Float -> SafeInt
floor x =
    if Basics.isNaN x || x < minFloat || x > maxFloat then
        Undefined

    else
        Defined <| Basics.toFloat <| Basics.floor x


{-| Convert `Float` to [`SafeInt`](#SafeInt), rounding to nearest integer and half towards positive infinity.

Return [`undefined`](#undefined) if argument is `NaN`,
below [`minValue`](#minValue) or above [`maxValue`](#maxValue).

    [ 3.2, 3.5, 3.8 ]
        |> List.map (SafeInt.round >> SafeInt.toInt)
        --> [ Just 3, Just 4, Just 4 ]

    [ -3.8, -3.5, -3.2 ]
        |> List.map (SafeInt.round >> SafeInt.toInt)
        --> [ Just -4, Just -3, Just -3 ]

-}
round : Float -> SafeInt
round x =
    if Basics.isNaN x || x < minFloat || x > maxFloat then
        Undefined

    else
        Defined <| Basics.toFloat <| Basics.round x


{-| Convert [`SafeInt`](#SafeInt) to `Maybe Float`.

Return `Just value` if [`SafeInt`](#SafeInt) is defined,
and `Nothing` if [`SafeInt`](#SafeInt) is [`undefined`](#undefined).

-}
toFloat : SafeInt -> Maybe Float
toFloat x =
    case x of
        Defined value ->
            Just value

        Undefined ->
            Nothing


{-| Convert `Float` to [`SafeInt`](#SafeInt), rounding towards zero.

Return [`undefined`](#undefined) if argument is `NaN`,
below [`minValue`](#minValue) or above [`maxValue`](#maxValue).

    SafeInt.truncate 3.8
        |> SafeInt.toInt
        --> Just 3

    SafeInt.truncate -3.8
        |> SafeInt.toInt
        --> Just -3

-}
truncate : Float -> SafeInt
truncate x =
    -- Basics.truncate can't be used as it only works with 32-bit values
    if Basics.isNaN x || x < minFloat || x > maxFloat then
        Undefined

    else if x < 0 then
        Defined <| Basics.toFloat <| Basics.ceiling x

    else
        Defined <| Basics.toFloat <| Basics.floor x



-- MATH


{-| Addition.

Return [`undefined`](#undefined) if

  - either argument is [`undefined`](#undefined)
  - result would be below [`minValue`](#minValue) or above [`maxValue`](#maxValue)


## Example

    -- `123 + 456`
    SafeInt.add (SafeInt.new 123) (SafeInt.new 456)
        |> SafeInt.toInt
        --> Just 579

-}
add : SafeInt -> SafeInt -> SafeInt
add a b =
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            let
                result =
                    a_ + b_
            in
            if result < minFloat || result > maxFloat then
                Undefined

            else
                Defined result

        _ ->
            Undefined


{-| Multiplication.

Return [`undefined`](#undefined) if

  - either argument is [`undefined`](#undefined)
  - result would be below [`minValue`](#minValue) or above [`maxValue`](#maxValue)


## Example

    -- `123 * 456`
    SafeInt.mul (SafeInt.new 123) (SafeInt.new 456)
        |> SafeInt.toInt
        --> Just 56088

-}
mul : SafeInt -> SafeInt -> SafeInt
mul a b =
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            let
                result =
                    a_ * b_
            in
            if result < minFloat || result > maxFloat then
                Undefined

            else
                Defined result

        _ ->
            Undefined


{-| Power aka exponentiation, rounding towards zero.

Return [`undefined`](#undefined) if

  - in `pow 0 b`, `b <= 0`
  - either argument is [`undefined`](#undefined)
  - result would be below [`minValue`](#minValue) or above [`maxValue`](#maxValue)

The table below shows the return values of `pow a b` near zero.
`U` denotes [`undefined`](#undefined) and `*0` denotes non-integer result rounded towards zero.

```text
  b: -2 -1  0  1  2
 a   -- -- -- -- --
--
-2   *0 *0  1 -2  4
-1    1 -1  1 -1  1
 0    U  U  U  0  0
 1    1  1  1  1  1
 2   *0 *0  1  2  4
```


## Example

    -- `2 ^ 40`
    SafeInt.pow SafeInt.two (SafeInt.new 40)
        |> SafeInt.toInt
        --> Just 1099511627776

**Note:** Opinions differ on what the result of `0 ^ 0`, `NaN ^ 0` and `1 ^ NaN` should be.
[`SafeInt`](#SafeInt) takes the stance to return [`undefined`](#undefined) when uncertain,
so all of these (using [`undefined`](#undefined) instead of `NaN`) return [`undefined`](#undefined).
For more information see e.g. [Zero to the power of zero][00]🢅 and [NaN § Function definition][NaN]🢅.

[00]: https://en.wikipedia.org/wiki/Zero_to_the_power_of_zero
[NaN]: https://en.wikipedia.org/wiki/NaN#Function_definition

-}
pow : SafeInt -> SafeInt -> SafeInt
pow a b =
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            if b_ > 0 then
                let
                    result =
                        a_ ^ b_
                in
                if result < minFloat || result > maxFloat then
                    Undefined

                else
                    Defined result

            else if a_ == 0 then
                Undefined

            else if b_ == 0 || a_ == 1 then
                Defined 1

            else if a_ == -1 then
                Defined <| a_ ^ b_

            else
                Defined 0

        _ ->
            Undefined


{-| Subtraction.

Return [`undefined`](#undefined) if

  - either argument is [`undefined`](#undefined)
  - result would be below [`minValue`](#minValue) or above [`maxValue`](#maxValue)


## Example

    -- `456 - 123`
    SafeInt.sub (SafeInt.new 456) (SafeInt.new 123)
        |> SafeInt.toInt
        --> Just 333

-}
sub : SafeInt -> SafeInt -> SafeInt
sub a b =
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            let
                result =
                    a_ - b_
            in
            if result < minFloat || result > maxFloat then
                Undefined

            else
                Defined result

        _ ->
            Undefined



-- DIVISION


{-| Integer division, rounding towards negative infinity.

See [Division Basics](#division-basics) for more information about division functions.

    SafeInt.div (SafeInt.new 1234) (SafeInt.new 100)
        |> SafeInt.toInt
        --> Just 12

    SafeInt.div (SafeInt.new -1234) (SafeInt.new 100)
        |> SafeInt.toInt
        --> Just -13

-}
div : SafeInt -> SafeInt -> SafeInt
div a b =
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            if b_ == 0 then
                Undefined

            else
                Defined <| Basics.toFloat <| Basics.floor <| a_ / b_

        _ ->
            Undefined


{-| Remainder after [`div`](#div). This is also used for [modular arithmetic][ma]🢅.

See [Division Basics](#division-basics) for more information about division functions.

    SafeInt.mod (SafeInt.new 1234) (SafeInt.new 100)
        |> SafeInt.toInt
        --> Just 34

    SafeInt.mod (SafeInt.new -1234) (SafeInt.new 100)
        |> SafeInt.toInt
        --> Just 66

[ma]: https://en.wikipedia.org/wiki/Modular_arithmetic

-}
mod : SafeInt -> SafeInt -> SafeInt
mod a b =
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            if b_ == 0 then
                Undefined

            else
                -- OPTIMIZATION NOTE: This alternative implementation is slower
                -- Defined <| Basics.toFloat <| Basics.modBy (Basics.round b_) (Basics.round a_)
                Defined <| a_ - b_ * (Basics.toFloat <| Basics.floor <| a_ / b_)

        _ ->
            Undefined


{-| Integer division, rounding towards zero.

This is similar to `//` operator.

See [Division Basics](#division-basics) for more information about division functions.

    SafeInt.quotient (SafeInt.new 1234) (SafeInt.new 100)
        |> SafeInt.toInt
        --> Just 12

    SafeInt.quotient (SafeInt.new -1234) (SafeInt.new 100)
        |> SafeInt.toInt
        --> Just -12

-}
quotient : SafeInt -> SafeInt -> SafeInt
quotient a b =
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            if b_ == 0 then
                Undefined

            else
                Defined <| Unchecked.truncate <| a_ / b_

        _ ->
            Undefined


{-| Remainder after [`quotient`](#quotient).

See [Division Basics](#division-basics) for more information about division functions.

    SafeInt.remainder (SafeInt.new 1234) (SafeInt.new 100)
        |> SafeInt.toInt
        --> Just 34

    SafeInt.remainder (SafeInt.new -1234) (SafeInt.new 100)
        |> SafeInt.toInt
        --> Just -34

-}
remainder : SafeInt -> SafeInt -> SafeInt
remainder a b =
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            if b_ == 0 then
                Undefined

            else
                -- OPTIMIZATION NOTE: This alternative implementation is about same speed
                -- Defined <| a_ - b_ * (Unchecked.truncate <| a_ / b_)
                Defined <| Basics.toFloat <| Basics.remainderBy (Basics.round b_) (Basics.round a_)

        _ ->
            Undefined



-- DIVISION REVERSED


{-| Same as [`div`](#div) except with reversed arguments.
-}
divBy : SafeInt -> SafeInt -> SafeInt
divBy b a =
    -- OPTIMIZATION NOTE: inlining `div` gave >30% speed increase (2020-06-07)
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            if b_ == 0 then
                Undefined

            else
                Defined <| Basics.toFloat <| Basics.floor <| a_ / b_

        _ ->
            Undefined


{-| Same as [`mod`](#mod) except with reversed arguments.

This is similar to `Basics.modBy`.

-}
modBy : SafeInt -> SafeInt -> SafeInt
modBy b a =
    -- OPTIMIZATION NOTE: inlining `mod` gave >20% speed increase (2020-06-07)
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            if b_ == 0 then
                Undefined

            else
                Defined <| a_ - b_ * (Basics.toFloat <| Basics.floor <| a_ / b_)

        _ ->
            Undefined


{-| Same as [`quotient`](#quotient) except with reversed arguments.
-}
quotientBy : SafeInt -> SafeInt -> SafeInt
quotientBy b a =
    -- OPTIMIZATION NOTE: inlining `quotient` gave >30% speed increase (2020-06-07)
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            if b_ == 0 then
                Undefined

            else
                Defined <| Unchecked.truncate <| a_ / b_

        _ ->
            Undefined


{-| Same as [`remainder`](#remainder) except with reversed arguments.

This is similar to `Basics.remainderBy`.

-}
remainderBy : SafeInt -> SafeInt -> SafeInt
remainderBy b a =
    -- OPTIMIZATION NOTE: inlining `remainder` gave >20% speed increase (2020-06-07)
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            if b_ == 0 then
                Undefined

            else
                Defined <| Basics.toFloat <| Basics.remainderBy (Basics.round b_) (Basics.round a_)

        _ ->
            Undefined



-- DIVISION COMBINED


{-| Combines [`div`](#div) and [`mod`](#mod) into a single function.

`divMod a b` is same as `( div a b, mod a b )` except faster.

    SafeInt.divMod (SafeInt.new 1234) (SafeInt.new 100)
        |> Tuple.mapBoth SafeInt.toInt SafeInt.toInt
        --> ( Just 12, Just 34 )

    SafeInt.divMod (SafeInt.new -1234) (SafeInt.new 100)
        |> Tuple.mapBoth SafeInt.toInt SafeInt.toInt
        --> ( Just -13, Just 66 )

-}
divMod : SafeInt -> SafeInt -> ( SafeInt, SafeInt )
divMod a b =
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            if b_ == 0 then
                ( Undefined, Undefined )

            else
                let
                    div_ =
                        Basics.toFloat <| Basics.floor <| a_ / b_
                in
                ( Defined div_, Defined <| a_ - b_ * div_ )

        _ ->
            ( Undefined, Undefined )


{-| Same as [`divMod`](#divMod) except with reversed arguments.
-}
divModBy : SafeInt -> SafeInt -> ( SafeInt, SafeInt )
divModBy b a =
    -- OPTIMIZATION NOTE: inlining `divMod` gave >20% speed increase (2020-06-07)
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            if b_ == 0 then
                ( Undefined, Undefined )

            else
                let
                    div_ =
                        Basics.toFloat <| Basics.floor <| a_ / b_
                in
                ( Defined div_, Defined <| a_ - b_ * div_ )

        _ ->
            ( Undefined, Undefined )


{-| Combines [`quotient`](#quotient) and [`remainder`](#remainder) into a single function.

`quotRem a b` is same as `( quotient a b, remainder a b )` except faster.

    SafeInt.quotRem (SafeInt.new 1234) (SafeInt.new 100)
        |> Tuple.mapBoth SafeInt.toInt SafeInt.toInt
        --> ( Just 12, Just 34 )

    SafeInt.quotRem (SafeInt.new -1234) (SafeInt.new 100)
        |> Tuple.mapBoth SafeInt.toInt SafeInt.toInt
        --> ( Just -12, Just -34 )

-}
quotRem : SafeInt -> SafeInt -> ( SafeInt, SafeInt )
quotRem a b =
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            if b_ == 0 then
                ( Undefined, Undefined )

            else
                let
                    quotient_ =
                        Unchecked.truncate <| a_ / b_
                in
                ( Defined quotient_, Defined <| a_ - b_ * quotient_ )

        _ ->
            ( Undefined, Undefined )


{-| Same as [`quotRem`](#quotRem) except with reversed arguments.
-}
quotRemBy : SafeInt -> SafeInt -> ( SafeInt, SafeInt )
quotRemBy b a =
    -- OPTIMIZATION NOTE: inlining `quotRem` gave >20% speed increase (2020-06-07)
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            if b_ == 0 then
                ( Undefined, Undefined )

            else
                let
                    quotient_ =
                        Unchecked.truncate <| a_ / b_
                in
                ( Defined quotient_, Defined <| a_ - b_ * quotient_ )

        _ ->
            ( Undefined, Undefined )



-- COMPARISON


{-| Compare two [`SafeInt`](#SafeInt):s.

First argument defines how [`undefined`](#undefined) is handled:

  - if `True`, [`undefined`](#undefined) is equal to itself and smaller than any defined value
  - if `False`, [`undefined`](#undefined) is equal to itself and larger than any defined value


## Example

    [ SafeInt.new 34
    , SafeInt.new 12
    , SafeInt.undefined
    , SafeInt.new 56
    , SafeInt.undefined
    ]
        |> List.sortWith (SafeInt.compare True)
        |> List.map SafeInt.toInt
        --> [ Nothing, Nothing, Just 12, Just 34, Just 56 ]

-}
compare : Bool -> SafeInt -> SafeInt -> Basics.Order
compare undefinedIsSmallest a b =
    case ( a, b ) of
        ( Defined a_, Defined b_ ) ->
            Basics.compare a_ b_

        ( Undefined, Defined _ ) ->
            if undefinedIsSmallest then
                Basics.LT

            else
                Basics.GT

        ( Defined _, Undefined ) ->
            if undefinedIsSmallest then
                Basics.GT

            else
                Basics.LT

        ( Undefined, Undefined ) ->
            Basics.EQ



-- SIGNS


{-| Absolute value.

Return [`undefined`](#undefined) if argument is [`undefined`](#undefined).

    SafeInt.abs (SafeInt.new 123)
        |> SafeInt.toInt
        --> Just 123

    SafeInt.abs (SafeInt.new -123)
        |> SafeInt.toInt
        --> Just 123

-}
abs : SafeInt -> SafeInt
abs x =
    case x of
        Defined x_ ->
            Defined <| Basics.abs x_

        Undefined ->
            Undefined


{-| Negation.

Return [`undefined`](#undefined) if argument is [`undefined`](#undefined).

    SafeInt.negate (SafeInt.new 123)
        |> SafeInt.toInt
        --> Just -123

    SafeInt.negate (SafeInt.new -123)
        |> SafeInt.toInt
        --> Just 123

-}
negate : SafeInt -> SafeInt
negate x =
    case x of
        Defined x_ ->
            Defined <| Basics.negate x_

        Undefined ->
            Undefined


{-| Sign.

  - `1` if argument is positive
  - `-1` if argument is negative
  - `0` if argument is zero
  - [`undefined`](#undefined) if argument is [`undefined`](#undefined)


## Examples

    SafeInt.sign (SafeInt.new 123)
        |> SafeInt.toInt
        --> Just 1

    SafeInt.sign (SafeInt.new -123)
        |> SafeInt.toInt
        --> Just -1

-}
sign : SafeInt -> SafeInt
sign x =
    case x of
        Defined x_ ->
            if x_ > 0 then
                Defined 1

            else if x_ < 0 then
                Defined -1

            else
                Defined 0

        Undefined ->
            Undefined



-- INTERNALS - CONSTANTS


maxFloat : Float
maxFloat =
    9007199254740991.0


maxInt : Int
maxInt =
    9007199254740991


minFloat : Float
minFloat =
    -9007199254740991.0


minInt : Int
minInt =
    -9007199254740991
