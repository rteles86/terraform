#!/bin/sh
# Recebe JSON via stdin com {"function_name":"..."}
read -r input
function_name=$(printf '%s' "$input" | sed -E 's/.*"function_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
if [ -z "$function_name" ]; then
  echo '{"exists":"false"}'
  exit 0
fi
if aws lambda get-function --function-name "$function_name" >/dev/null 2>&1; then
  echo '{"exists":"true"}'
else
  echo '{"exists":"false"}'
fi
