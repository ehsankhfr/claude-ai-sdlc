# The workflow in pictures

How one change moves from an idea to merged code, who decides at each point, and where the checks sit. For the commands to type at each step, see [README.md](README.md). The diagrams are Mermaid, which GitHub renders. A plain-text version is at the bottom for editors that do not.

State below was checked on 2026-11-06.

**How to read them**
- Blue boxes are Claude skills. Green boxes are the artifact a skill puts in a pull request. Amber hexagons and diamonds are human decisions. Grey diamonds are checks run by a script. Red rounded boxes are stops and rejections.
- **A skill never merges or closes a PR on its own.** Every amber hexagon is a person, and each one has a way to say no. See "How a person says no" below the first diagram.
- Dashed arrows are back-steps, not the normal path.

## 1. One change, end to end

```mermaid
flowchart TD
  idea(["Idea, ticket or incident"])

  subgraph S1["Stage 1: Intent"]
    cap["/capture-intent<br/>Claude drafts intent.md, Status: draft"]
    pr1["Draft PR intent/slug<br/>intent-status fails on it by design"]
    acc["/accept-intent<br/>readiness check, then the product owner<br/>chooses a disposition for each open question"]
    ok1{"Ready, and the product owner<br/>gives an explicit yes?"}
    rej1(["REJECTED: PR closed with a reason<br/>Status stays draft, never reaches main"])
    pr2["PR accept/slug<br/>Status: accepted"]
    m1{{"Product owner decides on the PR"}}
  end

  subgraph S2["Stage 2: Design"]
    ds["/draft-spec<br/>Claude drafts spec.md from the accepted intent"]
    g1{"Intent accepted on main and unchanged?<br/>check-spec-gate and the spec-gate hook"}
    stop1(["Stop: run /accept-intent first"])
    pr3["PR spec/slug<br/>spec.md, Status: draft<br/>requirements, design, areas of concern"]
    m2{{"Product owner reviews the spec PR"}}
    as1["/accept-spec, phase A<br/>readiness check, then the product owner<br/>chooses a disposition for each area of concern"]
    ok2{"Ready, and the product owner<br/>gives an explicit yes?"}
    rej2(["NOT ACCEPTED: PR closed with a reason<br/>the spec on main stays Status: draft"])
    pr4["PR accept-spec/slug<br/>Status: accepted on the From line"]
    m3{{"Product owner decides on the PR"}}
  end

  subgraph S3["Stage 3: Build, planning"]
    as2["/accept-spec, phase B<br/>Claude drafts plan.md"]
    g2{"Spec accepted on main and unchanged?"}
    stop2(["Stop: finish phase A first"])
    pr5["PR plan/slug<br/>files, order of work with streams,<br/>risks, proof"]
    m4{{"Engineer reviews the plan PR<br/>against the spec"}}
  end

  subgraph S4["Stage 3: Build, code and checks"]
    build["Build by stream<br/>see diagram 2"]
    pr6["PR per stream<br/>ci runs lint, test, build"]
    m5{{"Code owner reviews the PR"}}
  end

  fin(["Change merged"])

  idea --> cap --> pr1 --> acc --> ok1
  ok1 -->|"gaps remain"| acc
  ok1 -->|"product owner says no"| rej1
  ok1 -->|"yes"| pr2 --> m1
  m1 -->|"merge: intent accepted"| ds
  m1 -->|"close with a reason"| rej1

  ds --> g1
  g1 -->|"no"| stop1
  g1 -->|"yes"| pr3 --> m2
  m2 -->|"merge"| as1
  m2 -.->|"changes requested: Claude revises the same file"| pr3

  as1 --> ok2
  ok2 -->|"gaps remain"| as1
  ok2 -->|"product owner says no"| rej2
  ok2 -->|"yes"| pr4 --> m3
  m3 -->|"merge: spec accepted"| as2
  m3 -->|"close with a reason"| rej2
  rej2 -.->|"revise the spec, then run /accept-spec again"| as1

  as2 --> g2
  g2 -->|"no"| stop2
  g2 -->|"yes"| pr5 --> m4
  m4 -->|"merge"| build
  m4 -.->|"changes requested: Claude revises plan.md on the same PR"| pr5

  build --> pr6 --> m5
  m5 -->|"merge"| fin
  m5 -.->|"changes requested"| build

  ds -.->|"problem in the intent: a new intent PR"| cap
  as2 -.->|"problem in the spec: revise it through its own PR"| pr3

  classDef skill fill:#dbeafe,stroke:#1d4ed8,color:#000
  classDef human fill:#fef3c7,stroke:#b45309,color:#000
  classDef check fill:#e5e7eb,stroke:#4b5563,color:#000
  classDef artifact fill:#dcfce7,stroke:#15803d,color:#000
  classDef stop fill:#fee2e2,stroke:#b91c1c,color:#000
  class cap,acc,ds,as1,as2 skill
  class ok1,ok2,m1,m2,m3,m4,m5 human
  class g1,g2 check
  class pr1,pr2,pr3,pr4,pr5,pr6 artifact
  class rej1,rej2,stop1,stop2 stop
```

