---
Document: Pricing Strategy
Version: 1.1
Status: Approved
Project: Relvio
Owner: Product Team
---

# Pricing Strategy

## Purpose

This document defines the strategic principles for evaluating and approving Relvio pricing.

Relvio is a multi-tenant Software as a Service product.

The long-term commercial model should support sustainable recurring product revenue while remaining understandable and appropriate for people-centered organizations.

This document does not define final public prices.

This document does not approve pricing tiers, quotas, trials, billing providers, payment infrastructure, subscription APIs, database structures, or feature entitlements.

Final pricing decisions require product and commercial validation.

---

# Pricing Objective

Relvio pricing should aim to be:

- Easy to understand
- Transparent
- Appropriate for validated customer needs
- Accessible to relevant early organizations
- Scalable as customer value grows
- Sustainable for the Relvio business
- Practical to operate and support

Pricing should communicate value clearly.

Commercial complexity should not be introduced without a validated reason.

---

# Product Context

Relvio is a People Operating System for people-centered organizations.

Relvio helps organizations understand people, strengthen relationships, coordinate meaningful follow-up, and support organizational growth.

Primary brand message:

> Build stronger relationships.

Churches and similar organizations are an important initial validation market.

The core Relvio product remains organization-neutral.

Pricing research may consider the realities of initial validation customers without hardcoding Relvio as a church-only product.

---

# SaaS Commercial Direction

Relvio is intended to operate as a recurring SaaS product.

Potential commercial structures may include:

- Recurring subscriptions
- Monthly billing
- Annual billing

These are strategic directions.

This document does not approve:

- Final billing frequencies
- Annual discount percentages
- Multi-year contracts
- Per-user pricing
- Per-person pricing
- Usage-based pricing
- Organization-size pricing
- Feature-based pricing
- Add-on pricing

The final pricing structure must be validated before implementation.

---

# Pricing Philosophy

Organizations should pay in a way that reasonably reflects the value Relvio provides.

Pricing should avoid unnecessary complexity.

Relvio should prefer a pricing model that customers can understand without requiring extensive explanation.

Pricing decisions should consider:

- Customer value
- Customer size and operating context
- Product usage patterns
- Infrastructure cost
- Support cost
- Payment processing cost
- Commercial sustainability
- Market expectations
- Expansion potential

No single pricing dimension is approved by this document.

---

# Pricing Validation

Before final pricing is approved, Relvio should validate the commercial model with real or representative target organizations.

Validation may explore:

- Willingness to pay
- Perceived product value
- Organization size
- Number of managed people
- Number of active organization users
- Frequency of product usage
- Importance of attendance workflows
- Importance of follow-up workflows
- Importance of journey workflows
- Sensitivity to recurring software cost
- Preferred billing frequency
- Expected support level

Research findings should inform pricing decisions.

AI coding assistants must not convert research questions into billing rules.

---

# Plan Structure

The final number and names of Relvio plans are not approved by this document.

Do not assume the existence of:

- Free
- Starter
- Professional
- Enterprise

as production pricing tiers.

These names appeared in an earlier Atlas draft and are not implementation authority.

The final plan structure should remain as simple as practical.

Plan decisions should be made after sufficient product and customer validation.

---

# Free Access

A permanent free plan is not approved by this document.

Relvio may evaluate whether free access supports:

- Product discovery
- Early adoption
- Customer acquisition
- Small organization access
- Product-led growth

The evaluation must also consider:

- Infrastructure cost
- Support cost
- Abuse
- Dormant organizations
- Data storage
- Conversion behavior
- Operational complexity

Do not implement a free-plan entitlement model unless a separate approved pricing decision defines it.

Do not invent free-plan quotas.

---

# Trial Strategy

A trial may be evaluated as part of Relvio's commercial model.

The following are not currently approved:

- A 14-day trial
- A 7-day trial
- A 30-day trial
- No-credit-card trials
- Credit-card-required trials
- Automatic trial conversion

Trial length and behavior require explicit commercial approval.

Before implementation, approved documentation must define:

- Trial eligibility
- Trial duration
- Trial start behavior
- Trial expiration behavior
- Access after expiration
- Upgrade behavior
- Data behavior
- Repeated trial prevention where required

Claude or another AI coding assistant must not invent trial lifecycle rules.

---

# Pricing Dimensions

Relvio may evaluate different pricing dimensions.

Potential research dimensions include:

- Organization
- Active organization users
- Managed people
- Product capability
- Usage
- Support level

