# cpp-container-template

## Getting Started

This repository is compatible with [cpp-container](https://github.com/ChicoState/cpp-container). If not already built on your machine, clone and build it.

Run the program in a POSIX shell from the repository root:

```bash
docker run -v "$(pwd)":/usr/src -it cpp-container
```

In PowerShell, use its path variable instead:

```powershell
docker run --rm -v "${PWD}:/usr/src" -it cpp-container
```

Run an interactive shell in the container:

```bash
docker run -v "$(pwd)":/usr/src -it cpp-container sh
```

## Square CLI

The container runs the test suite by default. The program draws a stylized square
whose default interior is seven characters wide and tall:

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

Compile and run it manually inside the container with:

```bash
g++ -std=c++17 -Wall -Wextra -Werror main.cpp -o squaredraw
./squaredraw --size 3
./squaredraw --help
```

`--size N` accepts ASCII decimal values from 3 through 40. Invalid arguments
write a diagnostic and usage hint to standard error and exit with status 2.

## Structure

* `.agents` - AI agent configurations and skills (in `/skills` subdirectory) for this project
* `.` - The root directory contains the C++ code for the application as well as necessary scripts
* `specs` - Specification documentation
* `tests` - Test code
