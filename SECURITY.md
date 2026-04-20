# Security Policy

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
