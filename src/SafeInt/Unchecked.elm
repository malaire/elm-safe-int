module SafeInt.Unchecked exposing
    ( minValue, maxValue
    , fromInt, toInt
    , round, ceiling, truncate, floor
    , add, sub, mul, pow
    , div, mod, quotient, remainder
    , divBy, modBy, quotientBy, remainderBy
    , divMod, quotRem, divModBy, quotRemBy
    , abs, negate, sign
    )

{-| Unchecked versions of [`SafeInt`](SafeInt#SafeInt) functions which operate directly on `Float` values.

    import SafeInt.Unchecked as Unchecked

    -- `2^40 / 10`
    Unchecked.pow 2 40
        |> Unchecked.divBy 10
        --> 109951162777

It is recommended to use [`SafeInt`](SafeInt#SafeInt) functions instead of `Unchecked` functions,
unless more speed is required at the cost of some lost safety and features.


# Difference to SafeInt

`Unchecked` functions are faster than corresponding [`SafeInt`](SafeInt#SafeInt) functions because they

  - operate directly on `Float` values
  - don't support [`undefined`](SafeInt#undefined) value
  - don't check that arguments are valid
  - don't check whether result would be between [`minValue`](#minValue) and [`maxValue`](#maxValue)

Therefore with `Unchecked` functions it's users responsibility to make sure
that arguments are valid and such that result will be within allowed limits.

As long as undefined behavior is avoided,
`Unchecked` functions will work exactly like corresponding [`SafeInt`](SafeInt#SafeInt) functions.


## Usage rules

When using `Unchecked` functions

  - arguments must be exact integer(\*) values and
  - arguments must be between [`minValue`](#minValue) and [`maxValue`](#maxValue) and
  - arguments must be such that corresponding [`SafeInt`](SafeInt#SafeInt) function would not return [`undefined`](SafeInt#undefined)

\*) This doesn't apply to [`round`](#round), [`ceiling`](#ceiling), [`truncate`](#truncate) and [`floor`](#floor)
which allow non-integer arguments.

**If these rules are not followed, behavior of `Unchecked` functions is undefined.**


# Constants

@docs minValue, maxValue


# Conversion from/to Int

@docs fromInt, toInt


# Rounding

Comparison of rounding functions:

```text
          -3.8 -3.5 -3.2   ~    3.2  3.5  3.8
          ---- ---- ----       ---- ---- ----
round     -4   -3   -3          3    4    4
ceiling   -3   -3   -3          4    4    4
truncate  -3   -3   -3          3    3    3
floor     -4   -4   -4          3    3    3
```

@docs round, ceiling, truncate, floor


# Math

@docs add, sub, mul, pow


# Division Basics


## Division undefined

Behavior of division functions is undefined if

  - divisor is `0`
  - either argument is not exact integer
  - either argument is below [`minValue`](#minValue) or above [`maxValue`](#maxValue)

@docs div, mod, quotient, remainder


# Division Reversed

Functions [`divBy`](#divBy), [`modBy`](#modBy), [`quotientBy`](#quotientBy) and [`remainderBy`](#remainderBy)
are same as basic division functions, except with reversed arguments.

[`modBy`](#modBy) is similar to `Basics.modBy` and [`remainderBy`](#remainderBy) to `Basics.remainderBy`.

    import SafeInt.Unchecked as Unchecked

    -- `2^40 / 10`
    Unchecked.pow 2 40
        |> Unchecked.divBy 10
        --> 109951162777

@docs divBy, modBy, quotientBy, remainderBy


# Division Combined

@docs divMod, quotRem, divModBy, quotRemBy


# Signs

@docs abs, negate, sign

-}

-- CONSTANTS


{-| Maximum possible value, `2^53 - 1 = 9 007 199 254 740 991`.

Equal to `Number.MAX_SAFE_INTEGER` in JavaScript.

    SafeInt.Unchecked.maxValue
        --> 9007199254740991

-}
maxValue : Float
maxValue =
    9007199254740991.0


{-| Minimum possible value, `- (2^53 - 1) = - 9 007 199 254 740 991`.

Equal to `Number.MIN_SAFE_INTEGER` in JavaScript.

    SafeInt.Unchecked.minValue
        --> -9007199254740991

-}
minValue : Float
minValue =
    -9007199254740991.0



-- CONVERSION - INT


{-| Convert `Int` to `Float`.

Behavior is undefined if

  - argument is not exact integer
  - argument is below [`minValue`](#minValue) or above [`maxValue`](#maxValue)

**Note:** You can use `Basics.toFloat` instead of this function.

**Note:** Unlike [`SafeInt.fromInt`](SafeInt#fromInt),
this function does not allow non-integer argument.

**Note:** Behavior of `Int` for values below `-2^31` and above `2^31 - 1` is undefined in Elm.
As of Elm 0.19.1 conversion from/to `Int` works for full [`SafeInt`](SafeInt#SafeInt) range
from [`minValue`](#minValue) to [`maxValue`](#maxValue), but this could change in the future.

-}
fromInt : Int -> Float
fromInt x =
    Basics.toFloat <| x


{-| Convert `Float` to `Int`.

Behavior is undefined if

  - argument is not exact integer
  - argument is below [`minValue`](#minValue) or above [`maxValue`](#maxValue)

**Note:** You can use `Basics.round`, `Basics.floor` or `Basics.ceiling` instead of this function.

**Note:** Unlike [`SafeInt.toInt`](SafeInt#toInt),
return value is `Int` instead of `Maybe Int` as `Unchecked` functions don't support [`undefined`](SafeInt#undefined) value.

**Note:** Behavior of `Int` for values below `-2^31` and above `2^31 - 1` is undefined in Elm.
As of Elm 0.19.1 conversion from/to `Int` works for full [`SafeInt`](SafeInt#SafeInt) range
from [`minValue`](#minValue) to [`maxValue`](#maxValue), but this could change in the future.

-}
toInt : Float -> Int
toInt x =
    Basics.round x



-- CONVERSION - FLOAT


{-| Round to integer towards positive infinity.

Behavior is undefined if argument is `NaN`, below [`minValue`](#minValue) or above [`maxValue`](#maxValue).

    SafeInt.Unchecked.ceiling 3.8
        --> 4.0

    SafeInt.Unchecked.ceiling -3.8
        --> -3.0

-}
ceiling : Float -> Float
ceiling x =
    Basics.toFloat <| Basics.ceiling x


{-| Round to integer towards negative infinity.

Behavior is undefined if argument is `NaN`, below [`minValue`](#minValue) or above [`maxValue`](#maxValue).

    SafeInt.Unchecked.floor 3.8
        --> 3.0

    SafeInt.Unchecked.floor -3.8
        --> -4.0

-}
floor : Float -> Float
floor x =
    Basics.toFloat <| Basics.floor x


{-| Round to nearest integer and half towards positive infinity.

Behavior is undefined if argument is `NaN`, below [`minValue`](#minValue) or above [`maxValue`](#maxValue).

    [ 3.2, 3.5, 3.8 ]
        |> List.map SafeInt.Unchecked.round
        --> [ 3.0, 4.0, 4.0 ]

    [ -3.8, -3.5, -3.2 ]
        |> List.map SafeInt.Unchecked.round
        --> [ -4.0, -3.0, -3.0 ]

-}
round : Float -> Float
round x =
    Basics.toFloat <| Basics.round x


{-| Round to integer towards zero.

Behavior is undefined if argument is `NaN`, below [`minValue`](#minValue) or above [`maxValue`](#maxValue).

    SafeInt.Unchecked.truncate 3.8
        --> 3.0

    SafeInt.Unchecked.truncate -3.8
        --> -3.0

-}
truncate : Float -> Float
truncate x =
    -- Basics.truncate can't be used as it only works with 32-bit values
    if x < 0 then
        Basics.toFloat <| Basics.ceiling x

    else
        Basics.toFloat <| Basics.floor x



-- MATH


{-| Addition.

Behavior is undefined if

  - either argument is not exact integer
  - either argument is below [`minValue`](#minValue) or above [`maxValue`](#maxValue)
  - result would be below [`minValue`](#minValue) or above [`maxValue`](#maxValue)

**Note:** You can use `+` operator instead of this function.

-}
add : Float -> Float -> Float
add =
    (+)


{-| Multiplication.

Behavior is undefined if

  - either argument is not exact integer
  - either argument is below [`minValue`](#minValue) or above [`maxValue`](#maxValue)
  - result would be below [`minValue`](#minValue) or above [`maxValue`](#maxValue)

**Note:** You can use `*` operator instead of this function.

-}
mul : Float -> Float -> Float
mul =
    (*)


{-| Power aka exponentiation, rounding towards zero.

Behavior is undefined if

  - in `pow 0 b`, `b <= 0`
  - either argument is not exact integer
  - either argument is below [`minValue`](#minValue) or above [`maxValue`](#maxValue)
  - result would be below [`minValue`](#minValue) or above [`maxValue`](#maxValue)

The table below shows the return values of `pow a b` near zero.
`U` denotes undefined behavior and `*0` denotes non-integer result rounded towards zero.

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

    SafeInt.Unchecked.pow 2 40
        --> 1099511627776

**Note:** Opinions differ on what the result of `0 ^ 0` should be.
[`SafeInt`](SafeInt#SafeInt) takes the stance that when uncertain, it's undefined behavior.
For more information see e.g. [Zero to the power of zero][00]🢅.

[00]: https://en.wikipedia.org/wiki/Zero_to_the_power_of_zero

-}
pow : Float -> Float -> Float
pow a b =
    if b >= 0 || a == 1 || a == -1 then
        a ^ b

    else
        0


{-| Subtraction.

Behavior is undefined if

  - either argument is not exact integer
  - either argument is below [`minValue`](#minValue) or above [`maxValue`](#maxValue)
  - result would be below [`minValue`](#minValue) or above [`maxValue`](#maxValue)

**Note:** You can use `-` operator instead of this function.

-}
sub : Float -> Float -> Float
sub =
    (-)



-- DIVISION


{-| Integer division, rounding towards negative infinity.

See [Division undefined](#division-undefined) for undefined behavior
and [SafeInt § Division Basics](SafeInt#division-basics) for more information about division functions.

    SafeInt.Unchecked.div 1234 100
        --> 12

    SafeInt.Unchecked.div -1234 100
        --> -13

-}
div : Float -> Float -> Float
div a b =
    Basics.toFloat <| Basics.floor <| a / b


{-| Remainder after [`div`](#div). This is also used for [modular arithmetic][ma]🢅.

See [Division undefined](#division-undefined) for undefined behavior
and [SafeInt § Division Basics](SafeInt#division-basics) for more information about division functions.

    SafeInt.Unchecked.mod 1234 100
        --> 34

    SafeInt.Unchecked.mod -1234 100
        --> 66

[ma]: https://en.wikipedia.org/wiki/Modular_arithmetic

-}
mod : Float -> Float -> Float
mod a b =
    -- OPTIMIZATION NOTE: This alternative implementation is slower
    -- Basics.toFloat <| Basics.modBy (Basics.round b) (Basics.round a)
    a - b * (Basics.toFloat <| Basics.floor <| a / b)


{-| Integer division, rounding towards zero.

This is similar to `//` operator.

See [Division undefined](#division-undefined) for undefined behavior
and [SafeInt § Division Basics](SafeInt#division-basics) for more information about division functions.

    SafeInt.Unchecked.quotient 1234 100
        --> 12

    SafeInt.Unchecked.quotient -1234 100
        --> -12

-}
quotient : Float -> Float -> Float
quotient a b =
    truncate <| a / b


{-| Remainder after [`quotient`](#quotient).

See [Division undefined](#division-undefined) for undefined behavior
and [SafeInt § Division Basics](SafeInt#division-basics) for more information about division functions.

    SafeInt.Unchecked.remainder 1234 100
        --> 34

    SafeInt.Unchecked.remainder -1234 100
        --> -34

-}
remainder : Float -> Float -> Float
remainder a b =
    -- OPTIMIZATION NOTE: This alternative implementation is about same speed
    -- a - b * (truncate <| a / b)
    Basics.toFloat <| Basics.remainderBy (Basics.round b) (Basics.round a)



-- DIVISION REVERSED


{-| Same as [`div`](#div) except with reversed arguments.
-}
divBy : Float -> Float -> Float
divBy b a =
    -- OPTIMIZATION NOTE: inlining `div` gave >30% speed increase (2020-06-07)
    Basics.toFloat <| Basics.floor <| a / b


{-| Same as [`mod`](#mod) except with reversed arguments.

This is similar to `Basics.modBy`.

-}
modBy : Float -> Float -> Float
modBy b a =
    -- OPTIMIZATION NOTE: inlining `mod` gave >30% speed increase (2020-06-07)
    a - b * (Basics.toFloat <| Basics.floor <| a / b)


{-| Same as [`quotient`](#quotient) except with reversed arguments.
-}
quotientBy : Float -> Float -> Float
quotientBy b a =
    -- OPTIMIZATION NOTE: inlining `quotient` gave >30% speed increase (2020-06-07)
    truncate <| a / b


{-| Same as [`remainder`](#remainder) except with reversed arguments.

This is similar to `Basics.remainderBy`.

-}
remainderBy : Float -> Float -> Float
remainderBy b a =
    -- OPTIMIZATION NOTE: inlining `remainder` gave >30% speed increase (2020-06-07)
    Basics.toFloat <| Basics.remainderBy (Basics.round b) (Basics.round a)



-- DIVISION COMBINED


{-| Combines [`div`](#div) and [`mod`](#mod) into a single function.

`divMod a b` is same as `( div a b, mod a b )` except faster.

    SafeInt.Unchecked.divMod 1234 100
        --> ( 12, 34 )

    SafeInt.Unchecked.divMod -1234 100
        --> ( -13, 66 )

-}
divMod : Float -> Float -> ( Float, Float )
divMod a b =
    let
        div_ =
            Basics.toFloat <| Basics.floor <| a / b
    in
    ( div_, a - b * div_ )


{-| Same as [`divMod`](#divMod) except with reversed arguments.
-}
divModBy : Float -> Float -> ( Float, Float )
divModBy b a =
    -- OPTIMIZATION NOTE: inlining `divMod` gave >20% speed increase (2020-06-07)
    let
        div_ =
            Basics.toFloat <| Basics.floor <| a / b
    in
    ( div_, a - b * div_ )


{-| Combines [`quotient`](#quotient) and [`remainder`](#remainder) into a single function.

`quotRem a b` is same as `( quotient a b, remainder a b )` except faster.

    SafeInt.Unchecked.quotRem 1234 100
        --> ( 12, 34 )

    SafeInt.Unchecked.quotRem -1234 100
        --> ( -12, -34 )

-}
quotRem : Float -> Float -> ( Float, Float )
quotRem a b =
    let
        quotient_ =
            -- OPTIMIZATION NOTE: inlining `truncate` doesn't give significant speed benefit (tested 2020-06-07)
            truncate <| a / b
    in
    ( quotient_, a - b * quotient_ )


{-| Same as [`quotRem`](#quotRem) except with reversed arguments.
-}
quotRemBy : Float -> Float -> ( Float, Float )
quotRemBy b a =
    -- OPTIMIZATION NOTE: inlining `divMod` gave >20% speed increase (2020-06-07)
    let
        quotient_ =
            truncate <| a / b
    in
    ( quotient_, a - b * quotient_ )



-- SIGNS


{-| Absolute value.

Behavior is undefined if

  - argument is not exact integer value
  - argument is below [`minValue`](#minValue) or above [`maxValue`](#maxValue)

**Note:** You can use `Basics.abs` instead of this function.

-}
abs : Float -> Float
abs =
    Basics.abs


{-| Negation.

Behavior is undefined if

  - argument is not exact integer value
  - argument is below [`minValue`](#minValue) or above [`maxValue`](#maxValue)

**Note:** You can use `Basics.negate` instead of this function.

-}
negate : Float -> Float
negate =
    Basics.negate


{-| Sign.

  - `1` if argument is positive
  - `-1` if argument is negative
  - `0` if argument is zero

Behavior is undefined if

  - argument is not exact integer value
  - argument is below [`minValue`](#minValue) or above [`maxValue`](#maxValue)


## Examples

    SafeInt.Unchecked.sign 123
        --> 1

    SafeInt.Unchecked.sign -123
        --> -1

-}
sign : Float -> Float
sign x =
    if x > 0 then
        1

    else if x < 0 then
        -1

    else
        0
