# Winnie: product flow and release sequence

## Product promise

Winnie helps a person, household, or small business understand what happened, why it matters, and what a plausible next month looks like. Every number and insight should lead back to the accounts, transactions, time period, and assumptions that produced it.

## Frontend flow

1. **Set up a workspace.** Create a portfolio, then entities (person, household, business) and accounts. Show plain language explanations for each level. A family with a side business can keep its business activity separate while seeing a combined portfolio.
2. **Bring in data.** Keep manual PDF/CSV upload available. Show the file's status, statement dates, linked transactions, and balance checkpoints. Reimports should be clear about duplicates.
3. **Review and correct.** Flag missing statement periods, unexplained balance differences, likely internal transfers, and uncertain categories. Allow a human to resolve each item and record who changed it. Until this exists, the dashboard should treat imported figures as provisional.
4. **Understand.** Overview should answer: current balance as of which date, money in and out over which period, what changed, and what needs attention. Clicking a number should expose its supporting records. Insights should explain evidence and confidence, not just state a tip.
5. **Look ahead.** Present a baseline range and scenario controls for known bills, income changes, and external inputs such as fuel prices. Label data freshness, source, assumptions, and the estimated effect. Keep scenarios separate from recorded facts.
6. **Ask Winnie.** Begin with read-only explanations of the user's own numbers and cited general tax topics. Show the records used, jurisdiction/year, uncertainty, and when a CPA is warranted. Do not silently create filings or definitive tax conclusions.

## Release slices

### R1: Trustworthy manual data and useful dashboard

- Import history and transaction drilldown (first slice implemented).
- Reconciliation queue: statement coverage, balance exceptions, duplicate imports, transfer candidates, category corrections.
- Account and portfolio views that show as-of dates, period labels, and traceable calculations.
- Overview readout showing recorded balance, period cashflow, attention items, and a clearly labeled estimate (first frontend pass implemented; transaction-level traceability remains).
- Guided navigation, page-level help, transaction filters, cashflow/insight drilldowns, and CPA preparation workspace (implemented in the frontend).
- A useful empty state and guided path from upload to first insight.

Exit condition: a user can upload overlapping statements, identify what was accepted, resolve exceptions, and trace an overview number to transactions.

### R2: Multi-user access and login hardening

The API already has email/password login and portfolio/entity/account roles. Treat this as hardening, not a fresh login feature: password reset, email verification, invitation acceptance, session management, rate limits, audit log, and tenant isolation tests. Decide whether an external identity provider is appropriate before expanding the current auth system.

Exit condition: separate households or businesses cannot read each other's data, invitations and revocation work, and account recovery is usable.

### R3: Bank connections

- Add a per-account connection model with provider item/account identifiers, consent state, last successful sync, cursor, and error state. Keep provider tokens encrypted and out of browser responses.
- Link through a server-issued token, then run initial and incremental transaction sync in background jobs. Handle added, modified, and removed records idempotently; reconcile them with manual imports.
- Expose connection health, account mapping, refresh, and disconnect in the same data source area as manual upload.

Exit condition: repeated syncs do not duplicate transactions, disconnect/reconnect is predictable, and manual upload remains usable.

### R4: Scenarios and sourced guidance

Start with user-entered scenario inputs. Add external signals only when source, region, update cadence, and estimated impact are visible. Add the tax helper after the transaction evidence and identity controls are dependable.

The CPA preparation area includes tax-year coverage, categories needing review, ledger questions, a CSV handoff, and a conversational assistant. Local Ollama is the default provider and receives only an aggregate record summary; it is labeled as having no live official-source retrieval. Optional OpenAI mode disables response storage, restricts search to IRS/USA.gov, and returns source links. Both modes escalate questions that depend on facts Winnie does not have. State and local guidance still needs a jurisdiction-specific source registry before it can be supported safely.

## Analytics worth adding next

Prioritize models that can be checked by the user:

1. **Data quality and categorization confidence.** Detect missing months, duplicate-looking records, balance discontinuities, and low-confidence categories. Corrections should become labeled training feedback.
2. **Merchant normalization and category suggestions.** Group description variants into one merchant and suggest categories with confidence and an explanation. Never overwrite a user correction silently.
3. **Unusual activity detection.** Compare each transaction with that account's own history and show the amount, usual range, and similar records. Avoid generic fraud claims.
4. **Recurring obligation detection.** Extend the existing cadence model to handle amount ranges, skipped periods, annual items, and cancellations. Show the occurrences behind every pattern.
5. **Cashflow ranges and scenarios.** Backtest forecasts, show error bands, and let users add dated changes such as income, rent, fuel prices, or hiring. External inputs need source, geography, freshness, and sensitivity.
6. **Tax document and CPA readiness.** Match likely document types, identify missing periods, and build a cited question packet. Do not infer deductibility or filing treatment from a merchant category alone.

## Decisions to settle with users

- Does a household prefer one shared portfolio with entities per person/business, or multiple portfolios with a combined view?
- Which three questions should the first overview answer every time?
- Which corrections must be possible before an import is considered reviewed?
- What level of explanation is useful for a forecast range without making it feel falsely precise?
