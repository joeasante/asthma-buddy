---
review_agents:
  - kieran-rails-reviewer
  - security-sentinel
  - performance-oracle
  - architecture-strategist
  - pattern-recognition-specialist
---

# Project: Asthma Buddy

Rails 8.1.2 health-tracking app. Users log asthma symptoms and peak flow readings.

## Review Context

- Stack: Rails 8.1.2, Ruby 4.0.1, SQLite3, Propshaft, Importmap, Hotwire (Turbo + Stimulus)
- No Redis — uses Solid Queue, Solid Cache, Solid Cable (SQLite-backed)
- Deployment: Kamal with Docker
- Testing: Minitest, Capybara + Selenium for system tests
- Linting: RuboCop with rubocop-rails-omakase
- Health/medical app — HIPAA considerations may apply in future
