# Feature Specification: Integrations

**Feature Branch**: `010-integrations`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "Integrations like HeyClicky: a catalog of apps my agents can reach into (GitHub, Notion, Linear…), Connect/Disconnect, plus Add custom connector."

Reference: `references/heyclicky/10-settings-integrations.png`, `02-app-home.png` (Apps chip)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Connect an app from the catalog (Priority: P1)

Settings → Integrations ("Apps your agents can reach into.") has a search field, an "Add custom connector" button, a
CONNECTED list and an AVAILABLE INTEGRATIONS list. Each row shows the app's icon, name, a status ("● Connected" in
green, or "● Reconnect required" in orange) and a one-line description of what agents can do with it. I click
**Connect**, sign in to that app in my browser, and it moves to CONNECTED.

**Why this priority**: Integrations let Clickys work with my real tools.

**Independent Test**: Connect GitHub. After signing in, GitHub shows "● Connected". Ask a Clicky "list my open pull
requests" and it answers from GitHub (after an Allow card).

**Acceptance Scenarios**:

1. **Given** an available integration, **When** I click Connect and finish signing in, **Then** it appears under
   CONNECTED with "● Connected" within 5 s of returning to MyClicky.
2. **Given** I cancel the sign-in, **Then** it stays under AVAILABLE with no error besides "Sign-in cancelled".
3. **Given** a search term, **Then** both lists filter by name and description.

---

### User Story 2 - Keep connections healthy (Priority: P1)

If a connection expires or breaks, its row says "● Reconnect required", with a **Reconnect** button and an ✕ to
remove it. Healthy connections have **Disconnect**.

**Independent Test**: Revoke MyClicky's access in GitHub's settings, reopen the page, and GitHub shows "Reconnect
required". Reconnect and it's healthy again. Disconnect and it moves back to AVAILABLE.

**Acceptance Scenarios**:

1. **Given** the Integrations page opens, **Then** each connection's status is refreshed (≤ 10 s, shown with a small spinner meanwhile).
2. **Given** Disconnect or ✕, **Then** agents can no longer use it, and it returns to AVAILABLE (catalog items) or disappears (custom).

---

### User Story 3 - Add a custom connector (Priority: P2)

"Add custom connector" lets me add any compatible connector by name plus either a web address or a command on
my Mac. It then behaves like the catalog ones.

**Independent Test**: Add a custom connector pointing to a known public server URL. It appears under CONNECTED (or
asks to sign in) and a Clicky can use it.

**Acceptance Scenarios**:

1. **Given** a name and URL, **When** I click Add, **Then** it's validated (reachable, compatible), and shown with a status.
2. **Given** an invalid URL or command, **Then** I see a clear error and nothing is added.

---

### User Story 4 - The Apps chip (Priority: P3)

The sidebar's "Apps +" chip shows the icons of my connected integrations. Clicking it opens the Integrations page.

**Acceptance Scenarios**:

1. **Given** GitHub and Notion are connected, **Then** the chip shows both icons followed by "Apps +".

### Edge Cases

- Claude Code isn't installed or signed in → the page explains that integrations need it (009) and disables Connect.
- A catalog service changes its address → Connect fails with a readable message. The catalog file can be updated.
- Two connectors with the same name → the second is rejected ("Name already used").
- Agents use integration actions → every action asks with an Allow card unless "Always allow for this Clicky" (009).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Integrations page MUST match the reference layout: search, Add custom connector, CONNECTED and
  AVAILABLE sections, rows with icon, name, status, description and actions.
- **FR-002**: Connect MUST run the service's sign-in in the browser and end in a Connected status.
- **FR-003**: Statuses MUST be refreshed when the page opens, with Reconnect for broken connections and Disconnect/✕ to remove.
- **FR-004**: Connected integrations MUST be available to every Clicky, with each action subject to Allow cards.
- **FR-005**: Custom connectors MUST accept a URL or a local command, and be validated before saving.
- **FR-006**: The catalog MUST be a data file that can be updated without code changes.
- **FR-007**: MyClicky MUST NOT store integration secrets in its own files (Principle IV).

### Key Entities

- **Integration**: id, name, icon, description, how to connect (web address or command), whether it's from the catalog.
- **Connection status**: connected, needs sign-in (Reconnect required), failed, checking.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: GitHub, Notion and Linear can each be connected and used by a Clicky in under 2 minutes each.
- **SC-002**: A revoked connection shows "Reconnect required" the next time the page opens.
- **SC-003**: The page matches ref 10 within 5% (catalog contents aside).

## API Cost Impact

None on the API key (agents use the Claude subscription).

## Deviations from HeyClicky

- The catalog only lists services with an official, publicly documented connector that signs in through the browser
  (verified during implementation). YouTube, LinkedIn and Google Docs are listed only if an official one is available.
  Otherwise, they can be added as custom connectors.
- Signing in may briefly open a Claude Code sign-in window (see plan). HeyClicky runs its own sign-in service, which
  MyClicky can't (III).

## Assumptions

- Integrations are managed through Claude Code's connector support (the agents' engine), so there's no MyClicky server.
