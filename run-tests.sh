#!/usr/bin/env bash

errors=0

if [ -f Cargo.toml ]; then
  cargo test || errors=$?
fi

if find -regex ".*\.\(m?j\|t\)s$" -print | grep -q .; then
  eslint || errors=$?
fi

if [ -f pyproject.toml ]; then
  if command -v pytest &> /dev/null; then
    pytest || errors=$?
  fi
fi

find -name "*.nix" -exec nix-instantiate --parse {} \+ >/dev/null || errors=$?

exit $errors
