# WebHook

## Description

language: [Raku](https://www.raku.org)

web framework: [Cro](https://cro.services)

ORM: [Red](https://fco.github.io/Red/)

## Requirements

Docker (last version)

## Test

run:

```bash
./test
```

the test files are on dir [t](https://github.com/FCO/WebHook/tree/main/t)

## Run

```bash
./build.sh
./webhook generate-tables
```

access service on port 9876

## Retry poist with error

```bash
./webhook retry
```

## Script

use `./webhook` to access other commands
