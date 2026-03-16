#!/usr/bin/env bash
# Fixture repository generator for confidence testing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-utils.sh"

# Fixture workspace
FIXTURES_DIR="${FIXTURES_DIR:-/tmp/agent-adr-fixtures-$$}"

# Source test utilities for helper functions
main() {
  log_info "🏗️  Creating fixture repositories in: $FIXTURES_DIR"
  
  rm -rf "$FIXTURES_DIR"
  mkdir -p "$FIXTURES_DIR"
  
  # Create different types of fixture repos
  
  # 1. Basic Node.js repo
  log_info "Creating basic-node fixture..."
  local basic_repo="$FIXTURES_DIR/basic-node"
  create_basic_repo "$basic_repo"
  
  # 2. Repo with comprehensive instructions
  log_info "Creating with-instructions fixture..."
  local instructions_repo="$FIXTURES_DIR/with-instructions"
  create_repo_with_instructions "$instructions_repo"
  
  # 3. Minimal repo (bare minimum)
  log_info "Creating minimal fixture..."
  local minimal_repo="$FIXTURES_DIR/minimal"
  create_minimal_repo "$minimal_repo"
  
  # 4. Complex repo with nested structure
  log_info "Creating complex-nested fixture..."
  local complex_repo="$FIXTURES_DIR/complex-nested"
  mkdir -p "$complex_repo"
  
  cat > "$complex_repo/package.json" <<'JSON'
{
  "name": "complex-app",
  "version": "2.1.0",
  "description": "A complex multi-module application",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "test": "jest",
    "test:integration": "jest --config jest.integration.config.js",
    "lint": "eslint src/**/*.ts",
    "start": "node dist/index.js",
    "dev": "ts-node src/index.ts"
  },
  "dependencies": {
    "express": "^4.18.0",
    "mongoose": "^7.0.0",
    "redis": "^4.6.0",
    "jsonwebtoken": "^9.0.0"
  },
  "devDependencies": {
    "@types/node": "^18.0.0",
    "@types/express": "^4.17.0",
    "typescript": "^5.0.0",
    "jest": "^29.0.0",
    "eslint": "^8.0.0",
    "prettier": "^2.8.0"
  }
}
JSON
  
  mkdir -p "$complex_repo/src" "$complex_repo/tests" "$complex_repo/docs" "$complex_repo/scripts"
  
  cat > "$complex_repo/src/index.ts" <<'TS'