These are evaluation categories.

They are not approved billing metrics.

Do not create database counters, entitlement checks, quotas, or API restrictions from these categories without an approved pricing model.

---

# Feature Packaging

Pricing strategy must not become an independent source of product scope.

`MVP Scope.md` controls the Relvio v1 product scope boundary.

`Feature Backlog.md` controls recorded backlog items.

`Roadmap.md` controls approved delivery sequencing.

`Future Features.md` controls speculative long-term opportunity boundaries.

A capability must not become an approved product feature because it appears in a pricing discussion.

Pricing must package approved product capabilities.

Pricing must not invent product capabilities.

---

# Entitlements

Feature entitlements are not defined by this document.

Do not implement:

- Plan permission checks
- Feature gates
- Usage quotas
- People limits
- Event limits
- Storage limits
- Export limits
- Seat limits
- Admin limits

until the pricing and entitlement model is explicitly approved.

When entitlements are approved, protected entitlement enforcement must be authoritative on the backend.

Flutter may present entitlement-aware UI.

Flutter must not be the authoritative commercial access-control layer.

Hiding a Flutter control is not entitlement enforcement.

---

# Roles, Permissions, and Pricing

Relvio roles and permissions are security and organization-access responsibilities.

They must not be confused with commercial entitlements.

Roles and permissions control what an authorized organization user may do.

Commercial entitlements may eventually control what an organization has purchased or can access.

These are separate responsibilities.

Do not encode pricing plans as roles.

Do not encode roles as pricing plans.

Backend authorization remains governed by approved security and API documentation.

---

# Future Product Capabilities

This pricing document does not approve premium versions or add-ons for speculative capabilities.

It does not approve paid add-ons for:

- SMS
- Messaging integrations
- AI insights
- AI assistance
- Automation
- Additional storage
- Custom domains
- White labeling
- Public API access
- Enterprise authentication
- Custom integrations

Future opportunities must first become approved product capabilities.

Only then may pricing evaluate whether and how they are commercially packaged.

A future feature is not automatically a premium feature.

---

# Billing Infrastructure

No billing provider is approved by this document.

Do not install or integrate a payment or subscription provider based on this pricing strategy.

Do not invent:

- Billing API endpoints
- Subscription tables
- Plan tables
- Price tables
- Invoice tables
- Payment tables
- Billing webhooks
- Checkout flows
- Customer portal flows

without approved billing architecture and API documentation.

Billing infrastructure requires separate review of:

- Product requirements
- Payment provider
- Supported countries
- Supported currencies
- Taxes
- Payment methods
- Subscription lifecycle
- Webhook security
- Retry behavior
- Failed payments
- Refund behavior
- Reconciliation
- Data retention
- Operational support

Relvio's current approved architecture remains:

Flutter

↓

Backend REST API

↓

PostgreSQL

Flutter must never connect directly to PostgreSQL.

Any future billing integration must preserve approved backend security boundaries.

---

# Currency and Market Considerations

Final supported currencies are not approved by this document.

Pricing validation should consider the commercial realities of Relvio's validated markets.

Potential considerations include:

- Local purchasing power
- Currency volatility
- Payment availability
- International customers
- Payment provider support
- Tax requirements
- Pricing communication

Do not hardcode a currency from this document.

Do not implement currency conversion.

Do not invent regional pricing rules.

Regional or market-specific pricing requires explicit commercial approval.

---

# Discounts

No discount program is approved by this document.

Relvio may evaluate discounts for validated commercial reasons.

Potential evaluation areas may include:

- Annual billing
- Early customer programs
- Non-profit programs
- Educational programs
- Commercial partnerships

This document does not approve:

- Discount percentages
- Coupon systems
- Referral rewards
- Promotional pricing
- Lifetime deals

Discount infrastructure must not be implemented without an approved commercial requirement.

---

# Upgrade and Downgrade Behavior

Upgrade and downgrade lifecycle behavior is not approved by this document.

Do not assume:

- Upgrades take effect immediately
- Downgrades occur at the next billing cycle
- Proration is required
- Credits are issued
- Entitlements change immediately

These behaviors depend on the approved pricing model and billing provider.

Before implementation, subscription lifecycle documentation must define the expected behavior.

---

# Cancellation

Relvio should aim for clear and fair cancellation behavior.

The exact cancellation lifecycle is not approved by this document.

Do not invent:

- Grace periods
- Immediate data deletion
- Delayed data deletion
- Read-only access
- Reactivation periods
- Automatic organization deletion

