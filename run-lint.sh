#!/usr/bin/env bash

echo Command line: $0 $@

errors=0

if [ -f Cargo.toml ]; then
  rustfmt --edition=2021 "$@"
  cargo clippy || errors=$?
fi

if find -regex ".*\.\(m?j\|t\)s$" -print | grep -q .; then
  eslint "$@" || errors=$?
fi

if [ -f pyproject.toml ]; then
  true
fi

find -name "*.nix" -exec nix-instantiate --parse {} \+ >/dev/null || errors=$?

exit $errors
