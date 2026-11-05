# Spec: claims status self-service
From: [intent.md](intent.md) (J. Ortiz, claims operations), accepted at 43150a1. Status: draft.
Skills applied: none. Not available: brand, security, compliance and UX policy skills (none of the four were checked).

## Requirements
Numbered so the plan and review can cite them. `Intent` = stated in intent.md. `Derived` = added by this spec, to be confirmed.
- R1. A signed-in customer can see the status of their own claim in the portal, without phoning the contact center. *(Intent: Proposed outcome.)*
- R2. The first version (MVP) shows a status label only. It does not show the next step or an expected date. *(Intent: Proposed outcome.)*
- R3. Only customers can use it. Third-party loss adjusters and other non-customers get no access. *(Intent: Affected users and systems.)*
- R4. Access uses the portal's existing login only. No new sign-in, account type or credential is added. *(Intent: Constraints.)*
- R5. The status view adds no new personal data to the portal session. *(Intent: Constraints.)*
- R6. Claim status and claim references are treated as personal data. They are never written to the session, cookies, browser storage, caches, page addresses (URLs) or logs. They exist only in memory while a request is handled, and on screen while the customer views them. *(Derived: the product owner chose the stricter reading of R5 and confirmed that showing status on screen is allowed. The privacy owner has not yet agreed, see concern 7.)*
- R7. While the exposure switch is off, no customer sees claim status: the view is not shown and the status source is not called. The switch is off by default and stays off until the source of claim status is identified. *(Intent: Constraints. "Source is not called" is Derived.)*
- R8. A customer sees only their own claims. *(Derived: general practice, not an organization policy.)*
- R9. Every outcome has a plain-language screen: no claims found, status source unavailable, and a status the portal cannot show. Each says what happened and how to reach the contact center. None shows a blank page or a raw error. *(Derived.)*
- R10. Labels shown to customers come from a list agreed with claims operations. Internal-only statuses are not shown. *(Derived, confirmed by the product owner.)*
- R11. Success is measured by handler time spent on status-only queries, read from contact-center data. The first version adds no new analytics to the portal. *(Intent: Proposed outcome for the measure. "No portal analytics" is Derived, confirmed by the product owner.)*

## Design
**What exists today.** The repo is an untouched Create React App starter. [src/App.js](../../src/App.js) is the starter page, and [src/index.js](../../src/index.js) renders it. [package.json](../../package.json) declares React `^19.3.1`, `react-scripts` 5.0.1 and Testing Library, and the only test, [src/App.test.js](../../src/App.test.js), checks the starter "learn react" link. There is no routing, API call, login, session, configuration or claim data anywhere in the repo. The product owner confirmed that this repo **is** the customer portal. It holds only the starter app so far, and Create React App builds a browser-only app with no server. The existing login (a separate service, to be integrated later, per the product owner), any back end, and the system holding claim status are therefore **not in this repo** (concern 1).

**Components and boundaries.** Where each piece lives is not yet known, except the portal front end.

| Piece | State | Role |
| :---- | :---- | :---- |
| Portal front end | This repo (confirmed). Starter app only. | Hosts the status view. |
| Existing login | A separate service, to be integrated later (confirmed). Not in repo. Its interface is not yet identified. | Signs the customer in and holds the session. The new work only reads who is signed in. It changes nothing the login stores (R4, R5). |
| Status view | Proposed | A page or section in the portal that lists the customer's claims with a status label, and shows the screens in R9. Read-only. |
| Status lookup | Proposed | A step on a server, between the view and the source. It takes the signed-in customer from the existing session, asks the source for that customer's claims, maps source statuses to the approved labels (R10), and returns only a claim reference and a label. It enforces R7 and R8. It cannot live in this repo as it stands, because there is no server here. Whether it goes in an existing back end or a new one is not yet identified (concern 1). General practice, not organization policy: the browser should not call the source directly, because R7 and R8 would then depend on the browser, which a customer can alter. |
| Claim status source | Not yet identified | The system that holds claim status, and the contract with it (concern 2). |
| Exposure switch | Proposed | On or off, off by default. Read by both the view and the lookup, so hiding the view alone is not enough (R7). Its mechanism is not yet identified (concern 5). |

**Contract (logical).** The lookup receives the signed-in customer, as the existing login already identifies them, and nothing else. It returns a list of claim reference and label pairs, an empty list, or an error kind (source unavailable, or not exposed). The source's own fields and how it matches a customer to claims are not yet identified.

**Data handling.** Three things are in play: the customer's existing identity, a claim reference, and a status label. The last two are personal data under R6. They live in memory for one request and one render, then are dropped. They never appear in page addresses, which browsers and servers keep. Responses carrying them are marked so browsers and intermediaries do not store them (general practice, not organization policy). No caching in the first version (confirmed by the product owner). It is the simplest way to honor R5 and R6, and it avoids showing stale status.

**Error and empty states.**
- Switch off: nothing is shown and there is no entry point.
- No claims: a message saying none were found.
- Source down or slow: a message and the contact route.
- A status with no approved label: a generic "contact us" message, never the internal value.

**Measuring success.** Handler time on status-only queries lives in contact-center data, not in the portal, so the portal does not measure it (R11). A baseline must exist before launch for any drop to mean something. Today the only figure is the handlers' estimate (concern 6).

