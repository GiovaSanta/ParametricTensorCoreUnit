# Klessydra TCU automated validation summary

| Format | Exact match % | Mean abs error | Max abs error | RMSE | Mean rel error | Max rel error | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| fp8 | 41.406250% | 3.99750996016 | 32 | 6.91503869904 | 0.225391314087 | 12 | Validated, nonzero numerical error |
| fp16 | 39.453125% | 0.00817346572876 | 0.0625 | 0.0131119996106 | 0.00123408499541 | 0.0276520864756 | Validated, nonzero numerical error |
| fp32 | 38.281250% | 6.90147280693e-05 | 0.00048828125 | 0.000107272175058 | 3.2725315192e-07 | 2.25436725353e-05 | Validated, nonzero numerical error |
| posit8 | 37.890625% | 3.49438476562 | 32 | 7.38531923073 | 0.461408728091 | 21.2608695652 | Validated, nonzero numerical error |
| posit16 | 40.625000% | 0.00574660301208 | 0.03125 | 0.0100397462035 | 0.000888902941904 | 0.0200081665986 | Validated, nonzero numerical error |
| posit32 | 37.890625% | 1.49911502376e-05 | 6.103515625e-05 | 2.22202931172e-05 | 8.5127409634e-08 | 8.29450803388e-06 | Validated, nonzero numerical error |
| lns16 | 32.421875% | 0.0207724946815 | 0.14189611723 | 0.0310779792575 | 0.00258721609081 | 0.0964290818164 | Validated, nonzero numerical error |
| fxp8_16 | 0.781250% | 0.0441207595148 | 0.1921378082 | 0.0564228239993 | 0.228882760079 | 42.9238570154 | Validated, nonzero numerical error |
| fxp16_32 | 0.000000% | 0.00143551423161 | 0.00529502203395 | 0.00177128288286 | 0.00439816362565 | 0.546091104777 | Validated, nonzero numerical error |
| int8_16 | 100.000000% | 0 | 0 | 0 | 0 | 0 | Exact |
| int16_32 | 100.000000% | 0 | 0 | 0 | 0 | 0 | Exact |

Generated from the per-format `validation_report.txt` files.
