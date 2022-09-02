--bbox-unsup
-lint-only
+define+VERILATOR_LINT
+define+FORMAL

-F ../ip/cache_ctrl/lint/filelist.f
-F ../ip/opi_phy/lint/filelist.f
-F ../ip/prim/lint/filelist.f
-F ../ip/simlib/lint/filelist.f

+incdir+../ip/sky130_sram_macros/sky130_sram_1kbyte_1rw1r_32x256_8
+incdir+../ip/sky130_sram_macros/sky130_sram_2kbyte_1rw1r_32x512_8
+incdir+../ip/sky130_sram_macros/sky130_sram_1kbyte_1rw_32x256_8

waiver.vlt
