# Contributing Guidelines

Thank you for your interest in contributing to WTF M4ST! We welcome issues, suggestions, and pull requests to help improve this personal AI automation stack.

## Setting Up Your Environment

1. Clone the repository:
   ```bash
   git clone https://github.com/m4stanuj/wtf-m4st.git
   cd wtf-m4st
   ```

2. Initialize a python virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. Install the package in editable mode with development dependencies:
   ```bash
   pip install -e .[dev]
   ```

4. Install the pre-commit hooks:
   ```bash
   pre-commit install
   ```

## Development and Verification

### Running Tests
Before submitting any changes, make sure all tests pass:
```bash
python -m pytest
```

### Running Crews (Dry Run)
You can test the crew execution without consuming API tokens by executing them with the `--dry-run` flag:
```bash
python crews/nightly_crew.py --dry-run
python crews/content_crew.py --dry-run
python crews/bugfix_crew.py --dry-run
```

### Formatting and Linting
We use `ruff` to format and lint code. Ensure your code passes quality gates before committing:
```bash
ruff check .
ruff format .
```

## Pull Request Process

1. Create a descriptive branch for your changes: `git checkout -b feature/cool-new-agent`.
2. Commit your changes with clear, concise commit messages.
3. Push to your branch and open a Pull Request against the `main` branch.
4. Ensure the GitHub Actions CI pipeline passes successfully.
