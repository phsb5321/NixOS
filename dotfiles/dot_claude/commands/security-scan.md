---
applyTo: '**'
description: "Comprehensive security analysis and vulnerability assessment"
---

# Security Analysis & Vulnerability Assessment

Perform thorough security analysis across code, configuration, and infrastructure:

## Code Security Analysis
1. **Static Code Analysis**:
   - **Secrets Detection**: Scan for hardcoded passwords, API keys, tokens
   - **Injection Vulnerabilities**: SQL injection, command injection, XSS
   - **Authentication Issues**: Weak password policies, session management
   - **Authorization Flaws**: Privilege escalation, access control bypasses

2. **Language-Specific Vulnerabilities**:
   - **JavaScript/TypeScript**: Prototype pollution, regex DoS, npm vulnerabilities
   - **Python**: Pickle deserialization, path traversal, dependency vulnerabilities
   - **Nix**: Insecure derivations, exposed secrets in store paths
   - **Shell Scripts**: Command injection, path issues, privilege problems

## Configuration Security
1. **System Configuration**:
   - **NixOS Security**: Service hardening, user permissions, firewall rules
   - **Service Configuration**: Secure defaults, encryption settings, access controls
   - **File Permissions**: World-readable sensitive files, improper ownership
   - **Network Security**: Open ports, insecure protocols, certificate validation

2. **Application Configuration**:
   - **Database Security**: Connection strings, access controls, encryption
   - **API Security**: CORS settings, rate limiting, input validation
   - **Session Management**: Cookie security, token handling, session timeouts
   - **Error Handling**: Information disclosure in error messages

## Dependency Security
1. **Package Vulnerabilities**:
   - Scan package.json, requirements.txt, Cargo.toml for known CVEs
   - Check for outdated dependencies with security patches
   - Analyze transitive dependency risks
   - Review licensing compliance issues

2. **Supply Chain Security**:
   - Verify package signatures and checksums
   - Check for typosquatting in dependencies
   - Review maintainer reputation and activity
   - Analyze build process security

## Infrastructure Security
1. **Container Security**:
   - Base image vulnerabilities
   - Dockerfile security best practices
   - Runtime security configurations
   - Registry security and scanning

2. **Cloud Configuration**:
   - IAM policy analysis
   - Storage bucket permissions
   - Network security groups
   - Encryption configurations

## Privacy and Compliance
1. **Data Protection**:
   - Personal data handling patterns
   - Data retention policies
   - Encryption at rest and in transit
   - Backup security measures

2. **Compliance Requirements**:
   - GDPR compliance checks
   - Industry-specific requirements
   - Audit trail implementation
   - Access logging requirements

## Threat Modeling
1. **Attack Surface Analysis**:
   - Identify entry points and attack vectors
   - Analyze trust boundaries
   - Review authentication mechanisms
   - Assess data flow security

2. **Risk Assessment**:
   - Prioritize vulnerabilities by severity and exploitability
   - Consider business impact of potential breaches
   - Evaluate likelihood of attack scenarios
   - Recommend remediation priorities

## Remediation Guidance
1. **Immediate Actions**:
   - Critical vulnerabilities requiring immediate patching
   - Security configurations to implement immediately
   - Access controls to strengthen
   - Monitoring to enable

2. **Long-term Improvements**:
   - Architecture security enhancements
   - Security process implementations
   - Training and awareness programs
   - Continuous security monitoring

## Arguments Support
- `$ARGUMENTS` can specify scan type: `code`, `config`, `deps`, `infra`, `compliance`
- Severity filter: `critical`, `high`, `medium`, `low`

## Example Usage
```bash
# Comprehensive security scan
/security-scan

# Focus on code vulnerabilities
/security-scan code

# Critical vulnerabilities only
/security-scan critical

# Dependency security analysis
/security-scan deps
```

## Output Format
1. **Executive Summary**: High-level security posture assessment
2. **Vulnerability Report**: Detailed findings with severity ratings
3. **Remediation Plan**: Prioritized action items with implementation guidance
4. **Security Metrics**: Quantified security improvements and KPIs

Execute this workflow autonomously, providing actionable security insights with clear remediation steps and priority guidance.