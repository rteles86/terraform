#!/bin/sh
# Recebe JSON via stdin com {"role_name":"..."}
read -r input
role_name=$(printf '%s' "$input" | sed -E 's/.*"role_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
if [ -z "$role_name" ]; then
  echo '{"exists":"false"}'
  exit 0
fi
if aws iam get-role --role-name "$role_name" >/dev/null 2>&1; then
  echo '{"exists":"true"}'
else
  echo '{"exists":"false"}'
fi
