## Coding Style Guide
---

**Signal naming convention:**

1. Suffix module ports with `_i` and `_o` for input/outputs respectively
2. Prefix signals with `d` or `u` to indicate upstream or downstream ports.
    - For instance, `drdy_i` or `uvld_i`
3. Signals with suffix `b` indicate active low signals.
    - For instance, `web_o` indicates write-enable active-low output port while `we_o` indicates a write-enable active-high output port.
 
**Coding style (optional suggestions):**

1. Generate blocks in non-primitives should be named and prefixed with `gen_`
2. In top level modules, combinational logic (especially involving MUXs) should be in named blocks labelled with prefix `cmb_`.
    - Use your best judgement on this one
3. State machine states should be set as `localparam`.

## Supported SystemVerilog Features
---

1. Only packed structs and unions are well-supported.
2. Do not use `logic` in module parameters.
