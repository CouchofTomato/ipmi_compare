# AGENTS.md — How to work in this Rails app

## Stack

- Rails: 8.1.2
- Ruby: 3.4.6
- DB: postgres

## Primary rule

Default to **standard Rails conventions**. Keep solutions idiomatic and boring.

## Architecture conventions

- Prefer Rails MVC: controllers, models, views, helpers, mailers, jobs.
- Avoid introducing new patterns (service objects, interactors, repositories) unless this codebase already uses them for the same problem.
- Use ActiveRecord associations, validations, scopes, and concerns only when they simplify code (don’t over-abstract).

## Routing & data are source of truth

- Always check `config/routes.rb` and `db/schema.rb` (or `db/structure.sql`) before adding endpoints or assuming columns.

## Permissions / admin

- Do **not** add Pundit policies or `authorize` calls unless explicitly requested.
- Admin access is currently enforced via: a require_admin method in application_controller and then using a before_action in controllers that should only be accessible to admins

## LLM / ranking constraint (important)

- Any filtering/ranking must operate **only** on data in this app (database + code). No external browsing, APIs, or web calls.

## Testing & quality

- Add/adjust RSpec tests for new behaviour.
- Keep style consistent with existing specs.
- Run: `bundle exec rubocop` and `bundle exec rspec` (or binstubs if present) before considering work “done”.

## Dependency changes

- Do not add or remove gems, or change configuration defaults, unless explicitly requested.

## Canonical reference files

The following files are authoritative and must be followed:

- AGENTS.md (this file)
- docs/domain_model.md
- docs/permissions.md
- docs/dev_commands.md

When reviewing or modifying code:

- Do not introduce new domain concepts
- Do not rename existing models or responsibilities
- Flag inconsistencies instead of fixing them unless asked
