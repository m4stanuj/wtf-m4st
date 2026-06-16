# Security Policy

## Responsible Disclosure

If you discover a security vulnerability in this project, please report it to us responsibly. 

You can report vulnerabilities by opening a draft security advisory on GitHub or by contacting the repository maintainer directly at **m4stanuj@users.noreply.github.com**.

We will evaluate the issue and aim to provide a response within 48 hours. If confirmed, we will coordinate a fix and publish a patched release.

## Scope and Authorization

All security testing and tool usage in this repository are for **authorized pentesting and educational purposes only**. Using these tools against systems without explicit, written permission is strictly prohibited. The authors assume no liability for misuse of code, tools, or configuration files provided here.

Please ensure that you secure your local configuration by:
- Setting strong random values for `M4ST_TOKEN` in your `.env` file.
- Leaving `M4ST_ALLOWED_COMMANDS` restricted to the minimum required tools (`git,npm,python,pytest`).
- Never exposing the `openwork-mcp` port (`8765`) or other stack ports directly to the public internet.
