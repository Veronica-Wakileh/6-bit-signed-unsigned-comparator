# 6-bit Signed/Unsigned Structural Comparator

A structural Verilog implementation of a 6-bit comparator that supports both unsigned and signed (2's complement) comparison, developed for the **Advanced Digital Design (ENCS3310)** course at Birzeit University.

## Overview

This project implements a clocked structural comparator that takes two 6-bit inputs `A` and `B` along with a 1-bit mode-select signal `S`, and produces three mutually exclusive outputs indicating whether `A` is equal to, greater than, or less than `B`. The design is built from primitive logic gates (AND, OR, NAND, NOR, XOR, XNOR, NOT) with explicit propagation delays, and uses D flip-flops on inputs and outputs to synchronize the data path with the clock and suppress glitches caused by accumulated gate delays.

A behavioral reference comparator and a self-checking testbench are included to validate the structural design against expected results.

## Features

- 6-bit comparison with three outputs: Equal (`E`), Greater Than (`GT`), Less Than (`LT`)
- Dual-mode operation: unsigned and signed (2's complement)
- Fully structural implementation using gate-level primitives with timing delays
- Input and output registers (D flip-flops) for synchronous, clocked operation
- Behavioral reference model used as a golden comparator
- Self-checking testbench with random stimulus and error counting
- Maximum data-path latency: **150 time units**

## Design Description

The comparator is implemented in a single Verilog file containing four modules:

- `Comparator` — top-level structural design
- `mux2to1` — 2-to-1 multiplexer (gate-level) used to select between signed and unsigned results
- `DFF` — positive-edge-triggered D flip-flop used as the input/output register
- `B_Comparator` — behavioral reference model used by the testbench
- `tb_comparator` — testbench

Inputs `A`, `B`, and `S` are first registered through D flip-flops. Equality is computed using bitwise XNOR followed by an AND reduction. Greater-than and less-than terms are generated using a hierarchical gate network for unsigned comparison, then adjusted using the sign bits to produce the signed result. Two 2-to-1 multiplexers select between the unsigned and signed `GT`/`LT` results based on `S`. The final outputs are registered before being driven out as `RegE`, `RegGT`, and `RegLT`.

Gate delays used in the design (as in the project report):

| Gate              | Delay (time units) |
|-------------------|--------------------|
| AND / OR          | 7                  |
| NAND / NOR        | 5                  |
| XOR               | 10                 |
| XNOR              | 9                  |
| NOT               | 4                  |

## Modes of Operation

| `S` | Mode      | Range          | Notes                                  |
|-----|-----------|----------------|----------------------------------------|
| 0   | Unsigned  | 0 to 63        | All 6 bits treated as magnitude        |
| 1   | Signed    | −32 to 31      | 2's complement; MSB is the sign bit    |

In both modes, exactly one of `E`, `GT`, `LT` is high at any valid sampled output.

## Inputs and Outputs

| Signal  | Direction | Width | Description                                     |
|---------|-----------|-------|-------------------------------------------------|
| `A`     | Input     | 6     | First operand                                   |
| `B`     | Input     | 6     | Second operand                                  |
| `S`     | Input     | 1     | Mode select (0 = unsigned, 1 = signed)          |
| `CLK`   | Input     | 1     | Clock signal (positive-edge triggered)          |
| `RegE`  | Output    | 1     | Registered Equal flag (`A == B`)                |
| `RegGT` | Output    | 1     | Registered Greater-Than flag (`A > B`)          |
| `RegLT` | Output    | 1     | Registered Less-Than flag (`A < B`)             |

## How the Comparator Works

1. **Register stage (input):** `A`, `B`, and `S` are sampled into D flip-flops on the rising clock edge to produce `RegA`, `RegB`, and `RegS`.
2. **Bitwise XNOR:** `X[i] = RegA[i] XNOR RegB[i]` indicates per-bit equality.
3. **Equality:** `E = AND(X[5..0])`.
4. **Unsigned GT / LT:** Computed using a hierarchical AND/OR network that scans from MSB to LSB, propagating equality through `X[i]`.
5. **Signed correction:** The sign bits of `A` and `B` are combined (NOR) and XNOR'd with the unsigned `GT` / `LT` results to produce the signed versions.
6. **Mode select:** Two 2-to-1 multiplexers, controlled by `RegS`, select between unsigned and signed results.
7. **Register stage (output):** Final `E`, `GT`, `LT` are registered into `RegE`, `RegGT`, `RegLT`.

## Simulation and Testing

The testbench (`tb_comparator`) instantiates both the structural `Comparator` and the behavioral `B_Comparator` reference model with the same inputs, generates **10 random test vectors** for `A`, `B`, and `S`, and waits 150 time units between vectors to allow signals to settle through the registered structural path. After each vector, the `Compare_outputs` task checks the structural outputs against the behavioral outputs and prints a **Test Passed** or **Test Failed** message. A final summary line reports the total number of errors detected.

The clock period is 60 time units (toggle every 30).

### How to Run

The exact commands depend on the simulator. Generic flow:

```bash
# 1. Compile the Verilog source (which also contains the testbench)
<compiler> Comparator.v

# 2. Elaborate / run the simulation with the testbench as the top module
<simulator> tb_comparator
```

## Example Simulation Output

Successful run (no errors):

```
KERNEL: Test Passed | Time: 150  | A = 100100, B = 000001, S = 1 | EQ=0 GT=0 LT=1
KERNEL: Test Passed | Time: 300  | A = 100011, B = 001101, S = 1 | EQ=0 GT=0 LT=1
KERNEL: Test Passed | Time: 450  | A = 100101, B = 010010, S = 1 | EQ=0 GT=0 LT=1
...
KERNEL: Test Passed | Time: 1500 | A = 111101, B = 101101, S = 1 | EQ=0 GT=0 LT=1
KERNEL: SIMULATION COMPLETE: No errors detected
```

Run after introducing an intentional bug (mismatches detected):

```
KERNEL: Test Failed | Time: 150  | A = 100100, B = 000001, S = 1 | Structural -> EQ=0 GT=1 LT=1 | Behavioral -> EQ=0 GT=0 LT=1
...
KERNEL: SIMULATION COMPLETED: 10 errors detected
```

## Error Detection / Verification

To confirm that the testbench actually detects faults, an intentional error was injected into the structural design by replacing the final unsigned greater-than `or` gate with a `nor` gate:

```verilog
// Correct
or  #7 (GT_unsigned, Y_GT[5], Y_GT[4], Y_GT[3], Y_GT[2], Y_GT[1], Y_GT[0]);

// Faulty (intentional)
nor #7 (GT_unsigned, Y_GT[5], Y_GT[4], Y_GT[3], Y_GT[2], Y_GT[1], Y_GT[0]);
```

After this change, the testbench correctly flagged mismatches between the structural and behavioral outputs and reported a non-zero error count, confirming the verification flow works as intended.

## Course Information

- **Course:** Advanced Digital Design — ENCS3310
- **Semester:** First Semester 2024 / 2025
- **Institution:** Birzeit University — Faculty of Engineering and Technology, Electrical and Computer Engineering Department
- **Student:** Veronica Wakileh 
