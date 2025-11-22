# Contributing to vext

**SPDX-License-Identifier: MIT OR AGPL-3.0-or-later**

Thank you for considering contributing to vext! This document provides guidelines for contributing to the project.

## 🎯 Quick Start

1. **Fork** the repository
2. **Clone** your fork: `git clone https://github.com/yourusername/vext.git`
3. **Create** a feature branch: `git checkout -b feature/amazing-feature`
4. **Make** your changes
5. **Test** your changes: `just test`
6. **Commit** with clear messages: `git commit -m "feat: add amazing feature"`
7. **Push** to your fork: `git push origin feature/amazing-feature`
8. **Open** a Pull Request

## 📜 Code of Conduct

This project adheres to the [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to conduct@vext.dev.

## 🌍 Ways to Contribute

We welcome many types of contributions:

### 💻 Code Contributions
- Bug fixes
- New features
- Performance improvements
- Code refactoring
- Test coverage improvements

### 📚 Documentation
- README improvements
- Tutorial creation
- API documentation
- Translation to other languages
- Example code and recipes

### 🐛 Issue Reports
- Bug reports with reproduction steps
- Feature requests with use cases
- Performance issue reports
- Security vulnerability reports (see [SECURITY.md](SECURITY.md))

### 💬 Community
- Answer questions in discussions
- Review pull requests
- Help triage issues
- Participate in design discussions

## 🏗️ Development Setup

### Prerequisites
- Python 3.6 or later
- Git
- (Optional) Nix for reproducible builds
- (Optional) Docker for containerized testing

### Local Development

```bash
# Clone the repository
git clone https://github.com/Hyperpolymath/vext.git
cd vext

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install development dependencies
pip install -r requirements-dev.txt

# Install vext in editable mode
pip install -e .

# Run tests
just test

# Run linters
just lint

# Check RSR compliance
just rsr-check
```

### Using Nix

```bash
# Enter development shell
nix develop

# Build
nix build

# Run
nix run
```

## 🧪 Testing

All contributions must include appropriate tests:

```bash
# Run all tests
just test

# Run specific test file
pytest tests/test_specific.py

# Run with coverage
just test-coverage

# Run integration tests
just test-integration
```

### Test Requirements
- Maintain or improve code coverage
- Include unit tests for new functions
- Include integration tests for new features
- Test edge cases and error conditions

## 📝 Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **test**: Test additions or changes
- **chore**: Build process or tooling changes
- **perf**: Performance improvements
- **ci**: CI/CD changes

### Examples

```
feat(irc): add TLS connection support

Implement TLS/SSL support for IRC connections using Python's ssl module.
This allows secure connections to IRC servers that support TLS.

Closes #42
```

```
fix(daemon): prevent memory leak in connection pool

Connection objects were not being properly released after use,
causing memory usage to grow over time.

Fixes #123
```

## 🔍 Code Review Process

1. **Submit PR**: Open a pull request with clear description
2. **CI Checks**: Automated tests and linters must pass
3. **Review**: Maintainers review code and provide feedback
4. **Iterate**: Address review comments
5. **Approval**: At least one maintainer approval required
6. **Merge**: Maintainer merges the PR

### Review Criteria
- Code quality and readability
- Test coverage
- Documentation updates
- Performance impact
- Security considerations
- Backward compatibility

## 🎨 Code Style

### Python
- Follow [PEP 8](https://pep8.org/)
- Maximum line length: 100 characters
- Use type hints where appropriate
- Use docstrings for public functions

```python
def send_notification(channel: str, message: str) -> bool:
    """Send a notification to an IRC channel.

    Args:
        channel: IRC channel name (e.g., "#mychannel")
        message: Message to send

    Returns:
        True if notification was sent successfully, False otherwise.

    Raises:
        ValueError: If channel name is invalid
    """
    pass
```

### Tools
- **Linting**: `pylint`, `flake8`
- **Formatting**: `black`
- **Type checking**: `mypy`
- **Security**: `bandit`, `safety`

Run all checks:
```bash
just lint
```

## 📋 Pull Request Checklist

Before submitting a PR, ensure:

- [ ] Code follows project style guidelines
- [ ] All tests pass (`just test`)
- [ ] New tests cover your changes
- [ ] Documentation is updated
- [ ] Commit messages follow conventions
- [ ] No merge conflicts with main branch
- [ ] CI checks pass
- [ ] PR description explains changes clearly

## 🏛️ Tri-Perimeter Contribution Framework (TPCF)

vext uses a graduated trust model for contributions:

### Perimeter 1: Core
- **Access**: Write access to main repository
- **Members**: Core maintainers (see [MAINTAINERS.md](MAINTAINERS.md))
- **Responsibilities**: Architecture decisions, releases, security

### Perimeter 2: Active Contributors
- **Access**: Triage permissions, reviewer status
- **Requirements**: 5+ merged PRs, consistent quality
- **Responsibilities**: Code review, issue triage, mentoring

### Perimeter 3: Community
- **Access**: Everyone can contribute
- **Method**: Fork and pull request
- **Support**: Issues, discussions, documentation

To advance from Perimeter 3 to Perimeter 2:
1. Make quality contributions over time
2. Demonstrate understanding of codebase
3. Show commitment to project values
4. Request promotion in #vext-contributors

See [governance/PROJECT_GOVERNANCE.md](governance/PROJECT_GOVERNANCE.md) for details.

## 🐛 Reporting Bugs

### Before Reporting
- Search existing issues to avoid duplicates
- Test with the latest version
- Gather reproduction steps

### Bug Report Template

```markdown
**Description**
Clear description of the bug

**Reproduction Steps**
1. Start irkerd with config...
2. Send notification via...
3. Observe error...

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- vext version: 1.0.0
- Python version: 3.9.5
- OS: Ubuntu 22.04
- IRC server: Libera.Chat

**Logs**
```
Relevant log output
```

**Additional Context**
Any other relevant information
```

## ✨ Feature Requests

We welcome feature requests! Please:

1. **Check existing issues** for duplicates
2. **Describe the use case** clearly
3. **Explain why** this feature would be valuable
4. **Propose implementation** (optional but helpful)
5. **Consider contributing** the feature yourself

### Feature Request Template

```markdown
**Use Case**
Describe the problem this feature would solve

**Proposed Solution**
How would you like this to work?

**Alternatives Considered**
Other approaches you've considered

**Additional Context**
Examples, mockups, or related projects
```

## 🔒 Security Contributions

Security issues require special handling:

- **DO NOT** open public issues for security vulnerabilities
- See [SECURITY.md](SECURITY.md) for reporting process
- Security patches receive priority review
- Reporters receive credit in security advisories

## 📄 License

By contributing, you agree that your contributions will be licensed under both:
- **MIT License** (permissive)
- **AGPL-3.0-or-later** (copyleft)

This is the Palimpsest Dual License. See [LICENSE](LICENSE) for details.

You must have the right to license your contribution under these terms.

### Copyright

- Retain your copyright
- You grant us a perpetual, worldwide license
- Small contributions (<10 lines) may not require attribution
- Significant contributions are credited in [CONTRIBUTORS.md](CONTRIBUTORS.md)

## 🎓 Learning Resources

New to the project? Start here:

- [README.md](README.md) - Project overview
- [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md) - Setup instructions
- [USAGE_GUIDE.md](USAGE_GUIDE.md) - How to use vext
- [TECHNOLOGY_STACK.md](TECHNOLOGY_STACK.md) - Technical architecture
- [docs/](docs/) - Additional documentation

## 💬 Communication Channels

- **Issues**: Bug reports and feature requests
- **Discussions**: General questions and ideas
- **Matrix**: `#vext:matrix.org` (real-time chat)
- **Email**: dev@vext.dev (development questions)

## 🙏 Recognition

Contributors are recognized in:
- [CONTRIBUTORS.md](CONTRIBUTORS.md) - All contributors
- [MAINTAINERS.md](MAINTAINERS.md) - Core maintainers
- Release notes - Specific contributions
- Project website - Hall of fame

## 📞 Questions?

If you have questions about contributing:

- **General**: Open a discussion
- **Specific issue**: Comment on the issue
- **Private**: Email dev@vext.dev

---

**Thank you for contributing to vext!** 🎉

Your contributions help make IRC notifications better for everyone.
