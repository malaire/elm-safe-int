# elm-safe-int

A safe 54-bit signed integer for use cases where normal `Int` isn't sufficient and 54-bit range will suffice.

```elm
import SafeInt

-- `2^40 / 10`
SafeInt.pow SafeInt.two (SafeInt.new 40)
    |> SafeInt.divBy (SafeInt.new 10)
    |> SafeInt.toInt
    --> Just 109951162777

-- `1 / 0` is undefined
SafeInt.div SafeInt.one SafeInt.zero
    |> SafeInt.toInt
    --> Nothing
```

`Unchecked` versions of functions are also provided for use cases where more speed is required at the cost of some lost safety and features.


    import SafeInt.Unchecked as Unchecked

    -- `2^40 / 10`
    Unchecked.pow 2 40
        |> Unchecked.divBy 10
        --> 109951162777


## Design Goals

Primary design goal is to fix many problems of normal `Int` with which:


  - operations can crash
      - e.g. `modBy 0 0`
  - operations can return e.g. `NaN`, `-Infinity`, `+Infinity` or `0.5`
      - e.g. `remainderBy 0 0`, `round(-1/0)`, `round 0 ^ -1`, `round 2 ^ -1`
  - operations don't work for full 54-bit JavaScript safe integer range
      - e.g. `2^40 // 10`
  - operations are not consistent
      - e.g. `modBy 0 0` crashes but `remainderBy 0 0` returns `NaN`
  - operations are not properly documented
      - e.g. many of the examples mentioned above
  - behavior depends on compilation target
      - e.g. `2000000000 + 1000000000` will give different result when compiling Elm to JavaScript versus WebAssembly*

So in contrast to `Int`, with [`SafeInt`](SafeInt#SafeInt):

  - operations never crash
  - operations either return an integer or [`undefined`](SafeInt#undefined), nothing else
  - operations work for full 54-bit JavaScript safe integer range
  - operations are consistent
  - operations are properly documented, including all cases which can result in [`undefined`](SafeInt#undefined)
  - behavior is same on any compilation target which supports IEEE 754 binary64, including JavaScript and WebAssembly*

Secondary design goal is speed.

\*) Elm compiler doesn't yet support compiling to WebAssembly.

## Performance

I'm not interested in doing proper benchmarking, but in some quick benchmarks:

 - [`SafeInt`](SafeInt#SafeInt) was up to 6 times slower than `Int` or `Float`
 - `Unchecked` was up to 3 times slower than  `Int` or `Float`
 - [`SafeInt`](SafeInt#SafeInt) was up to 2.5 times slower than `Unchecked`

Benchmarking was done 2020-06-07 with Elm 0.19.1 and `elm make --optimize` and run in Firefox 68.8 in Debian.

Some example benchmarks are included in `benchmarks` directory of source.

## Missing functionality

- Bitwise operations

   I don't think it makes sense to implement bitwise operations for [`SafeInt`](SafeInt#SafeInt),
   but if use case is found I can reconsider this.

   As `Float` doesn't support bitwise operations directly these would need to be simulated somehow.

