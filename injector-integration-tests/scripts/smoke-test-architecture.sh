#!/usr/bin/env bash

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"/../..

arch="${ARCH:-}"
case "$arch" in
  ppc64le)
    expected_machine="PowerPC64"
    expected_uname="ppc64le"
    ;;
  s390x)
    expected_machine="IBM S/390"
    expected_uname="s390x"
    ;;
  *)
    echo "ARCH must be one of: ppc64le, s390x." >&2
    exit 1
    ;;
esac

binary="dist/libotelinject_${arch}.so"
if [[ ! -f "$binary" ]]; then
  echo "Injector binary not found: $binary" >&2
  exit 1
fi

for executable in docker readelf; do
  if ! command -v "$executable" >/dev/null 2>&1; then
    echo "Required executable is not available: $executable" >&2
    exit 1
  fi
done

echo "Validating ELF header for $binary"
elf_header=$(readelf -h "$binary")
grep -Fq "Class:                             ELF64" <<<"$elf_header"
grep -Fq "Type:                              DYN (Shared object file)" <<<"$elf_header"
grep -Fq "Machine:                           $expected_machine" <<<"$elf_header"
if [[ "$arch" = "ppc64le" ]]; then
  grep -Fq "Data:                              2's complement, little endian" <<<"$elf_header"
fi

run_preload_smoke_test() {
  local libc_flavor=$1
  local image=$2

  echo "Testing $arch on $libc_flavor with $image"
  local actual_uname
  actual_uname=$(docker run --rm --platform "linux/$arch" "$image" uname -m)
  if [[ "$actual_uname" != "$expected_uname" ]]; then
    echo "Expected uname -m to report $expected_uname, got $actual_uname." >&2
    return 1
  fi

  local output
  output=$(
    docker run --rm \
      --platform "linux/$arch" \
      --volume "$PWD/$binary:/opt/opentelemetry/libotelinject.so:ro" \
      --env LD_PRELOAD=/opt/opentelemetry/libotelinject.so \
      --env OTEL_INJECTOR_SERVICE_NAME=architecture-smoke-test \
      "$image" \
      /usr/bin/env
  )

  if ! grep -Fxq "OTEL_RESOURCE_ATTRIBUTES=service.name=architecture-smoke-test" <<<"$output"; then
    echo "The injector loaded, but did not inject the expected resource attribute on $arch/$libc_flavor." >&2
    echo "$output" >&2
    return 1
  fi
}

run_preload_smoke_test glibc "debian:bookworm-20260824-slim@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171"
run_preload_smoke_test musl "alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b"

echo "Architecture smoke tests passed for $arch."
