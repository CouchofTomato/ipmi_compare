ai_agent_rules:
  general_guidelines:
    - Always use Rails best practices (e.g., skinny controllers, fat models).
    - Prefer service objects for business logic beyond basic CRUD.
    - Follow RESTful conventions for controllers and routes.
    - Use strong parameters for mass-assignment protection.
    - Never expose secrets, tokens, or credentials.
    - Validate inputs and sanitize outputs.
    - Write human-readable, well-documented code.

  testing_guidelines:
    - Use RSpec for all test suites.
    - Always write a test for every new model, controller, or service class.
    - Use `FactoryBot` for test data setup.
    - Use `let` and `subject` blocks for clarity.
    - Avoid using `before(:each)` for side-effect-heavy setups unless necessary.
    - Test both happy and edge cases.

  architecture_rules:
    - All business logic should reside in models or service objects.
    - Controllers should only handle request/response logic.
    - Keep views free of logic – use decorators or helpers instead.
    - Extract complex queries into scopes or query objects.
    - Use serializers (e.g., ActiveModel::Serializer or Fast JSON API) for API output.

  naming_conventions:
    - Models should use singular CamelCase (e.g., `UserProfile`).
    - Controllers should use plural (e.g., `UserProfilesController`).
    - Tests should be named consistently (`*_spec.rb`).
    - Use snake_case for variables and methods.

  coding_style:
    - Follow the Ruby style guide: https://rubystyle.guide/
    - Use RuboCop for linting and formatting.
    - Methods should be < 10 lines where possible.
    - Use meaningful names; avoid abbreviations.

  security:
    - Use `has_secure_password` for authentication where needed.
    - Always escape user input in views.
    - Never rescue generic `Exception` – rescue specific errors.
    - Log only non-sensitive information.

  AI-specific:
    - The AI agent should ask clarifying questions if requirements are ambiguous.
    - Prefer conventional Rails generators for scaffolding.
    - Avoid monkey patching unless explicitly instructed.
    - Annotate any AI-suggested code blocks with a comment like `# AI-generated: Description`