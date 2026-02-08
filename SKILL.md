---
name: sql-format
description: Format and prettify SQL queries with consistent indentation and keyword casing.
version: 0.1.0
license: Apache-2.0
---

# sql-format

A SQL formatter that takes messy SQL queries and outputs them with consistent indentation, uppercase keywords, and aligned clauses.

## Purpose

SQL queries written inline or in quick scripts tend to be messy — everything on one line, inconsistent casing, no indentation. This skill formats SQL into a readable, consistent style.

## Instructions

Given a SQL query (via stdin, file argument, or string argument), the skill:

1. Uppercases SQL keywords (SELECT, FROM, WHERE, JOIN, ORDER BY, GROUP BY, etc.)
2. Places major clauses on their own lines
3. Indents column lists and conditions
4. Preserves string literals and quoted identifiers
5. Handles subqueries with proper nesting

## Inputs

- **stdin**: Pipe a SQL query or file contents
- **File argument**: `./scripts/run.sh query.sql`
- **String argument**: `./scripts/run.sh -q "select * from users where id = 1"`
- `--help`: Show usage information

## Outputs

Formatted SQL to stdout.

## Constraints

- Pure bash/awk implementation — no external SQL parser dependencies
- Handles standard SQL (SELECT, INSERT, UPDATE, DELETE, CREATE TABLE)
- Does not validate SQL syntax — only formats it
- Preserves content inside single-quoted strings
