# Dev Commands

This application follows standard Rails conventions.

Rails version: 8.1.2

Prefer `bin/rails` where available to ensure the correct environment and Bundler context.

---

## Initial Setup

### Install dependencies

```bash
bundle install
```

### Prepare the database

Creates the database (if needed), loads the schema, and runs migrations.

```bash
bin/rails db:prepare
```

### Verify setup by running the test suite

```bash
bundle exec rspec
```

---

## Running the Application

### Start the Rails server

```bash
bin/rails server
```

### Open a Rails console

```bash
bin/rails console
```

---

## Testing

### Run the full test suite

```bash
bundle exec rspec
```

### Run a single spec file

```bash
bundle exec rspec spec/path/to/file_spec.rb
```

### Run a specific test by line number

```bash
bundle exec rspec spec/path/to/file_spec.rb:123
```

---

## Code Quality

### Run RuboCop

```bash
bundle exec rubocop
```

### Auto-correct safe RuboCop issues

```bash
bundle exec rubocop -A
```

---

## Database Tasks

### Run pending migrations

```bash
bin/rails db:migrate
```

### Roll back the most recent migration

```bash
bin/rails db:rollback
```

### Reset the local database (destructive)

Drops, recreates, loads the schema, and runs seeds (if present).
```bash
bin/rails db:reset
```

### Seed the database (if seeds are defined)

```bash
bin/rails db:seed
```

---

## Generators

Use Rails generators to keep code consistent with application conventions.

### Generate a model

```bash
bin/rails generate model Thing name:string
```

### Generate a migration

```bash
bin/rails generate migration AddThingToTable thing:string
```

### Generate a controller

```bash
bin/rails generate controller Things index show
```

---

## Useful Rails Commands

### View routes

```bash
bin/rails routes
```

---

## CI Parity (Recommended Before Pushing)

Run the following locally to match CI expectations:

```bash
bundle exec rubocop
bundle exec rspec
```

---

## Troubleshooting

### After changing gems

```bash
bundle install
```

### If database state seems inconsistent

```bash
bin/rails db:prepare
```

### If Spring causes unexpected behaviour (if enabled)

```bash
bin/spring stop
```