**What each status means**

| File | Status is on | `draft` | `accepted` |
|---|---|---|---|
| `intent.md` | the `Author:` line | still a proposal, on a PR | merged into `main` with `Status: accepted`. CI and the scripts read this line. |
| `spec.md` | the `From:` line | merged, but the product owner has not accepted it | the accept-spec PR is merged. Nothing in CI reads this line yet. |
| `plan.md` | the `From:` line | always. Nobody is defined to accept a plan, and there is no gate. | not used |

**How a person says no**

| Where | Who | How to say no | What happens |
|---|---|---|---|
| Intent, `/accept-intent` | product owner | Answer no to Claude's final question, or close the PR without merging. Say why in a comment. | Claude records the answer on the PR as a comment. `Status` stays `draft` and the intent never reaches `main`. The closed PR is the record, and counts against the survival rate. |
| Spec review | product owner | Comment on the PR and have Claude revise the same file. If the problem is in the intent, open a new intent PR. | Further commits on the same PR. The spec does not patch around a bad intent. |
| Spec acceptance, `/accept-spec` phase A | product owner | Answer no to Claude's final question, or close the accept-spec PR with a reason. | Claude records the answer on the PR as a comment. The spec on `main` stays `draft`. Revise it, then run `/accept-spec` again. |
| Plan review | engineer | Comment on the PR. Claude revises `plan.md` on the same PR. | Further commits on the same PR. No accept or reject gate is defined for a plan. |
| Code | code owner | Request changes, or close the PR, as in any review. | Standard review. |

Claude offers to draft the closing comment, but never closes a PR unless asked.

**Not defined anywhere in the repo**
- Rejecting a plan outright. Only "changes requested" exists.
- Withdrawing an intent or spec after it was merged as accepted. The `intent-status` check on `main` requires every intent there to be `accepted`, so setting one back to `draft` would fail it.
- Who may say no. `.github/CODEOWNERS` has its owner line commented out, so nothing stops anyone with write access from merging or closing these PRs. See [enforcement.md](enforcement.md).

## 2. Building from the plan

```mermaid
flowchart TD
  plan["Accepted plan.md<br/>Files that change, Order of work"]
  split{"Do steps sit in different streams?<br/>No shared file, no dependency"}
  one["One session, steps in order"]
  many["One worktree and branch per stream<br/>npm ci in each, its own PORT per dev server<br/>start with 2 or 3 sessions"]

  subgraph loop["Feedback loop, inside each session"]
    work["Implement a step"]
    chk["npm run lint<br/>npm test -- --watchAll=false<br/>npm run build"]
    fix["Read the failure<br/>fix the code, not the test"]
    passed(["All three pass, output pasted"])
  end

  ver["verifier subagent, fresh context<br/>runs the checks and the plan's Proof<br/>reports only, never fixes"]
  pr["PR: ci runs lint, test, build"]
  rev{{"Code owner reviews the diff and merges"}}

  plan --> split
  split -->|"one stream"| one --> work
  split -->|"streams A and B"| many --> work
  work --> chk
  chk -->|"any fails"| fix --> chk
  chk -->|"all pass"| passed --> ver
  ver -->|"mismatch reported"| work
  ver -->|"none found"| pr --> rev

  classDef skill fill:#dbeafe,stroke:#1d4ed8,color:#000
  classDef human fill:#fef3c7,stroke:#b45309,color:#000
  classDef check fill:#e5e7eb,stroke:#4b5563,color:#000
  classDef artifact fill:#dcfce7,stroke:#15803d,color:#000
  class ver skill
  class rev,split human
  class chk check
  class pr artifact
```