Data lifecycle behavior must align with approved security, privacy, product, and database decisions.

Cancellation must not silently determine data-retention policy.

---

# Data Retention Boundary

Commercial subscription state and data retention are related but separate responsibilities.

An organization ending a paid relationship does not automatically define how its data should be deleted.

Data retention requires approved rules covering:

- Organization data
- People records
- Attendance history
- Journey history
- Follow-up records
- Audit-relevant information
- Legal or compliance obligations where applicable

Pricing documentation must not invent permanent deletion behavior.

---

# Early Validation Period

During early Relvio validation, the primary commercial goal is to understand whether organizations receive enough recurring value from the approved product to support a sustainable business model.

The focus should be on:

- Product value
- Customer usage
- Customer understanding
- Workflow relevance
- Retention signals
- Support requirements
- Willingness to pay

This does not require maximizing short-term revenue.

It requires learning enough to make deliberate pricing decisions.

---

# Pricing Review

Approved pricing should be reviewed periodically when meaningful evidence justifies review.

Relevant evidence may include:

- Customer feedback
- Customer conversion
- Retention
- Churn
- Product usage
- Infrastructure cost
- Support cost
- Payment cost
- Market changes
- Product capability changes

Pricing should not change reactively without understanding the customer and business impact.

---

# Pricing Success Direction

The pricing model should ultimately support outcomes such as:

- Customers understand what they are paying for.
- Customers can identify the value of Relvio.
- Commercial packaging remains understandable.
- The business can support product operations sustainably.
- Relevant customers can move into an appropriate paid relationship.
- Pricing complexity remains controlled.
- Product packaging does not distort the Relvio product vision.

Exact pricing metrics and numeric targets require separate approved commercial measurement decisions.

Do not invent conversion or churn targets during implementation.

---

# Approval Requirements

Before production pricing or billing implementation begins, approved decisions should define the relevant commercial model.

Depending on the chosen approach, approval may include:

1. Pricing model
2. Plan structure
3. Plan names
4. Prices
5. Supported currencies
6. Billing frequencies
7. Trial behavior
8. Free access behavior
9. Feature packaging
10. Entitlement rules
11. Usage limits
12. Discount rules
13. Upgrade behavior
14. Downgrade behavior
15. Cancellation behavior
16. Billing provider
17. Payment methods
18. Subscription lifecycle
19. Data lifecycle implications
20. Required API and database changes

Only after the relevant decisions are approved should implementation-controlling documentation be updated.

---

# AI Implementation Rules

Claude or another AI coding assistant acts as an implementation engineer.

AI must not use this document to invent:

- Pricing plans
- Plan names
- Prices
- Currencies
- Trials
- Quotas
- People limits
- Seat limits
- Storage limits
- Feature gates
- Billing endpoints
- Billing tables
- Subscription models
- Payment providers
- Upgrade rules
- Downgrade rules
- Cancellation rules
- Discount systems

AI must not create billing or entitlement infrastructure in anticipation of future pricing.

When approved pricing requires implementation, the relevant API, database, security, and product documentation must first define the implementation responsibilities.

---

# Documentation Responsibilities

This document owns:

- Relvio pricing philosophy
- Pricing evaluation principles
- Commercial validation direction
- Pricing decision boundaries
- Pricing approval requirements

This document does not own:

- Product feature scope
- Feature backlog
- Delivery sequencing
- API contracts
- Database schema
- Billing architecture
- Payment provider selection
- Subscription lifecycle implementation
- Data retention policy
- Security implementation

Those responsibilities remain with their approved Relvio documents and future explicitly approved commercial implementation documentation.

---

# Guiding Principle

Relvio pricing should be deliberate.

The commercial model should be based on validated customer value and sustainable product operation.

Do not create pricing complexity before the product and customer evidence justify it.

Pricing should package approved Relvio value.

It must not invent the product.

---

# Success Criteria

This document is successful when:

- Pricing remains strategically guided without becoming prematurely fixed.
- Old Atlas plan assumptions cannot become accidental implementation scope.
- Product features are not invented through pricing tiers.
- Billing infrastructure is not pre-built without approval.
- Roles and permissions remain separate from commercial entitlements.
- Flutter is not treated as the authoritative entitlement layer.
- Trial and subscription lifecycle behavior is not guessed.
- Data retention is not determined by cancellation assumptions.
- Future opportunities do not become automatic paid add-ons.
- Relvio can make final pricing decisions using validated customer and business evidence.

---

# End of Document