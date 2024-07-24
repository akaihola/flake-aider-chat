#!/usr/bin/env bash

errors=0

if [ -f Cargo.toml ]; then
  cargo test || errors=$?
fi

if find -regex ".*\.\(m?j\|t\)s$" -print | grep -q .; then
  eslint || errors=$?
fi

if [ -f pyproject.toml ]; then
  pytest || errors=$?
fi

find -name "*.nix" -exec nix-instantiate --parse {} \+ >/dev/null || errors=$?

exit $errors
