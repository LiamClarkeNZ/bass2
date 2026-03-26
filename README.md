# bass2

Bass2 makes it easy to use utilities written for Bash in [fish shell](https://fishshell.com/).

A maintained fork of [edc/bass](https://github.com/edc/bass) with:
- **Bash function capture** — functions defined in sourced scripts become callable from fish
- Bug fixes for virtualenv compatibility, alias parsing, newline handling
- Python 3.10+ (dropped Python 2 support)
- pytest test suite and GitHub Actions CI

## Installation

### With [fisher](https://github.com/jorgebucaran/fisher)

```fish
fisher install LiamClarkeNZ/bass2
```

### With [fundle](https://github.com/danhper/fundle)

Add to your `config.fish`:

```fish
fundle plugin 'LiamClarkeNZ/bass2'
```

Then run:

```fish
fundle install
```

### Manual

```bash
make install
```

## Usage

Use `bass` to run bash commands and capture their environment changes:

```fish
# Source a bash script
bass source ~/.nvm/nvm.sh

# Export variables
bass export X=3

# Run bash functions after sourcing (new in bass2!)
bass source ~/.sdkman/bin/sdkman-init.sh
sdk install java 17  # the sdk function is now available in fish

# Use nvm
bass source ~/.nvm/nvm.sh ';' nvm use 18
```

### Debug mode

Use `-d` to see the fish commands that bass generates:

```fish
bass -d export X=3
```

## Requirements

- Python 3.10+
- fish shell
- bash (4+ recommended — env vars and aliases work on bash 3.2, but function capture requires bash 4+. macOS ships bash 3.2; install a newer version with `brew install bash`)

## Development

```bash
# Run all tests
make test

# Run only Python tests
make test-python

# Run only fish integration tests
make test-fish
```

## License

MIT
