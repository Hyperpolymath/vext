# Tests

SPDX-License-Identifier: MIT OR AGPL-3.0-or-later

## Test Structure

- **vext-core/src/**: Rust unit tests (inline with `#[cfg(test)]` modules)
- **vext-tools/**: Deno tests (using `deno test`)
- **tests/**: Integration tests

## Running Tests

### Rust Tests
```bash
cd vext-core && cargo test
```

### Deno Tests
```bash
cd vext-tools && deno test
```

### All Tests
```bash
just test
```
