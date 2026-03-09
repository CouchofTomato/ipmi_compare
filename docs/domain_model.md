# Domain Model

This document describes the core domain concepts used in the IPMI comparison application.  
It is intended as a shared reference for contributors and agents to ensure consistent naming,
relationships, and behaviour.

This is not an exhaustive specification — it documents **what exists today** and the
assumptions the system relies on.

---

# High-level overview

The application models international health insurance products offered by insurers.

At a high level:

- An **Insurer** offers one or more **Plans**
- A **Plan** has many **PlanVersions**, representing the plan at a specific point in time
- A **PlanVersion** is composed of one or more **PlanModules**
- **PlanModules** may be grouped using **ModuleGroups**
- **PlanModules** define coverage through **ModuleBenefits**
- **ModuleBenefits** reference reusable **Benefits**
- Cost-sharing (deductibles, co-payments, excesses) is modelled using **CostShares**
- Numeric limits are modelled using **BenefitLimitRules**

The system supports both:

- modular plans (coverage built from selectable modules), and
- non-modular plans (a single module covering multiple benefit areas).

---

# Core entities

## Insurer

Represents an insurance provider.

Key characteristics:

- Has many Plans
- Identified by name and jurisdiction
- Does not contain pricing, benefit, or coverage logic

Insurers are primarily an organisational and filtering construct.

---

## Plan

Represents a named insurance product offered by an insurer.

Key characteristics:

- Belongs to an Insurer
- Has many PlanVersions
- Does not directly define coverage or benefits

A Plan acts as a stable product identity over time.

---

## PlanVersion

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

## PlanModule

Represents a unit of coverage within a specific PlanVersion.

Key characteristics:

- Belongs to a PlanVersion
- Belongs to a ModuleGroup
- Can be marked as core or optional
- Can be associated with multiple CoverageCategories
- Links to Benefits via ModuleBenefits

A PlanModule may represent:

- a focused area (e.g. “Outpatient”), or
- broad coverage (e.g. a single module covering many benefit areas).

PlanModules represent **where coverage originates**, but individual benefit behaviour
is defined through ModuleBenefits.

---

## ModuleGroup

Used to group related PlanModules.

Key characteristics:

- Required for all PlanModules
- Used for organisational and UI purposes
- Can represent mutually exclusive choices or simple grouping
  (e.g. “Outpatient options” vs “Outpatient cover”)

ModuleGroups do not define coverage themselves.

---

## Benefit

Represents a specific insurable service or treatment type  
(e.g. inpatient surgery, outpatient consultations, evacuation).

Key characteristics:

- Benefits are reusable and generic
- Benefits are not plan- or insurer-specific
- Coverage details are defined through ModuleBenefits

---

# ModuleBenefit

Defines how a specific PlanModule covers a specific Benefit.

Key characteristics:

- Belongs to a PlanModule
- Belongs to a Benefit
- Has many BenefitLimitRules
- May have a CostShare
- Stores coverage detail such as:
  - waiting periods
  - coverage description
  - interaction type
  - weighting / precedence

ModuleBenefit is the primary source of truth for **benefit-level coverage**.

**ModuleBenefit does not store numeric limits.**  
All numeric limits are represented via `BenefitLimitRule`.

---

# Base vs modifying ModuleBenefits

Some modules **modify or enhance** benefits defined by another module.

Example:

- The **Hospital Plan** module defines a base *Childbirth* benefit.
- The **Non-hospitalisation Benefits** module increases the childbirth limit.

In this case:

- the Hospital Plan ModuleBenefit is the **base benefit**
- the Non-hospitalisation ModuleBenefit is an **enhancement**

To support this behaviour:

- A ModuleBenefit may optionally reference a **base ModuleBenefit**.
- Base ModuleBenefits represent the **owning source of coverage**.
- Enhancing ModuleBenefits modify specific attributes of the base benefit.

Ownership rules:

- The **owning module is always the module of the base ModuleBenefit**
- Enhancing modules **never become the benefit owner**

This distinction ensures:

- correct coverage attribution
- consistent UI behaviour
- accurate AI analysis of plan structures.

---

# Interaction types

ModuleBenefits may interact with other ModuleBenefits.

Supported interaction types include:

| Interaction | Meaning |
|---|---|
| append | adds additional coverage |
| replace | replaces another benefit definition entirely |
| enhance | modifies or improves the terms of another benefit |

Enhance interactions typically change:

- numeric limits
- waiting periods
- cost sharing
- wording notes

but do **not** change the owning module.

---

# Effective benefit resolution

When displaying the effective coverage for a benefit:

1. Locate the **base ModuleBenefit**
2. Locate any **enhancing ModuleBenefits**
3. Combine attributes using the override rules below.

---

# Field override behaviour

When an enhancement exists, fields are resolved as follows.

### Never overridden (always from base)

These fields define benefit identity.

- benefit
- owning module
- base_module_benefit_id
- benefit section/category

---

### Inherited unless overridden

These fields may be replaced by enhancements.

- waiting_period_months
- benefit_limit_rules
- cost_share
- inclusion / exclusion state
- display flags

