# PayLink — Bill Payments & Digital Wallet Backend

PayLink is a backend system designed for bill payments and digital wallet management, structured in Phase 1 as a **Modular Monolith**.

## Core Modules (Phase 1)
- **API / CLI Layer**: Entry point for customers/agents and admin/support operations.
- **Payment Processing**: Orchestrates payment requests, retries, timeouts, and refunds across the payment lifecycle (`Initiated`, `FundsHeld`, `SentToBiller`, `Completed`, `Failed`, `Unknown`, `Rejected`, `Refunded`).
- **Accounts & Wallet**: Manages balances, funds holds, and wallet releases.
- **Biller Catalog**: Maintains supported billers and service metadata.
- **Fraud Checks**: Validates transactions before holding funds.
- **Fees & Commissions**: Calculates applicable transaction fees and commissions.
- **Biller Integration**: Communicates with external/mock billers (such as `ElectroCo`, `AquaCo`, `TopUpNet`, `NetCo`).
- **Notifications**: Sends updates via SMS and push providers.
- **Reconciliation**: Resolves pending/unknown states and settlement mismatches.
- **Audit Log**: Records key system and payment events for traceability.

## Design Documentation
- **Payment Life Cycle State Diagram**: `Docs/Design/payment-state-diagram.md`
- **Prompt Log**: `Docs/prompt-log.md`

## Workflow & Contributing
- Create a feature/design branch from `main` instead of committing directly to `main`.
- Keep design diagrams as source files (`Mermaid` / `PlantUML`) under `Docs/Design/` and log AI-assisted steps in `Docs/prompt-log.md`.
- Open a **Pull Request** for review before merging into `main`.
