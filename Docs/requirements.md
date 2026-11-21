# PayLink — Software Requirements Specifications

**Cairo University — Faculty of Computers and Artificial Intelligence**  
Advanced Software Engineering · Phase 1 · Version 1.0 · November 2026

| **ID** | **Name** |
| --- | --- |
| 20242237 | fatema tarek Mostafa |
| 20242050 | Alaa Wafiq Samy |
| 20242148 | Sara Ali Refaey |
| 20242375 | Nawal Mahmoud Abdelalim |

## Contents
- [Document Purpose and Audience](#document-purpose-and-audience)
  - [Purpose](#purpose)
  - [Audience](#audience)
- [Introduction](#introduction)
  - [Software Purpose](#software-purpose)
  - [Software Scope](#software-scope)
  - [Problem Summary](#problem-summary)
  - [Definitions, acronyms, and abbreviations](#definitions-acronyms-and-abbreviations)
  - [Stakeholders](#stakeholders)
- [Requirements](#requirements)
  - [Priorities](#priorities)
  - [Functional Requirements](#functional-requirements)
  - [Non Functional Requirements](#non-functional-requirements)
- [Questions, Ambiguities and Decisions](#questions-ambiguities-and-decisions)
- [Enriched User Stories](#enriched-user-stories)

## Document Purpose and Audience

### Purpose

This document specifies the requirements of PayLink, a bill-payment and wallet backend, as agreed by its stakeholders. It states what the system must do and how well it must do it, so that the team can design (Phase 1 design pack) and build (Phase 2) the right system with less rework. Every requirement has an identifier (FR, NFR) so that design, code and tests can be traced back to it.

### Audience

- Software development team
- Stakeholders (see the Stakeholders section)
- Course instructors and teaching assistants who assess the work

## Introduction

### Software Purpose

The purpose of PayLink is to let customers pay utility bills (electricity, water, mobile top-up, internet) from a digital wallet, safely and correctly, through the mobile app or through agents’ terminals.

### Software Scope

PayLink is a backend system. It is in scope to build:

- Accounts and wallets with a ledger, holds, top-ups and refunds, and verification levels (Basic and Verified).
- A biller catalog with required input fields and amount limits.
- Payment processing with idempotency and a strict payment life cycle.
- One adapter per biller (ElectroCo, AquaCo, TopUpNet; NetCo batch is optional) with timeout, retry and callback handling.
- Fees and agent commissions, notifications with retry, fraud checks and nightly reconciliation.
- Support and admin functions, and an audit log of money movements and admin actions.

It is out of scope: real card or bank processing (top-ups are simulated), real SMS and push providers and real billers (all are mocks), and a full user interface (a simple web page or command-line client is enough).

### Problem Summary

PayLink is an Egyptian company, similar to Fawry or Vodafone Cash. Millions of people pay bills every month through its app and through small shops with a PayLink terminal. Customers want to avoid queues, and billers want to be paid quickly and correctly. PayLink earns a small fee on every payment and pays a commission to agents.

PayLink also holds its customers’ money. A customer who is charged twice, or charged for a payment the biller never received, destroys trust and exposes the company to losses and to regulators. The new backend must therefore be correct with money first of all, easy to extend with new billers, and ready for the busiest day of the month.

A payment is a chain of steps: check the customer’s limits, ask the biller for the bill, add the fee, run fraud checks, hold the money, send the payment to the biller, confirm it, notify the customer and, at night, compare everything with the biller’s settlement file. Every step can fail, and the four billers behave very differently (fast REST, slow XML, asynchronous with callbacks, daily batch file). Most of the requirements in this document describe what the system must do when something goes wrong: duplicate requests, timeouts, refusals, two payments at once, a provider that is down, or a mismatch with the biller’s records.

### Definitions, acronyms, and abbreviations

| **Phrase** | **Definition** |
| --- | --- |
| Biller | A company that issues bills and receives payments (electricity, water, mobile operator, internet provider). |
| Bill inquiry | Asking the biller what a customer owes before paying. |
| Wallet | A customer account holding money in EGP, with an available balance and a held balance. |
| Available balance | Money in a wallet that the customer can spend. |
| Held balance | Money in a wallet that is reserved for payments that are not yet confirmed. |
| Ledger | The list of entries that records every money movement. A balance is the sum of its entries and is never overwritten. |
| Hold | Money reserved for a payment that is not yet confirmed. |
| Service fee | What PayLink charges the customer for each payment. |
| Commission | What PayLink pays an agent for a payment made at the agent’s terminal. |
| Agent | A small shop with a PayLink terminal that pays bills on behalf of customers. |
| Idempotency key | A unique value sent with a request so that sending it twice has the effect of sending it once. |
| Settlement file | The biller’s daily list of the payments it received. |
| Reconciliation | Comparing PayLink’s payments with the settlement file and flagging the differences. |
| Refund | Returning held or charged money to the wallet after a failed or cancelled payment. For a failed payment the hold is released automatically (payment state Refunded); a Completed payment is returned only through a refund request. |
| Refund request | A customer’s request to get back the money of a Completed payment, which support approves or rejects. The payment itself stays Completed. |
| Payment attempt | Any payment request submitted by an account, whether it is accepted or rejected; repeated requests with the same idempotency key count once. |
| Rounding rule | Money values are rounded half-up (ROUND_HALF_UP) to two decimals, using exact decimal types. |
| Callback | A request that a biller sends to PayLink’s URL to report the final result of an asynchronous payment. |
| Payment state | One of Initiated, FundsHeld, SentToBiller, Completed, Failed, Unknown, Rejected, Refunded. |
| Verification level | Basic or Verified; the level decides the daily payment limit. |
| Velocity rule | A fraud rule that limits how many payments one account may make in a short time. |
| Mock biller | A small program that follows a biller’s contract and can be told to fail on purpose. |
| EGP | Egyptian pound (1 EGP = 100 piasters). |

### Stakeholders

| **Stakeholder** | **Description** | **Interest in the system** |
| --- | --- | --- |
| Customer | A person who owns a wallet and pays bills through the mobile app. | Fast and correct payments, no double charges, clear messages, safe money. |
| Agent | The owner of a shop with a PayLink terminal who pays bills for customers. | A simple payment flow and a correct commission. |
| Billers | ElectroCo, AquaCo, TopUpNet and NetCo, which receive the payments. | Each payment received exactly once, correct settlement, a stable contract. |
| PayLink management | The company that owns the product. | Revenue from fees, customer trust, easy addition of billers, a system that survives the busiest day. |
| Admin | An employee who configures billers, fees and limits and watches totals. | Changing rules without redeploying; clear daily figures. |
| Support employee | An employee who helps customers and investigates problems. | Finding a payment and its history quickly; blocking accounts; reviewing differences and refunds. |
| Regulators | Authorities that supervise companies that hold customers’ money. | A complete audit trail and no unexplained loss of money. |
| SMS and push providers | External services that deliver messages. | The system must keep working when they are down. |
| Development team | The students who build the system. | Clear, testable requirements and a system that is easy to change. |

## Requirements

### Priorities

Every requirement has one of three priorities:

| **Priority** | **Meaning** |
| --- | --- |
| Must | Required. The system is not acceptable without it. |
| Should | Important. It is built if at all possible. |
| Could | Desirable. It is built only if time remains. |

### Functional Requirements

The requirement numbers follow the project brief. Modules are those of the project brief.

| **ID** | **Requirement Statement** | **Module** | **Priority** | **User story** |
| --- | --- | --- | --- | --- |
| FR-1 | The system shall let a customer register; each newly registered customer shall have a basic verification level Basic. | Accounts and Wallet | Must | US #1 |
| FR-2 | The system shall let a customer be upgraded to Verified, which raises the limits. | Accounts and Wallet | Should | US #2 |
| FR-3 | The system shall allow a customer to view the wallet balance (available and held) and the transaction history. | Accounts and Wallet | Must | US #3 |
| FR-4 | The system shall allow a customer to top up the wallet using a simulated card or through an agent cash deposit. | Accounts and Wallet | Must | US #4 |
| FR-5 | The system shall create a ledger entry for every balance change and compute balances based on the ledger entries. | Accounts and Wallet | Must | US #5 |
| FR-6 | The system shall let an admin add, edit and disable billers and their services. | Biller Catalog | Must | US #6 |
| FR-7 | The system shall let a customer see the list of billers and the input fields required by each biller. | Biller Catalog | Must | US #7 |
| FR-8 | The system shall allow a customer to run a bill inquiry and see the amount, the fee and the total amount before paying. | Payment Processing | Must | US #8 |
| FR-9 | The system shall let a customer pay a bill from the wallet. | Payment Processing | Must | US #9 |
| FR-10 | The system shall return the original result when a request is repeated with the same idempotency key. | Payment Processing | Must | US #10 |
| FR-11 | The system shall move a payment only along the life cycle of the payment states and no other transitions. | Payment Processing | Must | US #11 |
| FR-12 | The system shall hold the funds before calling the biller and release them if the payment fails. | Payment Processing, Accounts and Wallet | Must | US #12, #13 |
| FR-13 | The system shall set a payment that times out to Unknown and re-query it by the retry rules. | Biller Integration | Must | US #14 |
| FR-14 | The system shall accept the asynchronous callbacks of TopUpNet and ignore duplicates. | Biller Integration | Must | US #15 |
| FR-15 | The system shall support at least 3 billers with different formats (ElectroCo, AquaCo, TopUpNet); the NetCo batch is optional. | Biller Integration | Must | US #16 |
| FR-16 | The system shall calculate fees by the fee rules of the project brief, including the promotion period. | Fees and Commissions | Must | US #8, #17 |
| FR-17 | The system shall let an agent pay on behalf of a customer and earn a commission. | Fees and Commissions, Payment Processing | Should | US #18 |
| FR-18 | The system shall reject payments above the single-payment limit or the daily limit with a clear reason. | Fraud Checks | Must | US #19 |
| FR-19 | The system shall block an account for 10 minutes after more than 5 payments in 60 seconds (velocity rule). | Fraud Checks | Should | US #20 |
| FR-20 | The system shall let a support employee search a payment by reference and see its full history. | Payment Processing | Must | US #21 |
| FR-21 | The system shall let a support employee block and unblock an account. | Accounts and Wallet | Should | US #22 |
| FR-22 | The system shall send the customer an SMS and a push message on completion and on failure of a payment. | Notifications | Must | US #13, #23 |
| FR-23 | The system shall retry a failed notification 3 times and then mark it undelivered. | Notifications | Should | US #24 |
| FR-24 | The system shall let an admin edit fee and limit values without redeploying. | Fees and Commissions, Fraud Checks | Should | US #25 |
| FR-25 | The system shall write every money movement and every admin action to an audit log. | All modules | Must | US #26 |
| FR-26 | The system shall produce a daily reconciliation report from a settlement file. | Reconciliation | Should | US #27 |
| FR-27 | The system shall let a customer request a refund of a completed payment, which support approves. | Payment Processing, Accounts and Wallet | Could | US #28 |
| FR-28 | The system shall let an admin view daily totals: payments, fees earned, commissions paid and failures per biller. | Reporting | Could | US #29 |

### Non Functional Requirements

| **ID** | **Measure** | **Requirement** | **Target and how it is measured** | **Priority** |
| --- | --- | --- | --- | --- |
| NFR-1 | Correctness | No payment is charged twice and no wallet balance ever becomes negative. | 0 double charges and 0 negative balances in the duplicate-request and concurrency tests (hard cases 1 and 4), run with at least 100 parallel requests on one wallet. Automated tests in the pipeline. | Must |
| NFR-2 | Performance | The system sustains 100 payments per second for 1 minute against the mock billers. | Load-test report: at least 100 payments per second for 60 seconds with 0 lost or duplicated payments; the 95th-percentile response time is recorded in the report. | Should |
| NFR-3 | Resilience | An outage of one biller does not stop payments to the other billers. | With one mock biller set to fail or time out on every call, payments to the other billers still complete with the same success rate as in a normal run (0 failures caused by the outage). Integration test and a load run with one biller down. | Must |
| NFR-4 | Modifiability | Adding a biller changes only the Biller Integration module and configuration. | The change that adds a new mock biller lists 0 modified files outside the Biller Integration package and the configuration. The same check is made for the ElectroCo API v2 change. | Must |
| NFR-5 | Auditability | Every money movement and admin action has an audit record with who, when and why. | 100% coverage: after the full automated test run, the number of ledger entries and admin actions without an audit record is 0 (database query in the test suite). | Must |
| NFR-6 | Testability | The system shall achieve at least 70% line coverage for domain logic through automated tests. | At least 70% line coverage on domain logic, measured and reported by the pipeline on every push. | Must |
| NFR-7 | Security | Only authenticated users can use the API, each role sees only what it is allowed to see, and passwords are never stored in plain text. | 100% of protected endpoints answer 401 (not logged in) or 403 (wrong role) in the API tests; 0 plain-text passwords in the database; a customer cannot read another customer’s wallet (tested). | Must |
| NFR-8 | Deployability | A person can run the whole system from a clean clone. | A clean-clone test (a teammate and a pipeline job) starts the application, the database and the mock billers with docker compose and the health check answers OK; the steps are in the README. | Must |

## Questions, Ambiguities and Decisions

The questions the AI asked, the ambiguities found in the brief and in the user stories, and the decision taken for each.

| **#** | **Question or ambiguity** | **Raised by (team / AI)** | **Decision made** | **Affects** |
| --- | --- | --- | --- | --- |
| 1 | FR-2: What is the verification process that upgrades a customer from Basic to Verified? | Team | It is simulated in this project. Only an admin upgrades a customer, after a simulated identity check; a customer cannot upgrade themselves. | FR-2, US #2 |
| 2 | FR-7: What exactly are the required input fields of each biller? | Team | They are stored in the configuration of each service. ElectroCo: meter number. TopUpNet: phone number. AquaCo: water account number. NetCo: subscriber number. (The brief fixes only the ElectroCo field; the others are the team’s choice.) | FR-6, FR-7, US #6, #7 |
| 3 | FR-8 / FR-10: What are the scope and the validity period of an idempotency key? | Team | The client generates the key (a UUID). It is unique per customer and valid for 24 hours. The same key with a different amount or content is rejected as a conflict. | FR-10, US #10 |
| 4 | FR-11: Is the move from Failed to Refunded automatic? (The allowed transitions themselves are fixed by the brief, section 2.5.) | AI | Yes. When the biller refuses, the hold is released and the payment becomes Refunded without any request. A payment in Unknown is never refunded automatically. | FR-11, FR-12, US #11, #13 |
| 5 | FR-13: From when are the re-queries of an Unknown payment counted (after 1, 5 and 15 minutes)? | Team | From the moment the payment became Unknown. The schedule is stored in the database so that it survives a restart. | FR-13, US #14 |
| 6 | FR-21: When does a support employee block or unblock an account? | Team | On suspected fraud, a lost phone or stolen credentials, or during an investigation; unblock when the case is cleared. A reason is mandatory for both actions. A block stops new payments only; payments already in progress continue. | FR-21, US #22 |
| 7 | FR-24: Which values can an admin edit, and from when do they apply? | Team | Fees, limits (single payment and daily), the velocity rule, the commission rate and the promotion dates. Only an admin can edit them; new values apply to the next payments. | FR-24, US #25 |
| 8 | FR-27: What are the conditions to accept a refund request, and is the refund full or partial? | Team | The payment is Completed, belongs to the customer, is not older than 30 days and has no other refund request; a reason is given. The refund is full only (payment amount and fee); partial refunds are postponed. | FR-27, US #28 |
| 9 | FR-16 / US #17: What is the rounding rule when a fee has more than two decimals? | Team | ROUND_HALF_UP to two decimals with exact decimal types. For example 1.5% of 150.50 = 2.2575, which becomes 2.26. | FR-16, US #17 |
| 10 | US #13 and US #28: “Refund” is used for two different things. | AI | Hold release after a failed payment (payment state Refunded) is kept apart from a refund request for a Completed payment (the payment stays Completed). The definitions are updated. | FR-12, FR-27, US #13, #28 |
| 11 | US #23 and US #24: which notification channels are used? | AI | SMS and push are the notification channels (FR-22). Email is not built in this version. The retry rule (3 times, then Undelivered) applies on each channel separately. The scope and the stakeholders name only SMS and push providers. | FR-22, FR-23, US #23, #24 |
| 12 | US #20: does the velocity rule count payment attempts or only completed payments? | AI | It counts all payment attempts submitted in the last 60 seconds, including rejected ones and excluding repeated requests with the same idempotency key. The sixth attempt is rejected and the account is blocked for 10 minutes. | FR-19, US #20 |
| 13 | US #18: which wallet is charged when an agent pays on behalf of a customer? | AI | The customer’s wallet, identified by the customer’s phone number and confirmed with a simulated OTP. | FR-17, US #18 |
| 14 | US #1 and FR-25: the registration was written to the audit log, but FR-25 covers only money movements and admin actions. | AI | The registration is not audited, and US #1 no longer writes an audit record. “Admin actions” include the actions of support employees (block, unblock, refund decisions). | FR-1, FR-25, NFR-5, US #1, #22, #26 |
| 15 | Daily limit: which period counts, and which payments are added up? | AI | The calendar day in Cairo time. Payments that are Completed, FundsHeld, SentToBiller or Unknown count, using the payment total (amount and fee). Failed, Rejected and Refunded payments do not count. | FR-18, US #19 |
| 16 | Minimum and maximum single payment (5 and 10,000 EGP): do they apply to the bill amount or to the total with the fee? | AI | To the bill amount (without the fee). | FR-18, US #19 |
| 17 | Can a customer pay only a part of a bill? | AI | No. The customer pays the full amount due that the inquiry returned. | FR-9, US #9 |
| 18 | How long is the result of a bill inquiry valid? | AI | 10 minutes. After that a new inquiry is needed before paying. | FR-8, FR-9, US #8, #9 |
| 19 | Does the velocity rule apply to agent accounts, who may serve many customers? | AI | Yes, it applies to every account, and its values are configurable by an admin (FR-24). | FR-19, FR-24, US #20 |
| 20 | Who creates agent, admin and support accounts? (FR-1 covers customers only.) | AI | An admin creates them; they are not created through public registration. | FR-1, FR-6 |
| 21 | Agent cash top-up: is the agent’s wallet debited, and is a commission paid? | AI | No. The customer’s wallet is credited and the agent’s identity is audited. No agent wallet debit and no commission on top-ups in this version. | FR-4, US #4 |
| 22 | Commission when the fee is 0 (promotion), and rounding of the commission. | AI | The commission is 0 when the fee is 0. Otherwise it is 40% of the fee, rounded half-up to two decimals (for example 40% of 2.26 = 0.904, which becomes 0.90). | FR-16, FR-17, US #18 |
| 23 | Are customers notified when a payment is Rejected or Unknown? (FR-22 covers Completed and Failed.) | AI | A rejection reason is shown immediately in the response, with no SMS or push. For Unknown the customer is told on screen that the payment is being processed and is notified when it ends as Completed or Failed. | FR-22, US #14, #23 |
| 24 | Reconciliation: which payments belong to a settlement file (cut-off time)? | AI | Payments made up to 23:59:59 Cairo time of the settlement day. Later payments belong to the next day’s file. | FR-26, US #27 |
| 25 | For how long do the funds of an Unknown payment stay held? | AI | Until a callback, a re-query or the reconciliation resolves the payment. Held funds are not available to spend but count in the daily limit. | FR-13, US #14 |
| 26 | How do users log in, and which roles exist? | AI | Token-based authentication (for example JWT) with the roles Customer, Agent, Support employee and Admin. | NFR-7 |

## Enriched User Stories

The 29 user stories below cover all 28 functional requirements. Each story has acceptance criteria in Given / When / Then form, a normal scenario and an exceptional scenario. The hard cases of the project brief are marked in the field “Hard case”.

### User Story #1

| Field | Value |
| --- | --- |
| **User Story ID** | US #1 |
| **User Story Name** | Customer registration |
| **Actors** | Customer |
| **Requirement** | FR-1 |
| **Priority** | Must |
| **Hard case** | — |
| **Description** | As a new customer<br>I’d like to register an account with my personal details<br>So that I get a wallet and can start paying bills |
| **Pre condition** | The phone number and email address are not already registered. |
| **Post condition** | A customer account exists with verification level Basic and a wallet with a zero balance. |
| **Acceptance Criteria** | Given I am a new customer on the registration screen<br>When I submit a valid name, phone number, email address and password<br>Then the system creates my account with verification level “Basic” and an empty wallet<br><br>Given a phone number or email address is already registered<br>When I submit the registration form<br>Then the system rejects it, creates no second account, and tells me the account already exists |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- User opens the registration screen |  |
|  | 2- System displays the registration form (name, phone number, email, password) |
| 3- User fills in the fields and submits |  |
|  | 4- System validates the data and checks that the phone number and email are not in use |
|  | 5- System creates the customer (level Basic) and a wallet with a zero balance |
|  | 6- System confirms the registration |

**Exceptional Scenario – Invalid or duplicate data**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- User submits the form with an invalid field or an already registered phone number or email |  |
|  | 2- System rejects the request and creates nothing |
|  | 3- System shows a clear error message |

### User Story #2

| Field | Value |
| --- | --- |
| **User Story ID** | US #2 |
| **User Story Name** | Upgrade a customer to Verified |
| **Actors** | Admin, Customer |
| **Requirement** | FR-2 |
| **Priority** | Should |
| **Hard case** | — |
| **Description** | As an admin<br>I’d like to upgrade a customer from Basic to Verified<br>So that the customer gets the higher daily payment limit (30,000 EGP instead of 5,000 EGP) |
| **Pre condition** | The admin is logged in; the customer exists with level Basic; the identity check has been completed (simulated in this project). |
| **Post condition** | The customer’s level is Verified and the Verified limits apply to the next payment; the change is audited (who, when, why). |
| **Acceptance Criteria** | Given a customer has level Basic and a daily limit of 5,000 EGP<br>When an admin upgrades the customer to Verified<br>Then the level becomes Verified and the customer’s next payment is checked against the 30,000 EGP daily limit<br><br>Given a customer is already Verified<br>When an admin tries to upgrade the same customer again<br>Then the system makes no change and tells the admin the customer is already Verified |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Admin searches for the customer |  |
|  | 2- System displays the customer profile with the current level |
| 3- Admin chooses “Upgrade to Verified” and enters a reason |  |
|  | 4- System checks that the customer is Basic and that a reason was given |
|  | 5- System sets the level to Verified and writes an audit record |
|  | 6- System confirms the change |

**Exceptional Scenario – Customer already Verified**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Admin chooses “Upgrade to Verified” for a Verified customer |  |
|  | 2- System makes no change and informs the admin |

### User Story #3

| Field | Value |
| --- | --- |
| **User Story ID** | US #3 |
| **User Story Name** | View wallet balance and history |
| **Actors** | Customer |
| **Requirement** | FR-3 |
| **Priority** | Must |
| **Hard case** | — |
| **Description** | As a customer<br>I’d like to see my available balance, my held balance and my transaction history<br>So that I know how much I can spend and where my money went |
| **Pre condition** | The customer is logged in and has a wallet. |
| **Post condition** | No data is changed. |
| **Acceptance Criteria** | Given my wallet has an available balance of 647.50 EGP and a held balance of 352.50 EGP<br>When I open my wallet<br>Then the system shows both amounts with two decimal places<br><br>Given I have made transactions<br>When I open my transaction history<br>Then the system lists my entries newest first, each with date, type, amount and reference |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer opens the wallet screen |  |
|  | 2- System computes the available and held balances from the ledger entries |
|  | 3- System displays both balances |
| 4- Customer opens the transaction history |  |
|  | 5- System lists the ledger entries newest first, page by page |

**Exceptional Scenario – New wallet without transactions**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer opens the wallet screen of a new account |  |
|  | 2- System shows zero balances and a message that there are no transactions yet |

### User Story #4

| Field | Value |
| --- | --- |
| **User Story ID** | US #4 |
| **User Story Name** | Top up the wallet |
| **Actors** | Customer, Agent |
| **Requirement** | FR-4 |
| **Priority** | Must |
| **Hard case** | — |
| **Description** | As a customer<br>I’d like to top up my wallet with a simulated card or with cash through an agent<br>So that I have money available to pay bills |
| **Pre condition** | The customer is logged in and has a wallet; for agent cash, an agent is available to receive the cash. |
| **Post condition** | A credit ledger entry exists and the available balance has increased by the top-up amount; the top-up is audited. |
| **Acceptance Criteria** | Given my available balance is 100.00 EGP<br>When I top up 200.00 EGP with a simulated card that is accepted<br>Then my available balance becomes 300.00 EGP and one top-up entry of +200.00 EGP appears in my ledger<br><br>Given the simulated card is declined<br>When I try to top up 200.00 EGP<br>Then my balance does not change, no ledger entry is created, and I see the reason for the decline<br><br>Given an agent has received 200.00 EGP cash from me<br>When the agent confirms the top-up for my wallet<br>Then my available balance increases by 200.00 EGP and the agent’s identity is recorded in the audit log |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer chooses “Top up”, selects the method (simulated card or agent cash) and enters the amount |  |
|  | 2- System validates that the amount is greater than zero |
|  | 3- System processes the simulated card payment, or records the agent’s cash confirmation |
|  | 4- System appends a credit entry to the wallet ledger and writes an audit record |
|  | 5- System shows the new available balance |

**Exceptional Scenario – Card declined**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Simulated card provider declines the charge |  |
|  | 2- System creates no ledger entry and leaves the balance unchanged |
|  | 3- System shows the reason for the decline |

### User Story #5

| Field | Value |
| --- | --- |
| **User Story ID** | US #5 |
| **User Story Name** | Ledger entry for every balance change |
| **Actors** | System (Wallet module) |
| **Requirement** | FR-5 |
| **Priority** | Must |
| **Hard case** | — |
| **Description** | As PayLink management<br>I’d like every balance change to be recorded as a ledger entry and every balance to be computed from the ledger<br>So that each balance can be explained and no balance is ever overwritten |
| **Pre condition** | A wallet exists. |
| **Post condition** | Each balance change has its own ledger entry; the balance equals the sum of the entries; no entry has been edited or deleted. |
| **Acceptance Criteria** | Given a wallet has ledger entries of +300.00 EGP (top-up) and −100.00 EGP (charge)<br>When the balance is requested<br>Then the balance is 200.00 EGP, the sum of its entries<br><br>Given any operation changes a balance (top-up, hold, release, charge, fee, commission or refund)<br>When the operation completes<br>Then a new ledger entry is added and no existing entry is changed or deleted |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Another module requests a money movement (top-up, hold, release, charge, fee, commission or refund) |  |
|  | 2- System validates the movement |
|  | 3- System appends a ledger entry (wallet, type, amount, reference, time) in the same database transaction as the business change |
|  | 4- System computes the new balance as the sum of the entries |

**Exceptional Scenario – Ledger entry cannot be saved**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Another module requests a money movement |  |
|  | 2- System fails to save the ledger entry |
|  | 3- System rolls back the whole transaction, so no balance changes, and logs the error |

### User Story #6

| Field | Value |
| --- | --- |
| **User Story ID** | US #6 |
| **User Story Name** | Manage billers and services |
| **Actors** | Admin |
| **Requirement** | FR-6 |
| **Priority** | Must |
| **Hard case** | — |
| **Description** | As an admin<br>I’d like to add, edit and disable billers and their services<br>So that the catalog is always correct |
| **Pre condition** | The admin is logged in. |
| **Post condition** | The catalog changes are saved; a disabled biller can no longer receive new payments; every change is audited. |
| **Acceptance Criteria** | Given I am logged in as an admin<br>When I add the biller “ElectroCo” with the service “Electricity”, the required field “meter number” and limits of 5 and 10,000 EGP<br>Then the biller and its service are saved and appear in the catalog<br><br>Given a biller is active<br>When I disable it<br>Then it no longer appears in the customers’ list, new payments to it are rejected with a clear reason, and payments already in progress are not affected |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Admin opens biller management |  |
|  | 2- System lists the billers and their services |
| 3- Admin chooses to add, edit or disable a biller or service |  |
|  | 4- System shows the form (name, service type, required input fields, minimum and maximum amount, status) |
| 5- Admin fills in the form and saves |  |
|  | 6- System validates the data, saves it and writes an audit record |

**Exceptional Scenario – Invalid data**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Admin saves a service whose minimum amount is higher than its maximum, or with a missing required field |  |
|  | 2- System rejects the change and shows what must be corrected |

### User Story #7

| Field | Value |
| --- | --- |
| **User Story ID** | US #7 |
| **User Story Name** | View billers and required input fields |
| **Actors** | Customer |
| **Requirement** | FR-7 |
| **Priority** | Must |
| **Hard case** | — |
| **Description** | As a customer<br>I’d like to see the available billers and the information each one needs<br>So that I know what to enter before paying |
| **Pre condition** | The customer is logged in. |
| **Post condition** | No data is changed. |
| **Acceptance Criteria** | Given active billers exist in the catalog<br>When I open the list of billers<br>Then I see only active billers, grouped by service<br><br>Given I select the Electricity service of ElectroCo<br>When the details are shown<br>Then the system shows the required field “meter number” and the minimum and maximum amount |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer opens “Pay bills” |  |
|  | 2- System shows the active billers grouped by service type |
| 3- Customer selects a service |  |
|  | 4- System shows the required input fields (for example meter number or phone number) and the allowed amount range |

**Exceptional Scenario – No active biller**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer opens a service type that has no active biller |  |
|  | 2- System shows that the service is currently unavailable |

### User Story #8

| Field | Value |
| --- | --- |
| **User Story ID** | US #8 |
| **User Story Name** | Bill inquiry with amount, fee and total |
| **Actors** | Customer, Biller |
| **Requirement** | FR-8, FR-16 |
| **Priority** | Must |
| **Hard case** | — |
| **Description** | As a customer<br>I’d like to run a bill inquiry and see the amount, the fee and the total before paying<br>So that I know exactly what I will be charged |
| **Pre condition** | The customer is logged in; a biller and a service are selected; the biller is active. |
| **Post condition** | The inquiry result is shown; no money is moved. |
| **Acceptance Criteria** | Given I selected ElectroCo and entered a valid meter number<br>When I request a bill inquiry<br>Then the system shows an amount due of 350.00 EGP, a fee of 2.50 EGP and a total of 352.50 EGP<br><br>Given I entered a meter number that does not exist<br>When I request a bill inquiry<br>Then the system shows that no bill was found and I cannot start a payment |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer enters the required fields (for example the meter number) and requests an inquiry |  |
|  | 2- System checks that all required fields are filled |
|  | 3- System sends the inquiry to the biller through its integration |
| 4- Biller answers with the amount due |  |
|  | 5- System calculates the service fee with the fee rules |
|  | 6- System shows the amount, the fee and the total |

**Exceptional Scenario – Biller does not answer**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Biller does not answer within the timeout |  |
|  | 2- System creates no payment and shows that the service is temporarily unavailable |
|  | 3- System suggests trying again later |

### User Story #9

| Field | Value |
| --- | --- |
| **User Story ID** | US #9 |
| **User Story Name** | Pay a bill from the wallet |
| **Actors** | Customer |
| **Requirement** | FR-9 |
| **Priority** | Must |
| **Hard case** | — |
| **Description** | As a customer<br>I’d like to pay a bill from my wallet<br>So that I do not have to queue at the biller’s office |
| **Pre condition** | The customer is logged in and has completed a bill inquiry (valid for 10 minutes); the payment is for the full amount due; the total is inside the allowed limits. |
| **Post condition** | The payment has followed its life cycle; if it completed, the wallet is charged the total, PayLink’s fee income is credited and a receipt is sent. |
| **Acceptance Criteria** | Given my available balance is 1,000.00 EGP and the inquiry total is 352.50 EGP<br>When I confirm the payment and the biller confirms it<br>Then the payment is Completed, 352.50 EGP is charged (available balance 647.50 EGP, nothing left on hold), PayLink’s fee income is credited 2.50 EGP and I receive a receipt<br><br>Given my available balance is 100.00 EGP and the total is 352.50 EGP<br>When I confirm the payment<br>Then the payment is Rejected, no money is moved and I am told that my balance is not enough |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer confirms the payment |  |
|  | 2- System creates the payment (state Initiated) with a unique reference |
|  | 3- System runs the fraud checks and checks the balance |
|  | 4- System holds the total (state FundsHeld) and sends the payment to the biller (state SentToBiller) |
| 5- Biller confirms the payment |  |
|  | 6- System sets the state to Completed, turns the hold into a final charge and credits the fee income |
|  | 7- System sends the notifications and shows the receipt |

**Exceptional Scenario – Fraud check fails or funds are insufficient**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer confirms the payment |  |
|  | 2- System finds a failed fraud check or insufficient funds |
|  | 3- System sets the payment to Rejected, holds nothing and shows the reason |

### User Story #10

| Field | Value |
| --- | --- |
| **User Story ID** | US #10 |
| **User Story Name** | Repeated request with the same idempotency key |
| **Actors** | Customer (mobile app) |
| **Requirement** | FR-10 |
| **Priority** | Must |
| **Hard case** | HC 1 |
| **Description** | As a customer on a slow network<br>I’d like to be able to send the same payment request again safely<br>So that I am never charged twice for one payment |
| **Pre condition** | A payment request with idempotency key K has been received; the key is unique per customer and valid for 24 hours. |
| **Post condition** | Exactly one payment and one charge exist for key K. |
| **Acceptance Criteria** | Given I sent a payment with key K and the answer did not reach my app<br>When the app sends the same request again with key K<br>Then the system returns the result of the first request and creates no second payment<br><br>Given key K was already used for a payment of 352.50 EGP<br>When a request with key K but a different amount arrives<br>Then the system rejects it as a conflict and changes nothing |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- App sends a payment request with idempotency key K |  |
|  | 2- System stores key K together with the new payment and processes it |
| 3- Network is slow, so the app sends the same request again with key K |  |
|  | 4- System finds key K and recognises the request |
|  | 5- System returns the stored result of the first request without processing again |

**Exceptional Scenario – Both requests arrive at the same moment**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- App sends two requests with the same key K at the same moment |  |
|  | 2- System processes only one of them |
|  | 3- System answers both with the same result |

### User Story #11

| Field | Value |
| --- | --- |
| **User Story ID** | US #11 |
| **User Story Name** | Enforce the payment life cycle |
| **Actors** | System (Payment Processing) |
| **Requirement** | FR-11 |
| **Priority** | Must |
| **Hard case** | — |
| **Description** | As PayLink management<br>I’d like a payment to move only along the allowed transitions<br>So that the state of every payment, and of the money behind it, is always predictable |
| **Pre condition** | A payment exists in one state. |
| **Post condition** | The payment state changed only along an allowed transition, and every transition is recorded with its time. |
| **Acceptance Criteria** | Given a payment is in state SentToBiller<br>When the biller confirms it<br>Then the state becomes Completed<br><br>Given a payment is in state Completed<br>When an event tries to move it to Failed<br>Then the system refuses the transition, the payment stays Completed and the attempt is logged<br><br>Given a payment is in state Unknown and the biller has not answered yet<br>When time passes<br>Then no refund is created automatically |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Another component sends an event for a payment (for example “biller confirms”) |  |
|  | 2- System compares the current state and the event with the allowed transitions of the payment life cycle |
|  | 3- System applies the transition and records the new state with its time |
|  | 4- System starts the follow-up action of the new state |

**Exceptional Scenario – Transition not allowed**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Another component sends an event that is not allowed in the current state |  |
|  | 2- System rejects the event, keeps the state and logs the attempt |

### User Story #12

| Field | Value |
| --- | --- |
| **User Story ID** | US #12 |
| **User Story Name** | Hold funds before calling the biller |
| **Actors** | Customer, System |
| **Requirement** | FR-12 |
| **Priority** | Must |
| **Hard case** | HC 4 |
| **Description** | As a customer<br>I’d like the money of my payment to be held before the biller is called<br>So that the money is reserved for my payment and cannot be spent twice |
| **Pre condition** | The payment is in state Initiated and the fraud checks passed. |
| **Post condition** | The total has moved from the available to the held balance before any request reaches the biller; the balance is never negative. |
| **Acceptance Criteria** | Given my available balance is 500.00 EGP and the total is 352.50 EGP<br>When the payment starts<br>Then my available balance becomes 147.50 EGP and my held balance 352.50 EGP before the biller request is sent<br><br>Given my available balance is 400.00 EGP and two payments of 352.50 EGP arrive at the same moment<br>When both are processed<br>Then exactly one payment reaches FundsHeld, the other is Rejected, and the balance never goes below zero |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer confirms a payment |  |
|  | 2- System checks that the available balance covers the total |
|  | 3- System moves the total from available to held in one atomic operation and writes the ledger entries |
|  | 4- System sets the state to FundsHeld |
|  | 5- System continues with the call to the biller |

**Exceptional Scenario – Not enough funds, or the other payment won the race**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Two payments from the same wallet arrive at the same moment |  |
|  | 2- System holds the funds for the first payment |
|  | 3- System finds the balance too low for the second and sets it to Rejected without any hold |

### User Story #13

| Field | Value |
| --- | --- |
| **User Story ID** | US #13 |
| **User Story Name** | Failed payment: release the hold and tell the customer why |
| **Actors** | Customer, Biller, System |
| **Requirement** | FR-12, FR-22 |
| **Priority** | Must |
| **Hard case** | HC 3 |
| **Description** | As a customer<br>I’d like my money to come back and to be told the reason when a biller refuses my payment<br>So that I do not lose money and I understand what went wrong |
| **Pre condition** | The payment is in state SentToBiller and its funds are held. |
| **Post condition** | The payment is Failed and then Refunded; the hold is released to the available balance; an SMS and a push message with the reason have been sent. |
| **Acceptance Criteria** | Given I paid a water bill through AquaCo and AquaCo answers with an error code<br>When the system receives the refusal<br>Then the payment becomes Failed, the hold is released to my wallet (payment Refunded) and I receive an SMS and a push message with a clear reason<br><br>Given a failed payment is Refunded<br>When I open my wallet<br>Then my available balance equals the balance before the payment and the ledger shows the hold and the release |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- AquaCo refuses the payment with an error code |  |
|  | 2- System maps the biller-specific error code to a standard, readable reason |
|  | 3- System sets the payment to Failed |
|  | 4- System releases the hold to the available balance and sets the payment to Refunded |
|  | 5- System sends an SMS and a push message with the reason |
|  | 6- System shows the failure and its reason in the app |

**Exceptional Scenario – Release of the hold fails**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- The release of the hold fails because of a technical error |  |
|  | 2- System keeps the payment in Failed and does not mark it Refunded |
|  | 3- System retries the release and logs the problem for support |

### User Story #14

| Field | Value |
| --- | --- |
| **User Story ID** | US #14 |
| **User Story Name** | Timeout: payment becomes Unknown and is re-queried |
| **Actors** | Customer, Biller, System |
| **Requirement** | FR-13 |
| **Priority** | Must |
| **Hard case** | HC 2 |
| **Description** | As a customer<br>I’d like my payment to stay safe when the biller does not answer in time<br>So that I am neither charged for nothing nor refunded by mistake |
| **Pre condition** | The payment is in state SentToBiller for a live biller (10-second timeout). |
| **Post condition** | The payment is Unknown with its funds still held; re-queries are scheduled after 1, 5 and 15 minutes, counted from the moment the payment became Unknown and stored so that they survive a restart. |
| **Acceptance Criteria** | Given ElectroCo takes 12 seconds to answer<br>When the 10-second timeout passes<br>Then the payment becomes Unknown, the money stays held and I am told that the payment is being processed<br><br>Given a payment is Unknown<br>When the system re-queries the biller after 1, 5 and 15 minutes<br>Then a confirmation moves it to Completed, a refusal moves it to Failed, and if the third requery gives no answer it waits for reconciliation with no refund |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer confirms a payment to ElectroCo |  |
|  | 2- System sends the payment to ElectroCo and starts the 10-second timer |
| 3- ElectroCo does not answer within 10 seconds |  |
|  | 4- System sets the payment to Unknown and keeps the funds held |
|  | 5- System tells the customer that the payment is being processed |
|  | 6- System re-queries the biller after 1, 5 and 15 minutes |
| 7- ElectroCo confirms the payment at one of the re-queries |  |
|  | 8- System sets the payment to Completed and notifies the customer |

**Exceptional Scenario – No answer after all three re-queries**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- ElectroCo still gives no answer at the third re-query |  |
|  | 2- System keeps the payment Unknown with the funds held |
|  | 3- System leaves the payment to the nightly reconciliation and creates no refund |

### User Story #15

| Field | Value |
| --- | --- |
| **User Story ID** | US #15 |
| **User Story Name** | Asynchronous callback from TopUpNet |
| **Actors** | TopUpNet, System |
| **Requirement** | FR-14 |
| **Priority** | Must |
| **Hard case** | HC 6 |
| **Description** | As PayLink<br>I’d like to accept the callback of TopUpNet and to ignore duplicates<br>So that a mobile top-up is completed exactly once |
| **Pre condition** | The payment to TopUpNet was accepted and is in state SentToBiller. |
| **Post condition** | The payment is Completed or Failed exactly once; duplicate callbacks are ignored and logged. |
| **Acceptance Criteria** | Given TopUpNet has replied “accepted” to my top-up<br>When TopUpNet calls the callback URL with “success”<br>Then the payment becomes Completed and I am notified<br><br>Given the payment is already Completed<br>When TopUpNet calls the callback again with “success”<br>Then the second callback is ignored, nothing changes and the event is logged<br><br>Given TopUpNet has replied “accepted”<br>When TopUpNet calls the callback with “failed”<br>Then the payment becomes Failed and the hold is released |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- TopUpNet replies “accepted” to the payment request |  |
|  | 2- System keeps the payment in SentToBiller with the funds held |
| 3- TopUpNet calls the callback URL with “success” some minutes later |  |
|  | 4- System checks that the callback belongs to a known payment |
|  | 5- System sets the payment to Completed, finalises the charge and notifies the customer |

**Exceptional Scenario – Duplicate callback**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- TopUpNet sends the “success” callback a second time |  |
|  | 2- System sees that the payment is already in a final state |
|  | 3- System ignores the callback, logs it and acknowledges it |

### User Story #16

| Field | Value |
| --- | --- |
| **User Story ID** | US #16 |
| **User Story Name** | Support several billers and add a new one |
| **Actors** | Development team, System |
| **Requirement** | FR-15 |
| **Priority** | Must |
| **Hard case** | HC 8 |
| **Description** | As a member of the development team<br>I’d like each biller to be integrated through its own adapter behind one common interface<br>So that a new biller needs only a new adapter and configuration |
| **Pre condition** | The contract of the biller (protocol, fields, error codes) is available. |
| **Post condition** | The new biller works for customers; no existing module has been changed. |
| **Acceptance Criteria** | Given adapters exist for ElectroCo (REST/JSON), AquaCo (XML over HTTP) and TopUpNet (asynchronous REST/JSON)<br>When a payment is made to each of them<br>Then each payment is processed in the format of its biller while Payment Processing uses one common interface<br><br>Given a new biller has to be added<br>When the team adds an adapter and its configuration<br>Then payments to the new biller work and no file outside the Biller Integration module and the configuration has changed |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Developer writes an adapter that implements the common biller interface |  |
| 2- Developer adds the configuration of the biller (address, timeout, field mapping) |  |
|  | 3- System registers the adapter by biller code |
|  | 4- System shows the new biller in the catalog |
| 5- Customer pays a bill of the new biller |  |
|  | 6- System uses the new adapter; all other modules are unchanged |

**Exceptional Scenario – No adapter registered**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer pays a bill of a biller that has a catalog entry but no adapter |  |
|  | 2- System rejects the payment with “biller not supported” and holds no funds |

### User Story #17

| Field | Value |
| --- | --- |
| **User Story ID** | US #17 |
| **User Story Name** | Calculate the service fee |
| **Actors** | Customer, System (Fees module) |
| **Requirement** | FR-16 |
| **Priority** | Must |
| **Hard case** | — |
| **Description** | As a customer<br>I’d like the fee to be calculated correctly for each kind of bill<br>So that I know the total before I pay |
| **Pre condition** | The service and the amount of the bill are known. |
| **Post condition** | A fee with exactly two decimals, rounded half-up, is returned; money values use exact decimal types. |
| **Acceptance Criteria** | Given I pay an electricity or water bill of 350.00 EGP<br>When the fee is calculated<br>Then the fee is 2.50 EGP<br><br>Given I top up a mobile with 100.00 EGP, or with 20.00 EGP<br>When the fee is calculated<br>Then the fee is 1.50 EGP for 100.00 EGP and 1.00 EGP for 20.00 EGP (1.5% with a minimum of 1 EGP)<br><br>Given I top up a mobile with 150.50 EGP, 123.45 EGP or 333.33 EGP<br>When the fee is calculated<br>Then the fee is 2.26 EGP (2.2575), 1.85 EGP (1.85175) and 5.00 EGP (4.99995), because the result is rounded half-up to two decimals<br><br>Given I pay an internet bill of 150.00 EGP, of 200.00 EGP, or of 300.00 EGP<br>When the fee is calculated<br>Then the fee is 2.00 EGP, 2.00 EGP and 4.00 EGP<br><br>Given a promotion with a start and an end date is active for one biller<br>When I pay a bill of that biller inside the period<br>Then the fee is 0.00 EGP; outside the period the normal fee applies |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer requests an inquiry or a payment |  |
|  | 2- System receives the service type, the amount and the date |
|  | 3- System selects the fee rule of the service (fixed, percentage or tiered) |
|  | 4- System checks whether a promotion is active for the biller on that date |
|  | 5- System calculates the fee with exact decimals, rounds it half-up to two decimals and returns it |

**Exceptional Scenario – Promotion period over**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer pays a bill of the promoted biller after the end date |  |
|  | 2- System ignores the promotion and applies the normal fee rule |

### User Story #18

| Field | Value |
| --- | --- |
| **User Story ID** | US #18 |
| **User Story Name** | Agent pays on behalf of a customer and earns commission |
| **Actors** | Agent, Customer |
| **Requirement** | FR-17 |
| **Priority** | Should |
| **Hard case** | — |
| **Description** | As an agent<br>I’d like to pay a bill on behalf of a customer at my terminal<br>So that customers without the app can pay and I earn my commission |
| **Pre condition** | The agent is logged in at a PayLink terminal; the wallet to charge is the customer’s wallet, identified by the customer’s phone number and confirmed with a simulated OTP. |
| **Post condition** | The payment is marked as made through the agent; on completion the agent’s wallet is credited the commission; the actions are audited. |
| **Acceptance Criteria** | Given an agent pays an electricity bill with a fee of 2.50 EGP for a customer<br>When the payment completes<br>Then the agent’s wallet is credited 1.00 EGP (40% of the fee) with a ledger entry<br><br>Given an agent’s payment fails<br>When the payment ends in Failed<br>Then no commission is credited |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Agent logs in and enters the customer’s phone number and the bill details |  |
|  | 2- System runs the bill inquiry and shows amount, fee and total |
|  | 3- System sends a simulated OTP to the customer to confirm the wallet |
| 4- Agent enters the OTP given by the customer and confirms the payment |  |
|  | 5- System processes the payment and records the agent on it |
|  | 6- System, when the payment completes, calculates 40% of the fee (rounded half-up) and credits the agent’s wallet |
|  | 7- System notifies the customer and shows the receipt to the agent |

**Exceptional Scenario – Payment does not complete**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- The payment is rejected or fails |  |
|  | 2- System credits no commission and shows the reason to the agent |

### User Story #19

| Field | Value |
| --- | --- |
| **User Story ID** | US #19 |
| **User Story Name** | Reject payments above the limits |
| **Actors** | Customer |
| **Requirement** | FR-18 |
| **Priority** | Must |
| **Hard case** | — |
| **Description** | As a customer<br>I’d like to be told clearly when a payment is above a limit<br>So that I understand why it was refused |
| **Pre condition** | The customer is logged in and has the level Basic or Verified. |
| **Post condition** | No funds are held; the payment is Rejected with a clear reason. |
| **Acceptance Criteria** | Given I am any customer<br>When I try to pay 4.00 EGP or 10,500.00 EGP<br>Then the payment is Rejected with the reason “below the minimum of 5 EGP” or “above the maximum of 10,000 EGP”<br><br>Given I am a Basic customer and I already paid 4,800.00 EGP today<br>When I try to pay 400.00 EGP<br>Then the payment is Rejected with the reason that the daily limit of 5,000 EGP would be exceeded<br><br>Given I am a Verified customer in the same situation<br>When I try to pay 400.00 EGP<br>Then the payment is accepted, because my daily limit is 30,000 EGP |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer confirms a payment of 10,500.00 EGP |  |
|  | 2- System checks the amount against the minimum and maximum of a single payment |
|  | 3- System finds the amount above 10,000 EGP and sets the payment to Rejected |
|  | 4- System holds no funds |
|  | 5- System shows the reason to the customer |

**Exceptional Scenario – Daily limit exceeded**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Basic customer who already paid 4,800.00 EGP today confirms a payment of 400.00 EGP |  |
|  | 2- System adds the payments of the day and finds the 5,000 EGP limit exceeded |
|  | 3- System sets the payment to Rejected and shows the reason |

### User Story #20

| Field | Value |
| --- | --- |
| **User Story ID** | US #20 |
| **User Story Name** | Block an account after too many payments |
| **Actors** | Customer, System (Fraud checks) |
| **Requirement** | FR-19 |
| **Priority** | Should |
| **Hard case** | — |
| **Description** | As PayLink<br>I’d like an account that makes more than 5 payments in 60 seconds to be blocked for 10 minutes<br>So that automated or fraudulent bursts of payments are stopped |
| **Pre condition** | The account is active. |
| **Post condition** | The account is blocked for 10 minutes and its payments are Rejected during that time; afterwards it can pay again. |
| **Acceptance Criteria** | Given an account has made 5 payments within 60 seconds<br>When it attempts a sixth payment inside the same 60 seconds<br>Then the sixth payment is Rejected and the account is blocked for 10 minutes<br><br>Given an account was blocked at 12:00<br>When it attempts a payment at 12:05 and another at 12:11<br>Then the payment at 12:05 is Rejected with the reason and the payment at 12:11 passes this check |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer submits a payment |  |
|  | 2- System counts the payments submitted by the account in the last 60 seconds (rejected ones included, repeated requests with the same idempotency key excluded) |
|  | 3- System finds that this would be the sixth and rejects the payment |
|  | 4- System blocks the account for 10 minutes and logs it |
|  | 5- System tells the customer when the block ends |

**Exceptional Scenario – Block expires**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer submits a payment after the 10 minutes have passed |  |
|  | 2- System has removed the block automatically and continues with the normal checks |

### User Story #21

| Field | Value |
| --- | --- |
| **User Story ID** | US #21 |
| **User Story Name** | Search a payment by reference |
| **Actors** | Support employee |
| **Requirement** | FR-20 |
| **Priority** | Must |
| **Hard case** | — |
| **Description** | As a support employee<br>I’d like to search a payment by its reference and see its full history<br>So that I can answer customers’ questions |
| **Pre condition** | The support employee is logged in. |
| **Post condition** | No data is changed. |
| **Acceptance Criteria** | Given a payment with reference R exists<br>When I search for R<br>Then I see its customer, biller, amount, fee, current state and the complete history of state changes with their times<br><br>Given no payment has reference R2<br>When I search for R2<br>Then the system shows that no payment was found |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Support employee enters a payment reference |  |
|  | 2- System finds the payment |
|  | 3- System displays the summary (customer, biller, amount, fee, state) |
|  | 4- System displays the history: state changes, ledger entries, biller answers and notifications |

**Exceptional Scenario – Reference not found**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Support employee enters a reference that does not exist |  |
|  | 2- System shows “no payment found” |

### User Story #22

| Field | Value |
| --- | --- |
| **User Story ID** | US #22 |
| **User Story Name** | Block and unblock an account |
| **Actors** | Support employee |
| **Requirement** | FR-21 |
| **Priority** | Should |
| **Hard case** | — |
| **Description** | As a support employee<br>I’d like to block and unblock an account<br>So that I can stop suspicious activity and restore a customer’s access |
| **Pre condition** | The support employee is logged in and the account exists. |
| **Post condition** | The account status is Blocked or Active; the action is audited with who, when and why. |
| **Acceptance Criteria** | Given an account is active<br>When I block it and enter a reason<br>Then its status is Blocked, its new payments are Rejected and an audit record is written<br><br>Given an account is blocked<br>When I unblock it and enter a reason<br>Then its status is Active, it can pay again and an audit record is written |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Support employee opens the account |  |
|  | 2- System shows the account and its status |
| 3- Support employee chooses Block (or Unblock) and enters a reason |  |
|  | 4- System changes the status and writes an audit record |
|  | 5- System confirms the change |

**Exceptional Scenario – Reason missing**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Support employee chooses Block or Unblock without a reason |  |
|  | 2- System refuses the action and asks for a reason |

### User Story #23

| Field | Value |
| --- | --- |
| **User Story ID** | US #23 |
| **User Story Name** | Notify the customer on completion and failure |
| **Actors** | Customer, System (Notifications), SMS and push providers |
| **Requirement** | FR-22 |
| **Priority** | Must |
| **Hard case** | — |
| **Description** | As a customer<br>I’d like to receive an SMS and a push message when my payment completes or fails<br>So that I have a receipt and know the result |
| **Pre condition** | A payment has reached the state Completed or Failed. |
| **Post condition** | An SMS and a push message built from message templates have been sent for the payment. |
| **Acceptance Criteria** | Given a payment becomes Completed<br>When the state change happens<br>Then I receive an SMS and a push message with biller, amount, fee, total and reference<br><br>Given a payment becomes Failed<br>When the state change happens<br>Then I receive an SMS and a push message with a clear reason and the information that my money was returned |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Payment reaches the state Completed or Failed |  |
|  | 2- System builds the SMS and push messages from the message templates |
|  | 3- System sends both messages through their channels |
| 4- Provider accepts the messages |  |
|  | 5- System records the notification status as Sent |

**Exceptional Scenario – A channel fails**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- SMS or push provider does not accept the message |  |
|  | 2- System keeps the payment state unchanged and continues as in “Retry failed notifications” |

### User Story #24

| Field | Value |
| --- | --- |
| **User Story ID** | US #24 |
| **User Story Name** | Retry failed notifications |
| **Actors** | System (Notifications), SMS provider, push provider |
| **Requirement** | FR-23 |
| **Priority** | Should |
| **Hard case** | HC 5 |
| **Description** | As PayLink<br>I’d like a failed notification (SMS or push) to be retried and finally marked as undelivered<br>So that customers are reached whenever possible and failures are visible |
| **Pre condition** | A payment has reached completed or failed, and at least one notification channel (SMS or push) has failed. |
| **Post condition** | The payment state remains unchanged; the message is Sent after a successful retry or Undelivered after 3 failed retries. |
| **Acceptance Criteria** | Given the SMS provider is down when a payment completes<br>When the payment completes<br>Then the payment stays Completed<br><br>Given sending an SMS or a push message fails<br>When the system retries<br>Then it retries 3 times on that channel and, if all fail, marks the message Undelivered<br><br>Given a retry succeeds<br>When the provider accepts the message<br>Then the message is marked Sent and no more retries are made |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Payment completes while the SMS provider is down |  |
|  | 2- System keeps the payment Completed |
|  | 3- System tries to send the SMS and the provider fails |
|  | 4- System retries the SMS up to 3 times |
|  | 5- System marks the message Undelivered and logs it after the third failure |

**Exceptional Scenario – A retry succeeds**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- SMS provider accepts the message at a retry |  |
|  | 2- System marks the message Sent and stops retrying |

### User Story #25

| Field | Value |
| --- | --- |
| **User Story ID** | US #25 |
| **User Story Name** | Edit fee and limit values without redeploying |
| **Actors** | Admin |
| **Requirement** | FR-24 |
| **Priority** | Should |
| **Hard case** | — |
| **Description** | As an admin<br>I’d like to change fee and limit values in the running system<br>So that business rules can change without a new deployment |
| **Pre condition** | The admin is logged in. Editable values: fees, limits (single payment and daily), the velocity rule, the commission rate and the promotion dates; only an admin can edit them. |
| **Post condition** | The new values are stored and used for the next payments; the change is audited with the old and new value. |
| **Acceptance Criteria** | Given the daily limit of Basic accounts is 5,000 EGP<br>When an admin changes it to 6,000 EGP<br>Then the next payment of a Basic account is checked against 6,000 EGP without a restart or a redeploy<br><br>Given an admin enters an invalid value (for example a negative fee or a minimum above the maximum)<br>When the admin saves<br>Then the system rejects it and keeps the old value |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Admin opens the configuration screen |  |
|  | 2- System shows the current fee and limit values |
| 3- Admin changes a value and saves |  |
|  | 4- System validates the new value |
|  | 5- System stores it and writes an audit record with the old and the new value |
|  | 6- System applies the value to all following payments |

**Exceptional Scenario – Invalid value**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Admin saves an invalid value |  |
|  | 2- System rejects it, keeps the old value and shows the reason |

### User Story #26

| Field | Value |
| --- | --- |
| **User Story ID** | US #26 |
| **User Story Name** | Audit log of money movements and admin actions |
| **Actors** | System, Support employee, Admin |
| **Requirement** | FR-25 |
| **Priority** | Must |
| **Hard case** | — |
| **Description** | As PayLink management<br>I’d like every money movement and every admin action to be written to an audit log<br>So that we can show regulators who did what, when and why |
| **Pre condition** | A money movement or an admin action takes place. |
| **Post condition** | An audit record exists with who, when, what and why; audit records are never changed or deleted. |
| **Acceptance Criteria** | Given a customer tops up the wallet<br>When the top-up completes<br>Then an audit record exists with the customer, the time, the amount and the reason (top-up)<br><br>Given an admin changes a fee<br>When the change is saved<br>Then an audit record exists with the admin, the time, the old value and the new value<br><br>Given the full test run has finished<br>When ledger entries and admin actions are compared with audit records<br>Then 100% of them have an audit record |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- A money movement or an admin action takes place |  |
|  | 2- System writes an audit record (actor, time, action, reason, reference) in the same transaction |
| 3- Support employee or admin requests the audit trail of a payment or an account |  |
|  | 4- System displays the audit records in time order |

**Exceptional Scenario – Audit record cannot be written**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- A money movement is requested |  |
|  | 2- System cannot write the audit record |
|  | 3- System rolls the movement back, so no money moves without an audit record |

### User Story #27

| Field | Value |
| --- | --- |
| **User Story ID** | US #27 |
| **User Story Name** | Daily reconciliation report |
| **Actors** | Biller, System (Reconciliation), Support employee |
| **Requirement** | FR-26 |
| **Priority** | Should |
| **Hard case** | HC 7 |
| **Description** | As a support employee<br>I’d like PayLink’s payments to be compared every night with the biller’s settlement file<br>So that differences are found and investigated |
| **Pre condition** | The settlement file of the biller has been received. |
| **Post condition** | A reconciliation report lists all differences; Unknown payments are resolved by the lifecycle rules. |
| **Acceptance Criteria** | Given the settlement file lists a payment that PayLink has as Failed<br>When the nightly reconciliation runs<br>Then the difference appears in the reconciliation report for support to review<br><br>Given PayLink has a payment in Unknown and the file lists it as received<br>When the reconciliation runs<br>Then the payment becomes Completed<br><br>Given PayLink has a payment in Unknown and the file does not list it<br>When the reconciliation runs<br>Then the payment becomes Failed, its held funds are released to the customer’s available balance and the payment becomes Refunded<br><br>Given all lines of the file match PayLink’s payments<br>When the reconciliation runs<br>Then the report states that no differences were found |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Biller sends the nightly settlement file |  |
|  | 2- System reads the file and compares each line with PayLink’s payments by reference and amount |
|  | 3- System resolves Unknown payments according to the file: a payment listed as received becomes Completed; a payment not listed becomes Failed, its hold is released and it becomes Refunded |
|  | 4- System creates the report with all differences (missing, extra, amount or state different) |
|  | 5- System makes the report available to support |

**Exceptional Scenario – File missing or unreadable**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- The settlement file is missing or cannot be read |  |
|  | 2- System changes no payment, records the problem in the report and raises an alert |

### User Story #28

| Field | Value |
| --- | --- |
| **User Story ID** | US #28 |
| **User Story Name** | Request a refund of a completed payment |
| **Actors** | Customer, Support employee |
| **Requirement** | FR-27 |
| **Priority** | Could |
| **Hard case** | — |
| **Description** | As a customer<br>I’d like to ask for a full refund of a completed payment (a refund request) and have support decide<br>So that mistakes can be corrected |
| **Pre condition** | The payment is Completed, belongs to the customer, is not older than 30 days and has no other refund request; the customer is logged in; the support employee is logged in for the review. |
| **Post condition** | The payment stays Completed (a final state); the refund is a separate request with its own ledger entries; the decision is audited. |
| **Acceptance Criteria** | Given I have a completed payment<br>When I request a refund and give a reason<br>Then a refund request with the status “Pending review” is created and support can see it<br><br>Given a refund request is pending<br>When support approves it<br>Then the full amount (payment amount and fee) is credited to my wallet, ledger and audit entries are written and I am notified<br><br>Given a refund request is pending<br>When support rejects it<br>Then no money moves and I am told the decision<br><br>Given a payment is older than 30 days or already has a refund request<br>When I request a refund<br>Then the system rejects the request and tells me the reason |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Customer selects a completed payment and requests a refund with a reason |  |
|  | 2- System creates the refund request with the status Pending review |
| 3- Support employee opens the request and approves it |  |
|  | 4- System credits the full amount to the wallet with ledger and audit entries |
|  | 5- System notifies the customer |

**Exceptional Scenario – Request rejected**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Support employee rejects the request |  |
|  | 2- System moves no money, records the decision and notifies the customer |

### User Story #29

| Field | Value |
| --- | --- |
| **User Story ID** | US #29 |
| **User Story Name** | View daily totals |
| **Actors** | Admin |
| **Requirement** | FR-28 |
| **Priority** | Could |
| **Hard case** | — |
| **Description** | As an admin<br>I’d like to view the daily totals of payments, fees earned, commissions paid and failures per biller<br>So that I can monitor the business |
| **Pre condition** | The admin is logged in. |
| **Post condition** | No data is changed. |
| **Acceptance Criteria** | Given payments were made on a day<br>When I select that day<br>Then I see the number and total amount of payments, the fees earned, the commissions paid and the failed payments per biller<br><br>Given no payments were made on a day<br>When I select that day<br>Then all totals are shown as zero |

**Scenarios**

**Normal Scenario**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Admin opens the daily totals and selects a date |  |
|  | 2- System adds up the payments and ledger entries of that date |
|  | 3- System displays payments, fees earned, commissions paid and failures per biller |

**Exceptional Scenario – No activity on that day**

| **Actor Action** | **System Response** |
| --- | --- |
| 1- Admin selects a day without payments |  |
|  | 2- System shows zero for every total |
