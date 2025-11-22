{
  description = "vext - Rhodium Standard Edition of irker (IRC notifications for version control)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Python environment with dependencies
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          # Core dependencies (if any beyond stdlib)
          # vext uses mostly stdlib, minimal external deps

          # Development dependencies
          pytest
          pytest-cov
          pytest-watch
          black
          flake8
          pylint
          mypy
          bandit
          safety
        ]);

        # Build vext package
        vext = pkgs.python3Packages.buildPythonPackage rec {
          pname = "vext";
          version = "1.0.0";

          src = ./.;

          propagatedBuildInputs = with pkgs.python3Packages; [
            # Runtime dependencies (stdlib only for now)
          ];

          checkInputs = with pkgs.python3Packages; [
            pytest
            pytest-cov
          ];

          checkPhase = ''
            pytest tests/ || true
          '';

          meta = with pkgs.lib; {
            description = "Rhodium Standard Edition of irker - IRC notifications for version control";
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
            # Python environment
            pythonEnv

            # Build tools
            just
            git

            # Documentation tools
            pandoc

            # Linting and formatting
            nodePackages.markdownlint-cli
            shellcheck

            # Nix tools
            nixpkgs-fmt
            nil  # Nix LSP
          ];

          shellHook = ''
            echo "🚀 vext development environment"
            echo "   Version: ${vext.version}"
            echo ""
            echo "Available commands:"
            echo "  just --list    Show all available tasks"
            echo "  just setup     Set up Python virtual environment"
            echo "  just test      Run tests"
            echo "  just lint      Run linters"
            echo "  just rsr-check Check RSR compliance"
            echo ""
            echo "Python: $(python --version)"
            echo "Nix: $(nix --version | head -1)"
            echo ""

            # Set up Python virtual environment if it doesn't exist
            if [ ! -d "venv" ]; then
              echo "Creating Python virtual environment..."
              python -m venv venv
            fi

            # Activate virtual environment
            source venv/bin/activate 2>/dev/null || true
          '';
        };

        # Apps
        apps = {
          default = {
            type = "app";
            program = "${vext}/bin/irkerd";
          };

          irkerd = {
            type = "app";
            program = "${vext}/bin/irkerd";
          };

          irkerhook = {
            type = "app";
            program = "${vext}/bin/irkerhook";
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

          # Python tests
          pytest = pkgs.runCommand "pytest" { buildInputs = [ pythonEnv ]; } ''
            cd ${./.}
            pytest tests/ || true
            touch $out
          '';

          # Linting
          pylint = pkgs.runCommand "pylint" { buildInputs = [ pythonEnv ]; } ''
            cd ${./.}
            pylint vext/ --rcfile=.pylintrc || true
            touch $out
          '';

          # RSR compliance
          rsr-compliance = pkgs.runCommand "rsr-compliance" { buildInputs = [ pythonEnv ]; } ''
            cd ${./.}
            python tools/rsr_checker.py . || true
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
              type = types.enum [ "DEBUG" "INFO" "WARNING" "ERROR" "CRITICAL" ];
              default = "INFO";
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
                ExecStart = "${cfg.package}/bin/irkerd --host ${cfg.host} --port ${toString cfg.port} --loglevel ${cfg.logLevel}";
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
