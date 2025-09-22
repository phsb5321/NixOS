---
applyTo: '**'
description: "Apply comprehensive best practices to code and configuration"
---

# Best Practices Application

Apply industry-standard best practices across different project types and technologies:

## Code Quality Assessment
1. **Language-Specific Analysis**:
   - **Nix**: Module structure, option definitions, proper escaping
   - **TypeScript/JavaScript**: Type safety, async patterns, error handling
   - **Python**: PEP compliance, type hints, documentation
   - **Rust**: Ownership patterns, error handling, performance
   - **Go**: Idiomatic patterns, error handling, concurrency

2. **Architecture Review**:
   - Separation of concerns
   - Dependency injection patterns
   - Interface design and abstractions
   - Configuration management

## Security Best Practices
1. **Code Security**:
   - Input validation and sanitization
   - Authentication and authorization patterns
   - Secret management (no hardcoded credentials)
   - SQL injection and XSS prevention

2. **Configuration Security**:
   - Least privilege principles
   - Secure defaults
   - Encryption at rest and in transit
   - Audit logging implementation

## Performance Optimization
1. **Code Performance**:
   - Algorithm complexity analysis
   - Memory usage optimization
   - Async/await patterns for I/O operations
   - Caching strategies

2. **System Performance**:
   - Database query optimization
   - Frontend bundle optimization
   - API response time improvement
   - Resource utilization monitoring

## Documentation and Testing
1. **Documentation Standards**:
   - API documentation with examples
   - Code comments for complex logic
   - Architecture decision records (ADRs)
   - User guides and tutorials

2. **Testing Strategy**:
   - Unit test coverage and quality
   - Integration testing patterns
   - End-to-end testing workflows
   - Performance testing implementation

## Development Workflow
1. **Version Control**:
   - Conventional commit messages
   - Branch naming conventions
   - Pull request templates
   - Code review guidelines

2. **CI/CD Optimization**:
   - Build pipeline efficiency
   - Automated testing integration
   - Deployment strategies
   - Monitoring and alerting

## Technology-Specific Patterns
1. **Web Development**:
   - React/Vue component patterns
   - State management best practices
   - API design (REST/GraphQL)
   - Progressive enhancement

2. **Backend Development**:
   - Microservices patterns
   - Database design and migrations
   - API versioning strategies
   - Error handling and logging

3. **DevOps/Infrastructure**:
   - Infrastructure as Code patterns
   - Container optimization
   - Monitoring and observability
   - Disaster recovery planning

## Arguments Support
- `$ARGUMENTS` can specify focus areas: `security`, `performance`, `testing`, `docs`
- Project type detection: `web`, `api`, `cli`, `library`, `nixos`

## Example Usage
```bash
# Comprehensive best practices review
/best-practices

# Focus on security improvements
/best-practices security

# Performance-specific optimizations
/best-practices performance

# Documentation improvements
/best-practices docs
```

## Implementation Approach
1. **Analysis Phase**: Scan codebase for anti-patterns and improvement opportunities
2. **Recommendation Phase**: Provide specific, actionable recommendations with examples
3. **Implementation Phase**: Apply changes systematically with proper testing
4. **Validation Phase**: Verify improvements and measure impact

Execute this workflow autonomously, providing concrete improvements with clear rationale and implementation steps.