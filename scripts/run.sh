#!/usr/bin/env bash
set -euo pipefail

# run.sh — Format SQL queries
# Usage: ./run.sh [FILE | -q "QUERY" | stdin]

QUERY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -q) QUERY="$2"; shift 2 ;;
    --help)
      echo "Usage: run.sh [OPTIONS] [FILE]"
      echo ""
      echo "Format SQL queries with consistent style."
      echo ""
      echo "Options:"
      echo "  -q QUERY    Format a SQL string directly"
      echo "  --help      Show this help"
      echo ""
      echo "Examples:"
      echo "  run.sh query.sql"
      echo "  run.sh -q \"select * from users where id = 1\""
      echo "  echo \"select 1\" | run.sh"
      exit 0
      ;;
    -*)
      echo "Error: unknown option: $1" >&2
      exit 2
      ;;
    *)
      if [[ -f "$1" ]]; then
        QUERY=$(cat "$1")
        shift
      else
        echo "Error: file not found: $1" >&2
        exit 2
      fi
      ;;
  esac
done

# Read from stdin if no query provided
if [[ -z "$QUERY" ]]; then
  if [[ -t 0 ]]; then
    echo "Error: no SQL input provided" >&2
    echo "Usage: run.sh [FILE | -q \"QUERY\" | stdin]" >&2
    exit 2
  fi
  QUERY=$(cat)
fi

if [[ -z "$QUERY" ]]; then
  echo "Error: empty SQL input" >&2
  exit 2
fi

# Format SQL using awk
echo "$QUERY" | awk '
BEGIN {
  indent = 0
  indent_str = "  "
  in_string = 0
  # Major clause keywords that get their own line
  split("SELECT,FROM,WHERE,JOIN,INNER JOIN,LEFT JOIN,RIGHT JOIN,FULL JOIN,CROSS JOIN,ON,ORDER BY,GROUP BY,HAVING,LIMIT,OFFSET,UNION,UNION ALL,EXCEPT,INTERSECT,INSERT INTO,VALUES,UPDATE,SET,DELETE FROM,CREATE TABLE,ALTER TABLE,DROP TABLE,AND,OR", clause_kw_arr, ",")
  for (i in clause_kw_arr) {
    clause_keywords[clause_kw_arr[i]] = 1
  }
  # All SQL keywords to uppercase
  split("SELECT,FROM,WHERE,JOIN,INNER,LEFT,RIGHT,FULL,CROSS,OUTER,ON,ORDER,BY,GROUP,HAVING,LIMIT,OFFSET,UNION,ALL,EXCEPT,INTERSECT,INSERT,INTO,VALUES,UPDATE,SET,DELETE,CREATE,TABLE,ALTER,DROP,AS,AND,OR,NOT,IN,IS,NULL,BETWEEN,LIKE,EXISTS,CASE,WHEN,THEN,ELSE,END,DISTINCT,TOP,ASC,DESC,PRIMARY,KEY,FOREIGN,REFERENCES,INDEX,CONSTRAINT,DEFAULT,CHECK,UNIQUE,AUTO_INCREMENT,CASCADE,IF,REPLACE,TRUNCATE,COUNT,SUM,AVG,MIN,MAX,COALESCE,CAST,CONVERT,CONCAT", all_kw_arr, ",")
  for (i in all_kw_arr) {
    all_keywords[all_kw_arr[i]] = 1
  }
}

{
  line = $0
  # Normalize whitespace
  gsub(/\t/, " ", line)
  gsub(/  +/, " ", line)
  gsub(/^ +| +$/, "", line)

  # Tokenize: split by spaces but respect quoted strings
  n = split(line, chars, "")
  result = ""
  token = ""
  in_sq = 0  # single quote
  in_dq = 0  # double quote

  for (i = 1; i <= n; i++) {
    c = chars[i]
    if (c == "\047" && !in_dq) {  # single quote
      in_sq = !in_sq
      token = token c
    } else if (c == "\"" && !in_sq) {
      in_dq = !in_dq
      token = token c
    } else if (c == " " && !in_sq && !in_dq) {
      if (token != "") {
        result = result process_token(token) " "
        token = ""
      }
    } else if ((c == "(" || c == ")") && !in_sq && !in_dq) {
      if (token != "") {
        result = result process_token(token) " "
        token = ""
      }
      result = result c " "
    } else if (c == "," && !in_sq && !in_dq) {
      if (token != "") {
        result = result process_token(token)
        token = ""
      }
      result = result ", "
    } else if (c == ";" && !in_sq && !in_dq) {
      if (token != "") {
        result = result process_token(token)
        token = ""
      }
      result = result ";\n"
    } else {
      token = token c
    }
  }
  if (token != "") {
    result = result process_token(token)
  }

  # Now format by placing clause keywords on new lines
  gsub(/ +/, " ", result)
  n2 = split(result, words, " ")

  output = ""
  i = 1
  while (i <= n2) {
    w = words[i]
    wu = toupper(w)

    # Check for two-word clause keywords
    two_word = ""
    if (i < n2) {
      two_word = wu " " toupper(words[i+1])
    }

    if (two_word in clause_keywords) {
      if (output != "") output = output "\n"
      output = output two_word
      i += 2
    } else if (wu in clause_keywords && !(wu == "ON" && output == "")) {
      if (output != "") output = output "\n"
      if (wu == "AND" || wu == "OR") {
        output = output "  " wu
      } else {
        output = output wu
      }
      i++
    } else {
      output = output " " w
      i++
    }
  }

  # Clean up spacing
  gsub(/\n +/, "\n", output)
  gsub(/^ +/, "", output)

  # Add indentation for continuation lines after clause keywords
  n3 = split(output, out_lines, "\n")
  for (j = 1; j <= n3; j++) {
    ol = out_lines[j]
    gsub(/^ +| +$/, "", ol)
    # Check if line starts with a clause keyword
    first_word = ol
    sub(/ .*/, "", first_word)
    if (toupper(first_word) in clause_keywords || index(ol, "  AND") == 1 || index(ol, "  OR") == 1) {
      printf "%s\n", ol
    } else {
      printf "  %s\n", ol
    }
  }
}

function process_token(t) {
  # Check if its a keyword to uppercase
  up = toupper(t)
  if (up in all_keywords) {
    return up
  }
  return t
}
'