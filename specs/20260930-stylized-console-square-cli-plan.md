# Feature: Stylized Console Square CLI

## Feature Description
Create a small, dependency-free C++ command-line program that renders a decorative square in a terminal. By default, it prints a fixed, readable ASCII square with a shaded diagonal and a centered `@` emblem. The program also supports a bounded square size and conventional help output so it is useful as a CLI example rather than a hard-coded printout.

## User Story
As a terminal user
I want to run a simple executable that draws a stylized square
So that I can see a consistent piece of console art and adjust its size when needed.

## Problem Statement
The repository currently builds an executable whose `main` exits without output. There is no defined command-line interface, rendered-art contract, or automated way to verify the output.

## Solution Statement
Implement the renderer in `main.cpp` using only the C++ standard library. Parse a deliberately narrow set of options, validate input before rendering, and generate the square row by row instead of storing many hard-coded lines. Keep output ASCII-only to avoid locale, font, and Windows-console Unicode differences. Add a shell test that compiles the program in an isolated temporary directory and asserts its observable behavior.

## Relevant Files
Use these files to implement the feature:

- `main.cpp` — replace the empty program with argument parsing, validation, help text, and square rendering.
- `test_runner.sh` — update the existing developer entry point to compile with warnings and run the test suite rather than leaving an `app` binary in the repository.
- `README.md` — document prerequisites, build/run commands, CLI options, exit behavior, and a sample rendering.
- `tests/README.md` — retain as the folder purpose statement; no behavior belongs here.

### New Files

- `tests/test_stylized_square_cli.sh` — executable black-box regression test for default output, sizing, help, and invalid input.

## Implementation Plan
### Phase 1: Foundation
Define a stable, small command-line contract and testable output format. Use `g++` and the standard library only; no package manager or external graphics/terminal dependency is needed.

### Phase 2: Core Implementation
Add option parsing for `--size <N>`, `--help`, and `-h`. `N` always means the number of *interior* cells per side (the complete visible line width and height are therefore `N + 2`); the default is `7`, and accepted values are unsigned decimal digits representing integers from `3` through `40`. Render each row from its coordinates, producing a square with `+`, `-`, and `|` borders; use `#` along the upper-left to lower-right diagonal to suggest shading, leave the remaining interior as spaces, and place the `@` emblem at the middle cell. End every rendered row with one newline and emit no other stdout text. CLI usage errors use exit status `2`; successful help and rendering use `0`.

### Phase 3: Integration
Make the existing test runner invoke the new shell test, which compiles the program with a named C++ standard and useful warnings in an isolated temporary directory. Document the executable’s interface and expected visual result in the README so users can run it outside a container as well as inside the documented container workflow.

## Step by Step Tasks
IMPORTANT: Execute every step in order, top to bottom.

### 1. Define the externally visible CLI behavior

- Treat no arguments as `--size 7`.
- Support `--size <N>` exactly once, where `N` is a base-10 integer in the inclusive range `3..40`.
- Support `-h` and `--help` only as the sole argument. Each prints usage text to stdout and exits with status `0`; help must not render the square. A help option combined with any other argument is a usage error.
- For a missing size value, a value containing anything other than ASCII decimal digits, an out-of-range value, an unknown option, repeated `--size`, or a positional argument, print a concise diagnostic followed by the same usage text to stderr and exit `2`.
- Reject positional arguments so a typo cannot silently change output.

### 2. Add output-focused regression coverage

- Create `tests/test_stylized_square_cli.sh` using POSIX shell behavior and `set -eu`.
- Compile `main.cpp` into a temporary directory owned by the test; use a trap to remove only that temporary directory when the test exits.
- Assert the complete default output byte-for-byte, including its final newline:

  ```text
  +-------+
  |#      |
  | #     |
  |  #    |
  |   @   |
  |    #  |
  |     # |
  |      #|
  +-------+
  ```

  This verifies exactly nine lines, all borders, every diagonal `#` except the deliberately overwritten centered emblem, and no extra stdout text.
- Assert that `--size 3` succeeds and produces five total lines with an appropriately scaled border and emblem.
- Assert that `--help` and `-h` succeed, include both supported options in usage text, and do not contain the rendered border.
- Assert that invalid inputs such as `--size 2`, `--size nope`, `--size +3`, `--size`, `--unknown`, duplicate `--size`, a positional argument, and `--help --size 3` exit `2`, write both a diagnostic and usage to stderr, and leave stdout empty.

