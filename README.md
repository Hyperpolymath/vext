# vext - Rhodium Standard Edition

SPDX-License-Identifier: MIT OR AGPL-3.0-or-later

[![Rust 1.70+](https://img.shields.io/badge/rust-1.70+-orange.svg)](https://rustup.rs)
[![Deno 1.40+](https://img.shields.io/badge/deno-1.40+-blue.svg)](https://deno.land)
[![License](https://img.shields.io/badge/license-MIT%20OR%20AGPL--3.0--or--later-green.svg)](LICENSE.txt)
[![RSR Compliance](https://img.shields.io/badge/RSR-Silver-silver.svg)](RSR_COMPLIANCE.md)

> High-performance IRC notification daemon for version control systems.
>
> Full documentation: [README.adoc](README.adoc)

## Overview

**vext** is a modernized rewrite of [irker](http://www.catb.org/~esr/irker/) by Eric S. Raymond. It provides real-time commit notifications from Git repositories to IRC channels, with connection pooling to eliminate join/leave spam.

Built with:
- **Rust** - High-performance async daemon with memory safety
- **Deno/TypeScript** - Modern hook scripts and CLI tools

## Features

- **Async I/O**: Built on Tokio for efficient handling of thousands of connections
- **Connection Pooling**: Maintains persistent IRC connections, eliminating join/leave spam
- **TLS Support**: Secure connections to IRC servers (enabled by default)
- **Rate Limiting**: Built-in flood protection with token bucket algorithm
- **Multi-Target**: Send notifications to multiple channels/servers simultaneously
- **JSON Protocol**: Simple, language-agnostic notification format
- **Color Support**: Optional mIRC color codes for enhanced visibility

## Installation

### From Source (Recommended)

```bash
# Prerequisites: Rust 1.70+, Deno 1.40+
git clone https://github.com/Hyperpolymath/vext.git
cd vext

# Build everything
just build

# Or build components separately
cargo build --release           # Rust daemon
cd vext-tools && deno check src/**/*.ts  # Deno tools
```

### Nix/NixOS

```bash
# Development shell
nix develop

# Build package
nix build

# Install system-wide (NixOS)
services.vext.enable = true;
```

### Guix

```bash
guix shell -D -f guix.scm
```

## Usage

### Running the Daemon

```bash
# Start daemon (listens on 127.0.0.1:6659 by default)
./target/release/vextd

# Start with custom settings
./target/release/vextd --listen 0.0.0.0:6659 --default-server irc.libera.chat

# Debug mode
./target/release/vextd -vv
```

### Installing Git Hook

```bash
cd /path/to/your/repo
deno run --allow-read --allow-write \
  https://raw.githubusercontent.com/Hyperpolymath/vext/main/vext-tools/src/hooks/install.ts

# Configure the hook
export VEXT_TARGETS="ircs://irc.libera.chat/your-channel"
export VEXT_PROJECT="your-project"
```

### Sending Notifications

```bash
# Using the CLI tool
./target/release/vext-send \
  --target "ircs://irc.libera.chat/#channel" \
  --message "Build completed successfully"

# Using netcat
echo '{"to":"ircs://irc.libera.chat/#channel","privmsg":"Hello!"}' | nc localhost 6659
```

## Documentation

- [Installation Guide](INSTALLATION_GUIDE.md)
- [Usage Guide](USAGE_GUIDE.md)
- [Features](FEATURES.md)
- [Technology Stack](TECHNOLOGY_STACK.md)
- [Project Overview](PROJECT_OVERVIEW.md)
- [RSR Compliance](RSR_COMPLIANCE.md)

## License

Dual-licensed under MIT OR AGPL-3.0-or-later (Palimpsest License).
See [LICENSE.txt](LICENSE.txt) for details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## Security

See [SECURITY.md](SECURITY.md) for security policy and vulnerability reporting.
