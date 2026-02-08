# sql-format

Format and prettify SQL queries with consistent indentation and keyword casing.

## Quick Start

```bash
./scripts/run.sh -q "select id, name from users where active = 1 order by name"
```

## Prerequisites

- Bash 4+
- awk (standard on all Unix systems)

## Usage

```bash
# Format a SQL file
./scripts/run.sh query.sql

# Format inline SQL
./scripts/run.sh -q "select * from users where id = 1"

# Pipe from stdin
echo "select * from users" | ./scripts/run.sh
```