**Testing.** The repo's stack is Jest and Testing Library through `react-scripts`. Proposed tests use a stubbed lookup unless noted:
- The view renders each state in R9.
- With the switch off, nothing renders and the lookup is never called (R7).
- The lookup returns only the signed-in customer's claims, tested with a stubbed source (R8). This test belongs wherever the lookup ends up living.
- Rendering writes nothing to cookies or browser storage, and no claim data appears in the page address (R6).
- Responses carrying claim data are marked as not to be stored. This test belongs wherever the lookup lives (R6).
- An unapproved status shows the generic message (R10).

Anything that needs the real login or the real source cannot be tested until they are integrated. Until then tests use a stand-in for the login. The starter test stops applying once the starter page is replaced.

## How each constraint in the intent is met
| Constraint | Met by | Confidence |
| :---- | :---- | :---- |
| No new personal data in the portal session | R5, R6: status is fetched per view and never stored. | Partial. It depends on how the customer is matched to claims (concern 3), and the privacy owner has not yet agreed the reading of "personal data" (concern 7). |
| Use the existing login only | R4, R8: the lookup reads the customer from the existing session and adds no sign-in. | Partial. The login is a separate service to be integrated later, so we cannot yet confirm what it tells the portal about the customer, or that the lookup can use it. |
| Customers must not see claim status until its source is identified | R7: switch off by default. Off means no view and no call to the source. | Partial. The rule is designed, but the switch mechanism is not identified (concern 5). |

## Open questions from the intent
| Question | State |
| :---- | :---- |
| Which system is the source of claim status, and who owns it and the portal? | Carried forward as concerns 1 and 2. The product owner confirmed this repo is the portal and that the login is a separate service to be integrated later. No owner is named for the portal, the login or the source, and nothing identifies the source. |
| What are the baseline and target for handler time on status-only queries? | Carried forward as concern 6. |

## Areas of concern
Ordered by how much they block planning. Owners are proposed.
1. **The login is not integrated yet, and no back end is identified.** The product owner confirmed that this repo is the portal and that the existing login is a separate service to be integrated later. The repo is still the unmodified starter, which builds a browser-only app with no server. Two things follow. Until the login is integrated, nobody can be identified as the signed-in customer (R4, R8), so the status view cannot be turned on. And the status lookup (R7, R8) needs a server, and no back end for the portal is identified. The plan cannot place the lookup until one is. Needed: the login service's owner and what it tells the portal about a signed-in customer, and whether a back end exists for the lookup or how one becomes available. Owner: product owner with the engineering lead.
2. **The claim status source and its owner are not identified.** This is the intent's own open question. The source decides how customers are matched to claims, how fresh status is, and which statuses exist and are safe to show (R10). Without it there is no contract, and by the intent's constraint the view must stay hidden. Needed: name the system and its owner, plus a short note on how it identifies a customer's claims. Owner: claims operations, with the source system's owner once known.
3. **Matching a customer to claims may clash with two constraints.** To show a customer their claims, something must link the signed-in customer to their claim records. If the existing login does not carry that link, getting it means adding data to the session (against "no new personal data") or a new sign-in step (against "existing login only"). Proposal: do the matching on the server inside the lookup, using only what the login already provides. If that is impossible, the product owner must relax a constraint or change the outcome. Owner: portal owner and product owner.
4. **No policy skills were available, so four domains were not checked.**
   - **Brand and UX:** label wording, layout, accessibility.
   - **Security:** access control and logging rules. R8 and R6 are general practice only.
   - **Compliance:** whether claim status may be shown online at all, and rules on keeping or logging it.

   This session's skills hold only process skills and general tools. None is an organization policy. Needed: the policy skills made available, then this spec re-checked against them. Owner: not yet defined (the product owner confirmed this). [docs/spec-creation.md](../../docs/spec-creation.md) says a technical team member should decide who owns each policy skill.
5. **The exposure switch has no home yet.** The rule is clear (R7) but where the switch lives and who flips it depends on the portal (concern 1). In this repo's stack, build-time settings such as `REACT_APP_*` variables are fixed when the app is built, so changing one needs a new build. Proposal: a server-side setting that can be changed without a release, owned by the portal owner, with the product owner deciding when it goes on. Owner: portal owner.
6. **Success has no baseline or target.** The "third of call time" figure is a handler estimate, and the contact center may not be able to tell status-only calls from other calls. Needed: claims operations check whether such calls can be identified, and set a baseline and target before launch. Owner: claims operations with contact-center management.
7. **The privacy owner has not agreed the reading of "personal data".** The product owner chose the stricter reading of "No new personal data in the portal session": a claim status or claim reference counts as personal data. The product owner confirmed that showing a status on screen for the visit is acceptable, as long as it is never stored anywhere (R6). Taken literally, "not held in the browser at all" could not be met by any page that shows a status, so this confirmation matters. Whoever owns privacy for the portal is not yet identified and has not seen this reading. Needed: name that person and have them agree, or correct R6. Owner: product owner.

## Provenance
- Prompt: `/draft-spec claims-status-self-service`, no extra instructions. Revised in place after the product owner's answers: this repo is the portal, the login is a separate service to be integrated later, the stricter reading of "personal data" was chosen, the three small-scope proposals were accepted, and the owner of the policy skills is yet to be defined.
- Skills in force: `draft-spec` (no version recorded in the skill file). No policy skills.
- Source: intent.md at 43150a1.
