# Worked example: claims status self-service

A record of the first change taken through the workflow, `intent/claims-status-self-service/`, on 2026-11-05. It covers Stage 1 (Intent) and Stage 2 (Design). Stage 3 (Build) has not started. Times are as recorded in Git.

This page records what happened and what was decided. The artifacts themselves are the source of truth: [intent.md](../intent/claims-status-self-service/intent.md) and [spec.md](../intent/claims-status-self-service/spec.md).

## Where it stands

| Stage | Artifact | State | Record |
|---|---|---|---|
| 1. Intent | `intent.md` | **Accepted.** Merged with `Status: accepted`. | PR #1, merge `e82efbf`, accepted text `43150a1` |
| 2. Design | `spec.md` | **Drafted and merged, still `Status: draft`.** | PR #2, merge `7cb1327`, commit `f376edc` |
| 3. Build | `plan.md` | Not started. A spec becomes ready for Stage 3 when its status is set to `accepted` and merged. That has not happened. | none |

## Timeline

| Time | What | Record |
|---|---|---|
| 16:46 | Project created from Create React App | `87dc45a` |
| 17:08 | `init`: first commit, including the intent as a draft | `f51a5d9` |
| 17:22 | `draft-spec` skill and spec creation docs | `583df5b` |
| 17:37 | Intent accepted on branch `accept/claims-status-self-service` | `43150a1` |
| 17:42 | PR #1 merged | `e82efbf` |
| 17:43 | `accept-intent` skill committed | `8ed7c52` |
| 17:47 | Intent listing helper added, both skills linked | `8fd73ec` |
| 18:02 | Spec committed on `spec/claims-status-self-service` | `f376edc` |
| 18:03 | PR #2 merged | `7cb1327` |
| 18:09 | `CLAUDE.md` added | `b130765` |
| 18:16 | Spec gate hook and pull request check added, on `enforce/spec-gate` (no PR yet) | `f971da0` |

## Stage 1: accepting the intent

Run with `/accept-intent`, with the product owner in the conversation. The intent's author is J. Ortiz, claims operations.

**Readiness check on the draft: not ready.** One blocking failure, B2: six open questions, none with a disposition. One advisory, A2: the "no new personal data in the portal session" constraint could not be checked against a spec.

**The product owner's dispositions**

| Open question | Disposition |
|---|---|
| Is a status label enough, or also the next step and expected date? | Answered: a label is enough for the first version (MVP). |
| What is out of scope for the first version? | Answered: the next step and expected date. |
| How will success be measured? | Answered: by handler time spent on status-only queries. |
| Do loss adjusters or other non-customers need access? | Answered: no, only customers. |
| Is "about a third of call time" measured? | Answered: it is only the handlers' estimate. |
| Which system holds claim status, and who owns it and the portal? | Carried to Design: not clear yet, to be defined later. |

Two changes came with those answers. The product owner asked for the feature to be held back while the source is unknown, and that became a constraint in outcome terms, with wording they confirmed: customers must not see claim status until its source is identified. One new question was carried to Design: the baseline and target for handler time, which nobody can state because the only figure is an estimate.

**Result:** Ready, no blocking failures, A2 still open as an advisory. Claude asked one plain question ("Do you accept this intent into Design, and do you want me to commit it on a branch and open a PR?"), the product owner said yes, and only then was `Status: draft` changed to `accepted`, on the Author line and nowhere else. PR #1 was opened, and merged at 17:42 by the account that opened it. No review was recorded.

## Stage 2: drafting the spec

Run with `/draft-spec`.

**Gate:** passed. The status check was ok, the copy on `main` said accepted, the working copy matched it, and no `spec.md` existed.

**What the repo showed:** an untouched Create React App starter. There is no portal, login, API, session handling, configuration or claim data. The skills available were process skills and general tools, with no brand, security, compliance or UX policy, so all four domains are recorded as "not available".

**The first draft** had 11 requirements and 7 areas of concern. Claude asked the product owner four questions, then two follow-ups. The answers were:

- This repo is the customer portal. It is still the starter app.
- The existing login is a separate service, to be integrated later.
- Claim status and claim references count as personal data (the stricter reading of the constraint). They may be shown on screen for the visit but are never stored: not in the session, cookies, browser storage, caches, page addresses or logs.
- The small-scope proposals were accepted: no caching, no new portal analytics in the first version, approved customer labels only.
- The owner of the policy skills is yet to be defined.

**The spec as merged** has 11 requirements and 7 areas of concern, about 2,300 words, over the 2 to 3 page target. The two concerns that block planning are that the login is not integrated and no back end is identified (the status lookup needs a server, and this repo has none), and that the claim status source and its owner are unknown. The rest are in the spec.

PR #2 was based on `origin/main` through a temporary worktree, because local `main` held one unpushed commit that did not belong in a spec pull request. It was merged at 18:03 by the account that opened it, with no review recorded and the spec still `Status: draft`.

## What was built along the way

| Item | Why | Where it is described |
|---|---|---|
| Intent listing helper, `list-intents.sh` | Both skills should list the same options when run without a slug, and `/draft-spec` should not offer an intent that is accepted only on a branch. The real repo hit this case: the intent was accepted on its branch before PR #1 merged. | [enforcement.md](enforcement.md) |
| Spec gate script, hook and pull request check | Lesson 6: a skill is advisory, so the rule "a spec only comes from an accepted intent" got a deterministic check at the edit and on the pull request. | [enforcement.md](enforcement.md), [spec-creation.md](spec-creation.md#what-enforces-the-gate) |
| `CLAUDE.md` | Keeps the repo's working rules, including "do not invent systems", where every session reads them. | [CLAUDE.md](../CLAUDE.md) |

## What the run surfaced

- **Numbered answers drift.** The product owner's answers were numbered differently from the questions, and one question got no answer. Claude restated how it read each answer and asked for corrections before editing. Without that step an answer could have landed on the wrong question.
- **A literal reading of a constraint can make the outcome impossible.** "Not held in the browser at all" cannot be met by any page that shows a status. The spec asked the product owner to confirm that showing it on screen for the visit is acceptable, and they did. The privacy owner has not yet agreed. That is concern 7 in the spec.
- **The spec's main blocker is outside the code.** No login and no back end exist yet, so the status view cannot be turned on even once it is built.
- **Governance rested on convention.** Both pull requests were merged by their opener with no review, because `CODEOWNERS` has no owner and `main` has no branch protection. See [enforcement.md](enforcement.md#not-done-yet).
- **Some docs were out of date** about the remote and the workflow. They were corrected in [intent-approval.md](intent-approval.md).

## Still open

- Accept the spec: set `Status: accepted` and merge, which would start Stage 3.
- The spec's 7 areas of concern, owned as listed in [spec.md](../intent/claims-status-self-service/spec.md).
- The items in [enforcement.md](enforcement.md#not-done-yet).
- Open a PR for `enforce/spec-gate`. Its pull request check runs on GitHub for the first time there.
