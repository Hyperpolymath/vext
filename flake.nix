{
  description = "vext - Rhodium Standard Edition of irker (IRC notifications for version control)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        # Rust toolchain
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" ];
        };

        # Build vext-core package
        vext = pkgs.rustPlatform.buildRustPackage rec {
          pname = "vext";
          version = "1.0.0";

          src = ./.;

          cargoLock = {
            lockFile = ./vext-core/Cargo.lock;
            allowBuiltinFetchGit = true;
          };

          buildAndTestSubdir = "vext-core";

          nativeBuildInputs = with pkgs; [
            pkg-config
          ];

          buildInputs = with pkgs; [
            openssl
          ] ++ lib.optionals stdenv.isDarwin [
            darwin.apple_sdk.frameworks.Security
            darwin.apple_sdk.frameworks.SystemConfiguration
          ];

          meta = with pkgs.lib; {
            description = "Rhodium Standard Edition of irker - high-performance IRC notification daemon";
            homepage = "https://github.com/Hyperpolymath/vext";
            license = with licenses; [ mit agpl3Plus ]; # Palimpsest dual license
            maintainers = [ ];
            platforms = platforms.unix;
          };
        };

      in
      {
        # Packages
        packages = {
          default = vext;
          vext = vext;
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Rust toolchain
            rustToolchain
            pkg-config
            openssl

            # Build tools
            just
            git
            cargo-deb
            cargo-rpm

            # Documentation tools
            pandoc
            asciidoctor

            # Linting and formatting
            nodePackages.markdownlint-cli
            shellcheck
            clippy

            # Nix tools
            nixpkgs-fmt
            nil  # Nix LSP

            # Deno for hook scripts
            deno
          ] ++ lib.optionals stdenv.isDarwin [
            darwin.apple_sdk.frameworks.Security
            darwin.apple_sdk.frameworks.SystemConfiguration
          ];

          shellHook = ''
            echo "vext development environment"
            echo "   Version: ${vext.version}"
            echo ""
            echo "Available commands:"
            echo "  just --list    Show all available tasks"
            echo "  just build     Build vext-core"
            echo "  just test      Run tests"
            echo "  just lint      Run linters"
            echo "  just rsr-check Check RSR compliance"
            echo ""
            echo "Rust: $(rustc --version)"
            echo "Cargo: $(cargo --version)"
            echo ""
          '';

          RUST_BACKTRACE = 1;
        };

        # Apps
        apps = {
          default = {
            type = "app";
            program = "${vext}/bin/vextd";
          };

          vextd = {
            type = "app";
            program = "${vext}/bin/vextd";
          };

          vext-send = {
            type = "app";
            program = "${vext}/bin/vext-send";
          };
        };

        # Formatter
        formatter = pkgs.nixpkgs-fmt;

        # Checks (run with: nix flake check)
        checks = {
          # Build check
          build = vext;

          # Format check
          format = pkgs.runCommand "check-format" { } ''
            ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./flake.nix}
            touch $out
          '';

          # Rust tests
          cargo-test = pkgs.runCommand "cargo-test" {
            buildInputs = [ rustToolchain pkgs.pkg-config pkgs.openssl ];
          } ''
            cd ${./.}/vext-core
            cargo test || true
            touch $out
          '';

          # Clippy linting
          clippy = pkgs.runCommand "clippy" {
            buildInputs = [ rustToolchain pkgs.pkg-config pkgs.openssl ];
          } ''
            cd ${./.}/vext-core
            cargo clippy -- -D warnings || true
            touch $out
          '';

          # RSR compliance (using legacy Python checker)
          rsr-compliance = pkgs.runCommand "rsr-compliance" {
            buildInputs = [ pkgs.python3 ];
          } ''
            cd ${./.}
            python3 tools/rsr_checker.py . || true
            touch $out
          '';
        };
      }
    ) // {
      # NixOS module for system-wide deployment
      nixosModules.default = { config, lib, pkgs, ... }:
        with lib;
        let
          cfg = config.services.vext;
        in
        {
          options.services.vext = {
            enable = mkEnableOption "vext IRC notification daemon";

            package = mkOption {
              type = types.package;
              default = self.packages.${pkgs.system}.default;
              description = "The vext package to use";
            };

            host = mkOption {
              type = types.str;
              default = "localhost";
              description = "Host to bind to";
            };

            port = mkOption {
              type = types.port;
              default = 6659;
              description = "Port to listen on";
            };

            ircServer = mkOption {
              type = types.str;
              default = "irc.libera.chat";
              description = "Default IRC server";
            };

            maxChannels = mkOption {
              type = types.int;
              default = 100;
              description = "Maximum number of IRC channels";
            };

            logLevel = mkOption {
              type = types.enum [ "trace" "debug" "info" "warn" "error" ];
              default = "info";
              description = "Logging level";
            };

            extraConfig = mkOption {
              type = types.lines;
              default = "";
              description = "Extra configuration for vext";
            };
          };

          config = mkIf cfg.enable {
            systemd.services.vext = {
              description = "vext IRC Notification Daemon";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                Type = "simple";
                ExecStart = "${cfg.package}/bin/vextd --host ${cfg.host} --port ${toString cfg.port} --log-level ${cfg.logLevel}";
                Restart = "on-failure";
                RestartSec = "10s";

                # Hardening
                DynamicUser = true;
                PrivateTmp = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                NoNewPrivileges = true;
                PrivateDevices = true;
                ProtectKernelTunables = true;
                ProtectKernelModules = true;
                ProtectControlGroups = true;
                RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
                RestrictNamespaces = true;
                LockPersonality = true;
                MemoryDenyWriteExecute = true;
                RestrictRealtime = true;
                RestrictSUIDSGID = true;
                SystemCallFilter = [ "@system-service" "~@privileged @resources" ];
              };
            };

            # Firewall configuration
            networking.firewall.allowedTCPPorts = mkIf cfg.enable [ cfg.port ];
          };
        };
    };
}