import express from 'express';
import { connectDatabase } from './database';
import { authMiddleware } from './middleware/auth';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(authMiddleware);

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/api/users', async (req, res) => {
  try {
    const db = await connectDatabase();
    const users = await db.collection('users').find({}).toArray();
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

export default app;
TS
  
  cat > "$complex_repo/README.md" <<'MD'
# Complex Application

A sophisticated multi-module Node.js application with TypeScript, Express, MongoDB, and Redis.

## Architecture

```
src/
├── index.ts          # Main application entry point
├── database/         # Database connection and models
├── middleware/       # Express middleware
├── routes/          # API route handlers
├── services/        # Business logic services
└── utils/           # Utility functions

tests/
├── unit/            # Unit tests
├── integration/     # Integration tests
└── e2e/            # End-to-end tests

docs/
├── api/            # API documentation
├── deployment/     # Deployment guides
└── architecture/   # Architecture documentation
```

## Development

```bash
npm install
npm run dev          # Development server
npm run build        # Production build
npm test             # All tests
npm run test:integration  # Integration tests only
```

## Deployment

- Docker containers
- Kubernetes orchestration
- Redis for caching
- MongoDB for persistence
MD
  
  mkdir -p "$complex_repo/.github/workflows"
  cat > "$complex_repo/.github/workflows/ci.yml" <<'YAML'
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run linting
        run: npm run lint
      
      - name: Run tests
        run: npm test
      
      - name: Run integration tests
        run: npm run test:integration
      
      - name: Build application
        run: npm run build

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run security audit
        run: npm audit --audit-level moderate
      
      - name: CodeQL Analysis
        uses: github/codeql-action/init@v2
        with:
          languages: javascript
YAML
  
  mkdir -p "$complex_repo/.github"
  cat > "$complex_repo/.github/copilot-instructions.md" <<'MD'
# Copilot Instructions for Complex Application

## Repository Context
- TypeScript Express application with MongoDB and Redis
- Modular architecture with services, middleware, and routes
- Comprehensive testing (unit, integration, e2e)
- CI/CD pipeline with security scanning

## Development Guidelines

### Code Style
- Use TypeScript strict mode
- Follow functional programming patterns where appropriate
- Use dependency injection for services
- Implement proper error handling with custom error classes

### Testing Requirements
- Write unit tests for all utility functions
- Write integration tests for API endpoints
- Mock external dependencies (database, Redis)
- Maintain >90% test coverage

### Security Requirements
- Validate all input data with Joi or similar
- Use parameterized queries for database operations
- Implement rate limiting on API endpoints
- Sanitize all user inputs

### Performance Requirements
- Use Redis caching for frequently accessed data
- Implement database connection pooling
- Add database indexes for query optimization
- Monitor application performance metrics

### Database Patterns
- Use Mongoose for MongoDB operations
- Implement proper schema validation
- Use transactions for multi-document operations
- Add database indexes for performance

## File Organization
```
src/
├── models/          # Mongoose schemas
├── routes/          # Express route handlers
├── middleware/      # Custom middleware
├── services/        # Business logic
├── utils/           # Utility functions
└── types/           # TypeScript type definitions
```

## API Design
- Use RESTful conventions
- Implement proper HTTP status codes
- Return consistent JSON response format
- Include API versioning in routes
MD
  
  cat > "$complex_repo/AGENTS.md" <<'MD'
# AI Agent Instructions

## Application Overview
This is a complex TypeScript Express application with the following characteristics:
- Multi-layered architecture (routes, services, models)
- MongoDB for data persistence with Mongoose ODM
- Redis for caching and session management
- Comprehensive testing strategy
- CI/CD pipeline with security scanning

## Agent Capabilities Required

### Code Generation
- Generate TypeScript interfaces for data models
- Create Express route handlers with proper error handling
- Implement Mongoose schemas with validation
- Write unit and integration tests

### Database Operations
- Create MongoDB queries with proper indexing
- Implement database transactions
- Design schema relationships and references
- Optimize database performance

### API Development
- Design RESTful API endpoints
- Implement middleware for authentication and validation
- Add proper HTTP status codes and error responses
- Create API documentation

### Testing
- Write Jest unit tests for services and utilities
- Create integration tests for API endpoints
- Mock external dependencies appropriately
- Achieve high test coverage

## Development Workflow
1. Create feature branch from develop
2. Implement changes with tests
3. Run full test suite locally
4. Update documentation as needed
5. Submit PR for code review
6. Address review feedback
7. Merge to develop, then main via PR

## Quality Standards
- TypeScript strict mode enabled
- ESLint and Prettier for code formatting
- >90% test coverage required
- Security audit must pass
- Performance tests for critical paths
MD
  
  mkdir -p "$complex_repo/docs/architecture"
  cat > "$complex_repo/docs/architecture/overview.md" <<'MD'
# Architecture Overview

## System Components

### Application Layer
- Express.js web framework
- TypeScript for type safety
- Modular route handlers

### Business Logic Layer
- Service classes for domain logic
- Dependency injection pattern
- Error handling middleware

### Data Layer
- MongoDB for primary storage
- Redis for caching and sessions
- Mongoose ODM for database operations

### Infrastructure Layer
- Docker containers
- Kubernetes orchestration
- CI/CD pipeline
- Monitoring and logging

## Data Flow

1. HTTP requests hit Express routes
2. Middleware handles authentication, validation
3. Route handlers call service methods
4. Services interact with database via models
5. Responses flow back through middleware
6. Caching applied at appropriate layers

## Security Considerations

- JWT-based authentication
- Input validation and sanitization
- Rate limiting on API endpoints
- Security scanning in CI/CD
- Regular dependency updates
MD
  
  # 5. Repo with existing AI configuration
  log_info "Creating with-ai-config fixture..."
  local ai_config_repo="$FIXTURES_DIR/with-ai-config"
  create_repo_with_instructions "$ai_config_repo"
  
  # Add additional AI-specific files
  mkdir -p "$ai_config_repo/.ai"
  cat > "$ai_config_repo/.ai/config.json" <<'JSON'
{
  "model": "gpt-4",
  "temperature": 0.1,
  "max_tokens": 2000,
  "system_prompt": "You are a senior TypeScript developer helping with this Express application.",
  "context_window": 8000,
  "features": {
    "code_completion": true,
    "code_generation": true,
    "test_generation": true,
    "documentation": true
  }
}
JSON
  
  cat > "$ai_config_repo/.ai/prompts/feature-development.md" <<'MD'
# Feature Development Prompt

When implementing new features for this application:

1. Understand the existing architecture and patterns
2. Create TypeScript interfaces for new data structures
3. Implement proper error handling and validation
4. Write comprehensive tests (unit and integration)
5. Update API documentation
6. Consider performance and security implications

## Code Patterns to Follow
- Use dependency injection for services
- Implement proper logging with structured data
- Follow RESTful API conventions
- Use async/await for asynchronous operations
- Handle errors at appropriate levels

## Testing Requirements
- Unit tests for all new functions
- Integration tests for API endpoints
- Mock external dependencies
- Achieve >90% code coverage
MD
  
  # 6. Broken repo (missing critical files)
  log_info "Creating broken fixture..."
  local broken_repo="$FIXTURES_DIR/broken"
  mkdir -p "$broken_repo"
  
  # Only package.json, missing README, tests, etc.
  cat > "$broken_repo/package.json" <<'JSON'
{
  "name": "broken-repo",
  "version": "0.1.0"
}
JSON
  
  # Create a broken tsconfig.json
  cat > "$broken_repo/tsconfig.json" <<'JSON'
{
  "compilerOptions": {
    "target": "ES2020",
    // This comment makes it invalid JSON
    "module": "commonjs"
  }
}
JSON
  
  log_info "✅ Fixture repositories created successfully!"
  log_info "Available fixtures:"
  find "$FIXTURES_DIR" -maxdepth 1 -type d -not -path "$FIXTURES_DIR" | sort | while read -r fixture; do
    local name="$(basename "$fixture")"
    log_info "  - $name"
  done
  
  log_info ""
  log_info "Usage examples:"
  log_info "  ./tests/smoke-test-confidence.sh  # Will use these fixtures"
  log_info "  KEEP_TEST_ARTIFACTS=1 ./tests/smoke-test-confidence.sh  # Keep artifacts for inspection"
  
  if [ "${KEEP_FIXTURES:-}" != "1" ]; then
    log_info ""
    log_info "💡 Set KEEP_FIXTURES=1 to keep fixtures for manual inspection"
    log_info "   Fixtures will be cleaned up on exit"
    trap "rm -rf '$FIXTURES_DIR'" EXIT
  else
    log_info ""
    log_info "🔍 Fixtures kept at: $FIXTURES_DIR"
  fi
}

main "$@"