### 3. Implement parsing and validation in `main.cpp`

- Include only standard headers needed for strings, streams, numeric conversion, and program control.
- Parse arguments left to right, keeping a single optional size value and a help flag; avoid global mutable state.
- Validate that the size token is nonempty ASCII decimal digits before numeric conversion; use a strict standard-library conversion and enforce `3..40` before calling the renderer. This explicitly rejects signed, decimal, whitespace-padded, and trailing-character forms.
- Centralize usage text and error reporting so every error is consistent and writes to stderr.
- Return `0` on successful rendering or help, and `2` for every CLI usage error.

### 4. Implement deterministic square rendering in `main.cpp`

- Render the top and bottom as `+` followed by `N` `-` characters and a closing `+`.
- Render exactly `N` interior rows framed by `|` characters.
- Initialize each interior cell to a space; set the cell where row equals column to `#` to create the diagonal shade.
- On the middle row, overwrite the middle cell (index `N / 2`) with `@` after diagonal placement. This makes the emblem exactly centered for both odd and even sizes.
- Stream lines directly to stdout and return a status that allows tests to detect output errors.

### 5. Integrate developer commands and documentation

- Revise `test_runner.sh` to delegate to `tests/test_stylized_square_cli.sh` and ensure failures propagate; compilation remains inside the test's temporary directory, so no generated executable is left in the repository root.
- Update `README.md` with the program purpose, `g++` build example, default invocation, `--size` example, help command, option/exit-code behavior, and the exact default-output sample from the regression test.
- Keep the repository’s existing container instructions, while making the new usage instructions work in its interactive shell.

### 6. Run the validation commands

- Execute every command in the Validation Commands section and fix any failures before considering the feature complete.

## Testing Strategy
### Unit Tests

- Use the shell test as black-box unit coverage for CLI parsing and rendering because the repository currently has no C++ test framework.
- Compare exact default output or its individual rows to verify deterministic art, including newline count.
- Exercise both aliases of the help option and all supported success paths.

### Edge Cases

- Minimum supported size (`3`) retains a valid border and centered emblem.
- Maximum supported size (`40`) renders the expected number of rows and columns without truncation.
- A nonnumeric size, signed/decimal input, trailing characters, whitespace-padded input, an empty/missing value, zero, and values outside the bounds all fail safely with exit `2`.
- A `--help` or `-h` combined with any other argument fails with exit `2`, writes no art, and includes the usage text on stderr.
- Repeated options and unexpected positional arguments do not produce art or succeed accidentally.

## Acceptance Criteria

- Building `main.cpp` with the documented `g++` command succeeds without external dependencies.
- Running the executable with no arguments exits `0` and prints the defined seven-cell interior stylized square, with exactly one trailing newline per output line.
- `--size 3` through `--size 40` exit `0` and render a square with `N + 2` lines, each `N + 2` visible ASCII characters wide before its newline.
- The top/bottom borders, side borders, diagonal shading, and `@` emblem appear in every valid rendering according to the coordinate rules above.
- `-h` and `--help` exit `0` and show usage without rendering art.
- Invalid invocations exit `2`, write a diagnostic and usage text to stderr, and do not render art to stdout.
- The automated shell test and `test_runner.sh` pass.
- README usage and sample output match the implemented behavior.

## Validation Commands
Execute every command to validate the feature works correctly with zero regressions.

```bash
g++ -std=c++17 -Wall -Wextra -Wpedantic main.cpp -o /tmp/squaredraw-app
/tmp/squaredraw-app
/tmp/squaredraw-app --size 3
/tmp/squaredraw-app --size 40
/tmp/squaredraw-app --help
test "$(/tmp/squaredraw-app --size 2 >/dev/null 2>&1; echo $?)" -eq 2
bash tests/test_stylized_square_cli.sh
bash test_runner.sh
```

## Notes

- The visual and CLI details above are explicit design assumptions made because the request did not prescribe a particular art style or options. A future iteration could add `--border` or `--fill` customization, but this first version should stay focused and dependency-free.
- ASCII is intentionally preferred over box-drawing Unicode for consistent output in the repository’s documented container, CI shells, and Windows terminals.
- The repository has no `AGENTS.md` and no existing C++ test framework; the shell test is the smallest fitting test approach.
