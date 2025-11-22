# justfile for vext
# https://github.com/casey/just
# SPDX-License-Identifier: MIT OR AGPL-3.0-or-later

# Default recipe (show help)
default:
    @just --list

# ══════════════════════════════════════════════════════════════════════════════
# Development
# ══════════════════════════════════════════════════════════════════════════════

# Set up development environment
setup:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔧 Setting up vext development environment..."

    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        echo "✓ Created virtual environment"
    fi

    # Activate and install dependencies
    source venv/bin/activate
    pip install --upgrade pip

    if [ -f "requirements-dev.txt" ]; then
        pip install -r requirements-dev.txt
        echo "✓ Installed development dependencies"
    fi

    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
        echo "✓ Installed project dependencies"
    fi

    # Install in editable mode
    if [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
        pip install -e .
        echo "✓ Installed vext in editable mode"
    fi

    echo ""
    echo "✅ Setup complete!"
    echo "   Activate environment: source venv/bin/activate"

# Install dependencies
install:
    pip install -r requirements.txt

# Install development dependencies
install-dev:
    pip install -r requirements-dev.txt
    pip install -e .

# ══════════════════════════════════════════════════════════════════════════════
# Testing
# ══════════════════════════════════════════════════════════════════════════════

# Run all tests
test:
    pytest tests/ -v

# Run tests with coverage
test-coverage:
    pytest tests/ --cov=vext --cov-report=html --cov-report=term

# Run tests in watch mode
test-watch:
    pytest-watch tests/

# Run integration tests
test-integration:
    pytest tests/integration/ -v --integration

# Run unit tests only
test-unit:
    pytest tests/unit/ -v

# Run specific test file
test-file FILE:
    pytest {{FILE}} -v

# ══════════════════════════════════════════════════════════════════════════════
# Code Quality
# ══════════════════════════════════════════════════════════════════════════════

# Run all linters and formatters
lint:
    @echo "🔍 Running linters..."
    just lint-black
    just lint-flake8
    just lint-pylint
    just lint-mypy
    @echo "✅ All linters passed!"

# Check code formatting with black
lint-black:
    black --check --diff .

# Run flake8 linter
lint-flake8:
    flake8 vext/ tests/

# Run pylint linter
lint-pylint:
    pylint vext/ tests/ --rcfile=.pylintrc || true

# Run mypy type checker
lint-mypy:
    mypy vext/ --ignore-missing-imports

# Format code with black
format:
    black .

# Run security checks
security:
    @echo "🔒 Running security checks..."
    bandit -r vext/ -f json -o bandit-report.json || true
    bandit -r vext/
    safety check --json || true

# ══════════════════════════════════════════════════════════════════════════════
# Documentation
# ══════════════════════════════════════════════════════════════════════════════

# Build documentation
docs-build:
    @echo "📚 Building documentation..."
    cd docs && make html

# Serve documentation locally
docs-serve:
    @echo "🌐 Serving documentation at http://localhost:8000"
    cd docs/_build/html && python -m http.server 8000

# Check documentation links
docs-check:
    @echo "🔗 Checking documentation links..."
    find . -name "*.md" -exec markdown-link-check {} \;

# ══════════════════════════════════════════════════════════════════════════════
# RSR Compliance
# ══════════════════════════════════════════════════════════════════════════════

# Check RSR compliance
rsr-check:
    @echo "📊 Checking RSR compliance..."
    python3 tools/rsr_checker.py .

# Generate RSR compliance JSON report
rsr-check-json:
    @echo "📄 Generating RSR compliance JSON report..."
    python3 tools/rsr_checker.py . --json --json-output rsr_compliance.json
    @cat rsr_compliance.json

# Generate RSR compliance badge
rsr-badge:
    @echo "🏅 Generating RSR compliance badge..."
    python3 tools/rsr_checker.py . --badge

# Full RSR compliance report
rsr-report:
    @echo "📋 Generating comprehensive RSR compliance report..."
    python3 tools/rsr_checker.py . --json --badge

# ══════════════════════════════════════════════════════════════════════════════
# Building
# ══════════════════════════════════════════════════════════════════════════════

# Build distribution packages
build:
    @echo "📦 Building distribution packages..."
    python -m build

# Build wheel only
build-wheel:
    @echo "🎡 Building wheel..."
    python -m build --wheel

# Build source distribution only
build-sdist:
    @echo "📦 Building source distribution..."
    python -m build --sdist

# Clean build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    rm -rf build/ dist/ *.egg-info
    rm -rf .pytest_cache/ .coverage htmlcov/
    rm -rf **/__pycache__/
    rm -f rsr_compliance.json bandit-report.json
    @echo "✅ Cleaned!"

# ══════════════════════════════════════════════════════════════════════════════
# Running
# ══════════════════════════════════════════════════════════════════════════════

# Run irkerd daemon in foreground
run:
    python -m vext.irkerd

# Run irkerd daemon with debug logging
run-debug:
    python -m vext.irkerd --debug

# Run irkerd daemon in background
run-daemon:
    python -m vext.irkerd --daemon

# Stop running daemon
stop:
    pkill -f "python.*irkerd" || echo "No daemon running"

# ══════════════════════════════════════════════════════════════════════════════
# Docker
# ══════════════════════════════════════════════════════════════════════════════

# Build Docker image
docker-build:
    docker build -t vext:latest .

# Run Docker container
docker-run:
    docker run -d --name vext -p 6659:6659 vext:latest

# Stop Docker container
docker-stop:
    docker stop vext || true
    docker rm vext || true

# Docker logs
docker-logs:
    docker logs -f vext

# ══════════════════════════════════════════════════════════════════════════════
# Release
# ══════════════════════════════════════════════════════════════════════════════

# Prepare a new release
release VERSION:
    @echo "🚀 Preparing release {{VERSION}}..."
    @echo "1. Updating version numbers..."
    sed -i 's/^version = .*/version = "{{VERSION}}"/' pyproject.toml
    @echo "2. Updating CHANGELOG.md..."
    @echo "   (Manual step: Update CHANGELOG.md with release notes)"
    @echo "3. Creating git tag..."
    git add pyproject.toml CHANGELOG.md
    git commit -m "chore: bump version to {{VERSION}}"
    git tag -a "v{{VERSION}}" -m "Release v{{VERSION}}"
    @echo "✅ Release prepared!"
    @echo "   Review changes, then run: git push && git push --tags"

# Publish to PyPI (requires credentials)
publish:
    @echo "📦 Publishing to PyPI..."
    @echo "⚠️  This will upload to PyPI. Press Ctrl+C to cancel."
    @read -p "Continue? (y/N) " -n 1 -r
    @echo
    @if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
        python -m twine upload dist/*; \
    fi

# ══════════════════════════════════════════════════════════════════════════════
# Maintenance
# ══════════════════════════════════════════════════════════════════════════════

# Update dependencies
update-deps:
    @echo "🔄 Updating dependencies..."
    pip list --outdated
    pip install --upgrade pip setuptools wheel

# Check for security vulnerabilities
check-vulnerabilities:
    safety check
    pip-audit

# Generate requirements.txt from pyproject.toml
generate-requirements:
    pip-compile pyproject.toml -o requirements.txt
    pip-compile --extra dev pyproject.toml -o requirements-dev.txt

# ══════════════════════════════════════════════════════════════════════════════
# Validation
# ══════════════════════════════════════════════════════════════════════════════

# Run all validation checks (CI equivalent)
validate: lint test security rsr-check
    @echo ""
    @echo "✅ All validation checks passed!"

# Pre-commit checks
pre-commit: format lint test-unit
    @echo "✅ Pre-commit checks passed!"

# Full CI check
ci: clean install-dev lint test test-coverage security rsr-check
    @echo "✅ Full CI validation passed!"

# ══════════════════════════════════════════════════════════════════════════════
# Utilities
# ══════════════════════════════════════════════════════════════════════════════

# Show project information
info:
    @echo "Project: vext"
    @echo "Description: Rhodium Standard Edition of irker"
    @echo "License: MIT OR AGPL-3.0-or-later"
    @echo "Repository: https://github.com/Hyperpolymath/vext"
    @echo ""
    @echo "Python version:"
    @python --version
    @echo ""
    @echo "Dependencies:"
    @pip list | grep -E "(pytest|black|flake8|pylint|mypy|bandit|safety)"

# Count lines of code
loc:
    @echo "📊 Lines of code:"
    @find vext -name "*.py" | xargs wc -l | tail -1
    @echo "📊 Lines of tests:"
    @find tests -name "*.py" | xargs wc -l | tail -1

# Open documentation in browser
docs-open:
    xdg-open docs/README.md || open docs/README.md || echo "Open docs/README.md manually"

# ══════════════════════════════════════════════════════════════════════════════
# Nix Integration
# ══════════════════════════════════════════════════════════════════════════════

# Build with Nix
nix-build:
    nix build

# Run with Nix
nix-run:
    nix run

# Enter Nix development shell
nix-shell:
    nix develop

# Update Nix flake lock
nix-update:
    nix flake update