---

### Additive / merged

These fields may combine base and enhancement information.

- notes
- explanation text
- enhancement labels

---

### Coverage description rule

By default:

- `coverage_description` is inherited from the **base ModuleBenefit**

Enhancements should not normally replace this text.

Enhancements may instead provide additional explanatory notes.

This prevents enhancements from incorrectly changing the perceived source of coverage.

---

# BenefitLimitRule

Represents a numeric limit rule attached to a ModuleBenefit.

Key characteristics:

- Belongs to a ModuleBenefit
- Uses `scope` to describe where the rule applies:
  - `benefit_level` for rules that apply to the whole benefit
  - `itemised` for rules that apply to a specific component (e.g. X-ray, ECG, scan)
- Supports multiple limit types:
  - `amount`
  - `as_charged`
  - `not_stated`

Insurer payment amounts are represented using:

- `insurer_amount_usd`
- `insurer_amount_gbp`
- `insurer_amount_eur`

Units describe how the amount applies (e.g. per session).

Rules may also define aggregate caps:

- `cap_insurer_amount_*`
- `cap_unit`

Rules are ordered by:

1. `position`
2. `created_at`

---

# Worked examples

## Physiotherapy

- CostShare:
  - 100% covered
- BenefitLimitRule:
  - USD 50 per session, up to USD 500 per policy year

---

## Diagnostics with itemised caps

ModuleBenefit: Outpatient diagnostics

BenefitLimitRules:

- X-ray: GBP 305 per examination
- ECG: USD 450 per examination
- Scan: USD 1,200 per examination, up to USD 2,500 per policy year

---

# Cost sharing

Cost sharing is modelled using **CostShare** and **CostShareLink**.

---

# CostShare

Represents a cost-sharing rule.

Key characteristics:

- Polymorphic association
- Defines amount, percentage, unit, and application scope

CostShare defines a `kind`:

- `deductible`
- `coinsurance`

Percentages such as **80% coinsurance** are stored here.

CostShares may attach to:

- PlanVersion
- PlanModule
- ModuleBenefit
- BenefitLimitGroup
- BenefitLimitRule

---

# Display semantics

PlanVersion and PlanModule cost shares represent **deductibles** and are **not displayed inline with each benefit**.

Inline benefit display uses:

1. BenefitLimitRule cost share (highest precedence)
2. ModuleBenefit cost share
3. no inline cost share

---

# CostShareLink

Links one CostShare to another CostShare.

Used to model:

- shared pools
- override relationships
- dependent cost share rules.

Only one relevant cost share should apply in a given claim context.

---

# Worked dental example

ModuleBenefit: Routine dental treatment

BenefitLimitRules:

- Root treatment (cap per tooth)
- Extraction (cap per tooth)
- Surgery (cap per tooth)
- X-ray
- Anaesthesia

CostShare:

- kind: coinsurance
- amount: 80
- unit: percent

Attached to each BenefitLimitRule.

Result:

Each rule displays **80% covered up to the relevant cap**.

Rule-level coinsurance overrides any ModuleBenefit-level coinsurance.

---

# Benefit limit groups

## BenefitLimitGroup

Represents a shared limit across multiple benefits.

Key characteristics:

- Acts as a shared pool/container
- Can be referenced by multiple ModuleBenefits
- Has many BenefitLimitGroupRules
- Supports optional wording overrides.

---

## BenefitLimitGroupRule

Defines the shared limit logic.

Supported rule types:

- `amount`
- `usage`
- `as_charged`
- `not_stated`

Supports period semantics:

- policy_year
- calendar_year
- rolling_days
- rolling_months
- lifetime

Ordered by `position` then `created_at`.

---

# Plan module dependencies

## PlanModuleRequirement

Represents a dependency between PlanModules.

Used when selecting one module requires another.

---

# Coverage categories

CoverageCategories are used as a tagging system.

Key characteristics:

- PlanModules may have many categories
- Categories may apply to many modules
- Benefits belong to a category

Used for:

- summaries
- filtering
- comparison UI.

They are not a substitute for benefits or modules.

---

# Geographic and residency rules

## GeographicCoverArea

Represents an area of cover (e.g. Worldwide, Excluding USA).

Plans link to areas via join models.

---

## PlanResidencyEligibility

Defines residency eligibility rules for a PlanVersion.

---

# Important invariants

- Coverage logic lives in **PlanModules and ModuleBenefits**
- **PlanVersions** are the unit of comparison
- Benefits are reusable and generic
- Numeric limits must only be stored in **BenefitLimitRule**
- Cost sharing must only be stored in **CostShare**
- ModuleBenefit ownership must not change due to enhancements

---

# Explicitly out of scope

The following models are not part of the insurance domain:

- User
- WizardProgress
- ActiveStorage models

They must not be used to infer coverage logic.

---

# Guidance for contributors and agents

- Do not rename domain concepts without updating this document
- Avoid introducing duplicate models for limits or cost sharing
- Prefer extending existing relationships rather than creating new abstractions
- Maintain consistent terminology across plans and benefits

When in doubt, **simplicity and consistency take priority**.