# Feature Specification: Spending and Limits

**Feature Branch**: `011-usage-limits`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "My goal is that $20 of API credit lasts 2–3 months instead of paying $20 every month. I want to see what I spend and not go over."

Reference: `references/heyclicky/02-app-home.png` (the usage ring next to "Free" in the footer)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See what I've spent (Priority: P1)

The sidebar footer shows "$0.42 this month" with a small ring that fills up as I approach my monthly budget. Clicking
it opens a Spending sheet with:
- this month's total and number of questions
- the split by model (Haiku, Sonnet) and by kind (answers, memory, naming)
- the last 6 months as bars
- the note "Estimated at list prices. Your Anthropic Console bill is the final word."

**Why this priority**: Visible spending is Principle I, and the reason MyClicky exists.

**Independent Test**: Ask 5 questions, and the footer total grows. The sheet's split adds up to the total.

**Acceptance Scenarios**:

1. **Given** answers this month, **Then** the footer, profile badge and sheet show the same total (to the cent).
2. **Given** a Sonnet pointing question, **Then** the "by model" split shows it under Sonnet.

---

### User Story 2 - A monthly budget that protects me (Priority: P1)

In Settings → General → SPENDING I set a monthly budget (default $7, so $20 lasts about 3 months), or turn it off.
At 80%, MyClicky tells me once. At 100%, it stops making paid requests until next month and tells me why, with a
quick "Allow $2 more this month" button.

**Independent Test**: Set the budget to $0.05 and ask questions. At 80% a notice appears. At 100%, the next question
isn't sent, and the bubble explains it, with the button. Press it and questions work again.

**Acceptance Scenarios**:

1. **Given** 80% of the budget is used, **Then** a one-time notice appears in the bubble (and is spoken unless quiet).
2. **Given** 100% is used, **Then** screen questions, memory summaries and Clicky naming are paused. Agents keep
   working (they use the Claude plan).
3. **Given** a new month starts, **Then** everything resumes automatically.

---

### User Story 3 - How long will my credit last? (Priority: P3)

In the Spending sheet I can enter the credit I bought ($20) and when. MyClicky shows how much is probably left and,
from my recent pace, "At this pace, your credit lasts until about Dec 12."

**Acceptance Scenarios**:

1. **Given** $20 bought on Sep 24 and $1.10 spent since, **Then** it shows "≈ $18.90 left" and a projected date based
   on the last 14 days' average.

### Edge Cases

- No usage yet → "$0.00 this month" with an empty ring. The sheet says "No paid requests yet."
- The budget is changed below the current spend → treated as reached right away, with the same notice.
- The clock or time zone changes → months are local calendar months.
- A request is interrupted after being sent → its cost is still counted (it's billed).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST record the cost of every paid API request with its model and kind (answer, memory, naming).
- **FR-002**: The footer and profile card MUST show this month's spend. The footer ring MUST show the fraction of the budget.
- **FR-003**: A Spending sheet MUST show the month total, question count, the split by model and kind, 6-month
  history and the estimate disclaimer.
- **FR-004**: A monthly budget (default $7, range $1–$100, or off) MUST warn once at 80% and pause paid requests at
  100%, with a per-month top-up button (+$2).
- **FR-005**: Agent runs MUST NOT be blocked by the budget (they don't use the API key).
- **FR-006**: Optionally, MyClicky MUST estimate the remaining credit and the date it runs out.

### Key Entities

- **Month usage**: total, questions, cost by model, cost by kind.
- **Budget**: monthly amount, top-ups for the current month, the warned-this-month flag.
- **Credit**: amount and purchase date (optional).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Recorded spend is within 5% of the Anthropic Console's usage for the same period (checked once after a week of use).
- **SC-002**: At 100% of the budget, 0 paid requests are sent until top-up or the next month.
- **SC-003**: With the default budget and typical use, the projection shows ≥ 2 months for $20.

## API Cost Impact

None. This feature only reduces risk.

## Deviations from HeyClicky

- HeyClicky's footer ring shows plan usage (message quotas). MyClicky's shows API budget use (III).
- Added a SPENDING section in General and a Spending sheet (not in HeyClicky).

## Assumptions

- List prices come from the Core pricing table (updated when Anthropic changes prices).
