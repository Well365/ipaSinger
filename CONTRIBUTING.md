# Contributing to ipaSinger

Thank you for your interest in contributing to ipaSinger! This document provides guidelines and instructions for contributing.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Your environment (macOS version, Python version, Xcode version)
- Any relevant error messages or logs

### Suggesting Features

Feature suggestions are welcome! Please:
- Check if the feature has already been requested
- Provide a clear use case
- Explain how it would benefit users

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test your changes thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Style

- Follow PEP 8 style guidelines for Python code
- Add comments for complex logic
- Keep functions focused and single-purpose
- Use descriptive variable names

### Testing

When contributing code changes:
- Test on macOS with actual IPA files
- Test with different certificate types (development, distribution, enterprise)
- Verify error handling works correctly
- Test with and without optional parameters

### Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Well365/ipaSinger.git
   cd ipaSinger
   ```

2. Make the script executable:
   ```bash
   chmod +x ipasigner.py
   ```

3. Test your changes:
   ```bash
   python3 ipasigner.py --help
   ```

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Help others learn and grow

## Questions?

Feel free to open an issue for any questions or discussions about contributing.

Thank you for helping make ipaSinger better!