**Fixing a bug** swaps the middle for a stricter loop, so the agent cannot weaken the test that proves the fix.

```mermaid
flowchart TD
  bug(["Bug found"])
  t1["Normal session: ask Claude to reproduce the bug as a test"]
  t2["Run it and confirm it fails for the reason you expect"]
  t3["Commit the failing test"]
  t4["New session: CLAUDE_FIX_TASK=1 claude"]
  t5["Claude fixes the code<br/>the test-guard hook blocks every test edit"]
  t6["The old test now passes: the bug is gone"]
  t7["PR: ci runs, reviewer reads the diff<br/>for tests changed by a shell command"]
  t8(["The committed test is wrong:<br/>end the session, fix the test in its own commit"])

  bug --> t1 --> t2 --> t3 --> t4 --> t5 --> t6 --> t7
  t5 -.->|"test cannot be satisfied"| t8

  classDef check fill:#e5e7eb,stroke:#4b5563,color:#000
  classDef stop fill:#fee2e2,stroke:#b91c1c,color:#000
  class t5 check
  class t8 stop
```

## 3. Where the checks sit

```mermaid
flowchart LR
  edit["Claude edits a file"]

  subgraph atedit["At the edit: PreToolUse hooks, Claude's edits only"]
    h1["spec-gate<br/>blocks writing a spec.md unless its intent<br/>is accepted on main and unchanged"]
    h2["test-guard<br/>blocks editing a test file<br/>only while CLAUDE_FIX_TASK is set"]
  end

  pr["Pull request"]

  subgraph atpr["On the pull request: GitHub workflows"]
    w1["intent-status<br/>changed intents are accepted<br/>changed specs come from accepted intents"]
    w2["ci<br/>lint, test, build"]
  end

  rev["Review<br/>CODEOWNERS owner line is commented out"]
  mrg["Merge<br/>branch protection is not set up"]

  edit --> h1 --> pr
  edit --> h2 --> pr
  pr --> w1 --> rev
  pr --> w2 --> rev
  rev --> mrg

  classDef check fill:#e5e7eb,stroke:#4b5563,color:#000
  classDef notset fill:#ffffff,stroke:#b91c1c,stroke-dasharray:5 3,color:#000
  class h1,h2,w1,w2 check
  class rev,mrg notset
```

Dashed red boxes are controls that are written but not switched on. Until they are, nothing stops a PR's author from merging their own PR, and neither workflow is a required check. A file written by a shell command (`sed`, `tee`, `git checkout`) does not trigger either hook, so the PR checks and the reviewer are the backstop. Details in [enforcement.md](enforcement.md).

## Plain-text version

```
 idea, ticket or incident
          |
          v
 /capture-intent ----------> draft PR   intent/<slug>
          |
          v
 /accept-intent ----------> readiness check; product owner decides, explicit yes
          |                  PR          accept/<slug>
          |                  NO? close the PR with a reason: REJECTED, stays draft, never on main
          v
 [MERGE: INTENT ACCEPTED]    by the product owner
          |
          v
 /draft-spec -------------> gate: intent accepted on main and unchanged
          |                  PR          spec/<slug>     (Status: draft)
          v
 [MERGE]                     product owner reviews the areas of concern first
          |                  changes requested? Claude revises the same file on the same PR
          |
          v
 /accept-spec  phase A ---> readiness check; product owner decides, explicit yes
          |                  PR          accept-spec/<slug>
          |                  NO? close the PR with a reason: spec stays draft on main,
          |                      revise it, then run /accept-spec again
          v
 [MERGE: SPEC ACCEPTED]      by the product owner
          |
          v
 /accept-spec  phase B ---> gate: spec accepted on main and unchanged
          |                  PR          plan/<slug>     (plan.md)
          v
 [MERGE: PLAN REVIEWED]      engineer checks it against the spec, line by line
          |                  changes requested? Claude revises plan.md on the same PR
          |
          v
 build, one worktree per stream
          |   loop: lint, test, build -> fix -> repeat
          v   then the verifier subagent in a fresh context
 PR per stream  (ci: lint, test, build)
          |
          v
 [MERGE]                     code owner reviews the diff
                             changes requested? back to the build step

 Back-steps: a problem in the intent is a new intent PR. A problem in the spec found
 while planning is a revision of the spec through its own PR. A plan never patches
 around either.
```
