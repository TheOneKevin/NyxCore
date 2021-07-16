## SystemVerilog supported features
---

1. Only packed structs and unions are well-supported.
2. Do not use interfaces, type parameters or any other non-struct SV features (ensure yosys will synthesize).
3. Use `always_ff` and `always_comb` instead of `always` whenever possible.
4. Use `wire` for (unclocked) continuous `assign`. Use `reg` for clocked nonblocking assignments. Do not use `logic` for signals as it will not simulate properly under Verilator.
5. Icarus verilog testbenches will not run SV. Instead, use `sv2v` to convert SV to Verilog.
