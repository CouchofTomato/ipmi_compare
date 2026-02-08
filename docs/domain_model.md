# Domain Model

This document describes the core domain concepts used in the IPMI comparison application.
It is intended as a shared reference for contributors and agents to ensure consistent naming,
relationships, and behaviour.

This is not an exhaustive specification — it documents **what exists today** and the
assumptions the system relies on.

---

## High-level overview

The application models international health insurance products offered by insurers.
At a high level:

- An **Insurer** offers one or more **Plans**
- A **Plan** has many **PlanVersions**, representing the plan at a specific point in time
- A **PlanVersion** is composed of one or more **PlanModules**
- **PlanModules** may be grouped using **ModuleGroups**
- **PlanModules** define coverage through **ModuleBenefits**
- **ModuleBenefits** reference reusable **Benefits**
- Cost-sharing (deductibles, co-payments, excesses) is modelled using **CostShares**

The system supports both:

- modular plans (coverage built from selectable modules), and
- non-modular plans (a single module covering multiple benefit areas).

---

## Core entities

### Insurer

Represents an insurance provider.

Key characteristics:

- Has many Plans
- Identified by name and jurisdiction
- Does not contain pricing, benefit, or coverage logic

Insurers are primarily an organisational and filtering construct.

---

### Plan

Represents a named insurance product offered by an insurer.

Key characteristics:

- Belongs to an Insurer
- Has many PlanVersions
- Does not directly define coverage or benefits

A Plan acts as a stable product identity over time.

---

### PlanVersion

Represents a specific version of a Plan at a given point in time.

Key characteristics:

- Belongs to a Plan
- Has many PlanModules
- Stores eligibility and structural rules such as:
  - age limits
  - policy type (individual / company / corporate)
  - children-only eligibility
  - publication and review status
- Only one PlanVersion should normally be marked as `current`

PlanVersions allow insurers to change benefits or rules without breaking comparisons
across time.

---

### PlanModule

Represents a unit of coverage within a specific PlanVersion.

Key characteristics:

- Belongs to a PlanVersion
- Belongs to a ModuleGroup
- Can be marked as core or optional
- May define overall limits at the module level
- Can be associated with multiple CoverageCategories
- Links to Benefits via ModuleBenefits

A PlanModule may represent:

- a focused area (e.g. “Outpatient”), or
- broad coverage (e.g. a single module covering many benefit areas).

---

### ModuleGroup

Used to group related PlanModules.

Key characteristics:

- Required for all PlanModules
- Used for organisational and UI purposes
- Can represent mutually exclusive choices or simple grouping
  (e.g. “Outpatient options” vs “Outpatient cover”)

ModuleGroups do not define coverage themselves.

---

### Benefit

Represents a specific insurable service or treatment type
(e.g. inpatient surgery, outpatient consultations, evacuation).

Key characteristics:

- Benefits are reusable and generic
- Benefits are not plan- or insurer-specific
- Coverage details are defined through ModuleBenefits

---

### ModuleBenefit

Defines how a specific PlanModule covers a specific Benefit.

Key characteristics:

- Belongs to a PlanModule
- Belongs to a Benefit
- Stores coverage detail such as:
  - monetary limits (multi-currency)
  - limit units and descriptions
  - waiting periods
  - interaction type
  - weighting / importance
- This is where “what is actually covered” is expressed

ModuleBenefit is the primary source of truth for benefit-level coverage.

---

## Cost sharing (deductibles, excesses, co-payments)

Cost sharing is modelled using **CostShare** and **CostShareLink**.

### CostShare

Represents a single cost-sharing rule.

Key characteristics:

- Defines amount, type (deductible, co-pay, etc.), unit, currency, and scope
- Belongs to a polymorphic scope:
  - a PlanVersion,
  - a PlanModule,
  - a ModuleBenefit, or
  - a BenefitLimitGroup

### CostShareLink

Links one CostShare to another CostShare.

Key characteristics:

- Connects a CostShare to another CostShare
- Defines the relationship type (e.g. shared pool, override, dependent)

Only one relevant CostShare should apply for a given claim context.

---

## Benefit limit groups

### BenefitLimitGroup

Represents a shared limit that applies across multiple benefits.

Key characteristics:

- Defines a monetary limit (multi-currency)
- Can be referenced by multiple ModuleBenefits
- Used where insurers apply combined caps across related benefits

---

## Plan module dependencies

### PlanModuleRequirement

Represents a dependency between PlanModules within a PlanVersion.

Key characteristics:

- Belongs to a PlanVersion
- Links a dependent PlanModule to a required PlanModule
- Used to model cases where selecting one module requires another

---

## Coverage categories

CoverageCategories are used as a tagging system.

Key characteristics:

- A PlanModule can have many CoverageCategories
- A CoverageCategory can apply to many PlanModules
- A Benefit belongs to a CoverageCategory
- Categories are used for:
  - high-level summaries
  - filtering
  - comparison UI

They are not a substitute for benefits or modules.

---

## Geographic and residency rules

### GeographicCoverArea

Represents an area of cover (e.g. Worldwide, Excluding USA).

Plans link to areas of cover via join models.

### PlanResidencyEligibility

Defines residency-based eligibility rules for a PlanVersion.

---

## Important invariants and assumptions

- Coverage logic lives in PlanModules and ModuleBenefits, not Plans
- PlanVersions are the unit of comparison and eligibility
- Benefits are generic; coverage rules are contextual
- Cost sharing must not stack implicitly
- Naming should remain consistent with existing models
- New domain concepts should not be introduced without revisiting this document

---

## Explicitly out of scope

The following models are not part of the insurance domain:

- User
- WizardProgress
- ActiveStorage models

They should not be used to infer business or coverage logic.

---

## Guidance for contributors and agents

- Do not rename domain concepts without updating this document
- Do not introduce parallel models that duplicate responsibility
- When unsure where logic belongs:
  - prefer existing models,
  - then module–benefit relationships,
  - and avoid introducing new abstraction layers

When in doubt, simplicity and consistency take priority.
