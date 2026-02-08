# Permissions & Access Control

This document describes how permissions are handled in this application **today**.
It is intentionally minimal and does not attempt to define a full authorisation framework.

## Current state

- The application does **not** use Pundit policies or `authorize` calls in request flow.
- Pundit is present in the Gemfile due to an earlier change, but is **not active** in practice.
- Access control is currently limited to:
  - Admin-only views and actions
  - Enforced at the controller / view level using simple conditional checks

The intent is to keep permissions lightweight while the product surface area is still evolving.

## What is explicitly out of scope (for now)

- No role-based access control (RBAC)
- No per-record authorisation
- No policy objects or policy scopes
- No partial or incremental rollout of Pundit

If a more sophisticated permissions model is required, it should be introduced deliberately
and applied consistently across the application.

## Guidance for contributors and agents

- Do **not** add Pundit policies, `authorize` calls, or `policy_scope` usage unless explicitly requested.
- Do **not** introduce alternative authorisation frameworks.
- When adding new admin-only functionality:
  - Follow the existing pattern used for admin views and controllers
  - Keep checks explicit and easy to reason about

## Future direction (non-binding)

If and when permissions need to expand beyond simple admin gating:

- Pundit is the likely choice
- Adoption should be done in a single, coordinated change
- Existing access checks should be replaced, not layered

Until then, simplicity and clarity take priority.
