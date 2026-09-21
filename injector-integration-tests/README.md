Injector Integration Tests
==========================

This directory contains integration tests for the injector binary.
The full runtime integration suite runs natively on amd64 and arm64. Release binaries for ppc64le and s390x are
cross-built in CI and validated with a focused preload smoke test on both glibc and musl: the test verifies the ELF
architecture, loads the injector through `LD_PRELOAD`, and checks that it injects an OpenTelemetry resource attribute.
This keeps the architecture validation independent from the availability of language-runtime test images on those
platforms.
Note that the Zig source code in `src` also contains Zig unit tests. The integration tests for the DEB and RPM system
packages live in [open-telemetry/opentelemetry-packaging](https://github.com/open-telemetry/opentelemetry-packaging).

The available test cases for the injector integration tests are listed in the files
`injector-integration-tests/tests/*.tests`.

Usage
-----

* `scripts/test-all.sh` to run the full integration suite on amd64 and arm64.
* `ARCHITECTURES=arm64,amd64 scripts/test-all.sh` to run tests for a subset of those native-test CPU architectures.
  Can be combined with `LIBC_FLAVORS` and other flags.
* `ARCH=ppc64le make injector-architecture-smoke-test` (or `ARCH=s390x`) to run the cross-architecture preload
  smoke test. Docker binfmt/QEMU support for the selected architecture must already be installed.
* `LIBC_FLAVORS=glibc,musl scripts/test-all.sh` to run tests for a subset of libc flavors.
  Can be combined with `ARCHITECTURES` and other flags.
* `TEST_SETS=default,nodejs,jvm,sdk-does-not-exist,sdk-cannot-be-accessed` to only run a subset of test sets. The test
   set names are the different `injector-integration-tests/tests/*.tests` files. Can be combined with `ARCHITECTURES`,
  `LIBC_FLAVORS` etc.
* `TEST_CASES="injects NODE_OPTIONS if it is not present" scripts/test-all.sh` to only run test cases whose names
  _exactly match_ one of the provided strings.
  The test cases are listed in the different test sets, i.e. the `injector-integration-tests/tests/*.tests` files.
  Can be combined with `ARCHITECTURES`, `LIBC_FLAVORS` etc., cannot be combined with `TEST_CASES_CONTAINING`.
* `TEST_CASES_CONTAINING=OTEL_RESOURCE_ATTRIBUTES,OTEL_RESOURCE_ATTRIBUTES scripts/test-all.sh` to only run tests cases
  whose names _contain_ one of the provided strings as a substring.
  The test cases are listed in the different `scripts/*.tests` files.
  Can be combined with `ARCHITECTURES`, `LIBC_FLAVORS` etc., cannot be combined with `TEST_CASES`.
* Set `VERBOSE=true` to set `OTEL_INJECTOR_LOG_LEVEL=debug` when running test cases and to always include the output
  from running the test case. Otherwise, the default log level (`error`) is used, and output is only printed to stdout
  when a test case fails.
* Set `INTERACTIVE=true` to get a shell into the container under test, instead of running a test. Best used when working
  on a test for one specific app/test set, you would usually want to combine this with something like
  `ARCHITECTURES=arm64 LIBC_FLAVORS=glibc TEST_SETS=dotnet INTERACTIVE=true scripts/test-all.sh` to narrow down the
  scope to one container under test.
