# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly and confidentially.

### How to Report

1. **Do not** open a public GitHub issue for security vulnerabilities
2. **Email the maintainers** at `alberto.hdz1063@gmail.com` with the subject line `[SECURITY] Vulnerability Report`
3. **Include details**:
   - Description of the vulnerability
   - Affected components or files
   - Steps to reproduce (if applicable)
   - Potential impact
   - Suggested fix (if you have one)

### Timeline

- We will acknowledge your report within 48 hours
- We will investigate the issue and provide an initial assessment within 1 week
- We will work with you to develop and test a fix
- Once a fix is released, public disclosure will follow

## Supported Versions

Security updates are provided for the following versions:

| Version | Supported |
|---------|-----------|
| Latest (main) | ✅ Yes |
| Previous releases | ⚠️ Case-by-case |

## Security Considerations for Users

### Dependencies

This project uses Xilinx Vivado 2024.2 and standard IEEE VHDL libraries. Users should:

- Keep Vivado updated to the latest patch version
- Review the security advisories from Xilinx
- Use secure development practices when synthesizing and deploying designs

### Simulation and Testing

- Simulations are performed in Vivado's behavioral simulation environment
- This project does not handle external network communication or user input validation in this version
- Always verify designs through simulation before hardware deployment

## Security Best Practices for Contributors

When contributing to this project:

- **Don't commit secrets** — No passwords, API keys, or personal information in code
- **Use .gitignore** — Keep sensitive files out of version control
- **Review before pushing** — Check your changes for accidental leaks
- **Follow secure coding** — Use proper VHDL practices to avoid simulation errors

## Questions or Concerns?

If you have general security questions about the project, please contact the maintainers at `alberto.hdz1063@gmail.com`.
