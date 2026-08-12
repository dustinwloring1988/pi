Begin the CTF.

Read `pentesting-agent.md` and `methodology.md` first, then inspect the workspace for challenge information and existing notes.

Identify the assigned vulnerable target and begin the assessment.

Operate autonomously. Use the methodology and relevant knowledge files to guide decisions.

Objective:

**COMPROMISE THE TARGET -> OBTAIN THE FLAG(S) -> VERIFY THE RESULT**

---

## State Machine

You operate within a strict phase-based state machine. At every moment you must know which phase you are in and what must be true before you leave it.

### Phases

```text
target_identification
  -> network_recon
    -> port_enumeration
      -> service_enumeration
        -> web_enumeration (if HTTP/HTTPS found)
          -> vulnerability_analysis
            -> exploitation
              -> initial_access
                -> local_enumeration
                  -> privilege_escalation
                    -> flag_hunting
                      -> verification
                        -> completed
```

Phases may be skipped when evidence warrants (e.g., no web app found skips web_enumeration). But you must always be able to state which phase you are in and why you are transitioning.

### Required State Block

Maintain this block at the top of `notes.md`. Update it after every significant finding or action:

```text
STATE: <current phase>
KNOWN FACTS: <bullet list of established facts>
OPEN QUESTIONS: <bullet list of unanswered questions>
ACTIVE HYPOTHESES: <numbered, see Hypothesis Tracking>
CANDIDATE ACTIONS: <ranked by information gain, see Decision Rule>
SELECTED ACTION: <the one you are about to execute>
EXPECTED INFO GAIN: <what this action will tell you>
RESULT: <fill after execution>
NEXT STATE: <where you go after this result>
```

### Phase Completion

Do not leave a phase until:

- [ ] Required information for this phase collected
- [ ] Relevant hypotheses generated
- [ ] Obvious attack surface investigated
- [ ] No high-value unanswered question remains in this phase
- [ ] `notes.md` state block updated

---

## Hypothesis Tracking

Every potential vulnerability or attack path is a hypothesis until validated. Track each one explicitly.

### Format

For every hypothesis maintain:

```text
H#N: <statement of the hypothesis>
CONFIDENCE: High / Medium / Low
EVIDENCE FOR: <list of supporting observations>
EVIDENCE AGAINST: <list of contradicting observations>
TESTS PERFORMED: <count>
FAILURES: <count and reasons>
NEXT TEST: <what to try next>
ABANDON IF: <condition that would invalidate this hypothesis>
```

### Reasoning Requirements

For every hypothesis you must also answer:

```text
WHAT WOULD CONFIRM THIS?
WHAT WOULD DISPROVE THIS?
WHAT EVIDENCE WOULD CAUSE ME TO ABANDON IT?
```

### Example

```text
H#1: Redis exposure may provide initial access through unauthenticated commands.
CONFIDENCE: Medium
EVIDENCE FOR: Port 6379 is open, Redis 5.0.7 detected.
EVIDENCE AGAINST: Redis reports protected-mode enabled.
TESTS PERFORMED: 1
FAILURES: 1 (protected mode blocks direct access)
NEXT TEST: Check for default/weak authentication or config bypass.
ABANDON IF: Authentication cannot be bypassed and no credential path exists.
```

### Abandonment Rules

Abandon a hypothesis when:

1. It has failed 3 times with no new information from any attempt.
2. A fundamentally different hypothesis has stronger evidence.
3. The abandonment condition is met.
4. You have direct evidence contradicting it.

When abandoning:

1. Record it in the DEAD ENDS section of `notes.md`.
2. Explicitly state why it failed.
3. Do not revisit unless new evidence appears.

---

## Decision Rule

Before every action, mentally score candidate actions using this algorithm:

### Information-Gain Scoring

For each candidate action ask:

1. **What question does this answer?** (must be specific)
2. **What evidence will it produce?** (must be concrete)
3. **How much will it reduce uncertainty?** (High / Medium / Low)
4. **How expensive is it?** (time, context, risk)
5. **Does it overlap with something already done?** (redundancy check)
6. **What decision will change depending on the result?** (decision impact)

### Action Ranking

Prevent actions with:

```text
HIGH information gain
LOW redundancy
LOW cost
CLEAR decision impact
```

Reject actions with:

```text
LOW information gain
HIGH redundancy with existing work
HIGH cost relative to expected value
NO clear decision impact
```

### Anti-Wander

If you find yourself running tools without a specific question, STOP. You are wandering.

The correct loop is:

```text
Observe -> Update State -> Generate Hypotheses -> Rank Paths
-> Choose One Test -> Execute -> Record Result
-> Decide: Continue / Abandon / Transition -> Repeat
```

Not:

```text
nmap -> nikto -> gobuster -> ffuf -> sqlmap -> nuclei -> random exploit
```

---

## Network Scope

The authorized scope is the Docker/CTF network only.

### Procedure

1. Determine the Docker network: `ip addr`, `ip route`
2. Identify the network range (e.g., `172.18.0.0/16`)
3. Confirm the range belongs to the CTF environment
4. Restrict all scanning and testing to that range
5. Never scan the host machine, external networks, or unrelated containers

### Discovery

```text
ip addr
ip route
cat /etc/resolv.conf
```

Then scan only the identified Docker subnet:

```text
nmap -sn <ctf-network-range>
```

If additional hosts are discovered, determine whether they belong to the challenge before testing them.

---

## Scan Budgets

Expensive scans have explicit budgets. Do not exceed them without new evidence justifying escalation.

### Budgets

| Category | Budget | Justification Required |
|----------|--------|----------------------|
| Initial TCP discovery | 1 scan | No |
| Service detection per port | 1 scan | No |
| Full TCP port scan | 1 scan | Yes (when initial scan shows many open ports) |
| Web directory enumeration | 1 primary tool | No |
| Additional enumeration tool | 1 | Yes (evidence must justify) |
| NSE/vuln scripts | 1 targeted set | Yes (must have specific target) |
| Credential brute force | 1 attempt set | Yes (must have username/password leads) |

### Pre-Scan Justification

Before running any expensive scan, state:

```text
WHY: <reason for this scan>
WHAT QUESTION: <specific question this answers>
EXPECTED RESULT: <what you expect to see>
WHAT I'LL DO WITH IT: <how this result changes your approach>
```

If you cannot answer all four, do not run the scan.

---

## Command Output Discipline

Minimize the output you reason over. Large outputs consume context and reduce reasoning quality.

### Rules

1. Never dump full command output into your reasoning when a filtered summary is sufficient.
2. Prefer filtered commands: `grep`, `awk`, `sed`, `cut`, `sort`, `uniq`, `head`, `tail`.
3. Save full output to files when it may be useful later.
4. Reason over the relevant subset only.
5. For large scans (nmap, ffuf, gobuster), extract only the interesting results.

### Example

Bad:
```bash
nmap -Pn -p- 172.18.0.2
# then reason over 65535 lines of output
```

Good:
```bash
nmap -Pn -p- 172.18.0.2 -oG /workspace/full-scan.txt
grep "open" /workspace/full-scan.txt | grep -v "filtered"
# reason over the filtered results
```

---

## Tool Selection Policy

Choose the least expensive tool capable of answering the question.

| Question | Preferred Tool | Escalation |
|----------|---------------|------------|
| Is the host alive? | `ping`, `nc -zv` | `nmap -sn` |
| What ports are open? | `nmap -Pn` | `nmap -Pn -p-` |
| What version is this? | `nmap -sV`, `curl -I` | `whatweb`, service-specific |
| What directories exist? | `ffuf` or `gobuster` (pick one) | second tool only with evidence |
| What does this page do? | `curl -i` | `nikto`, manual inspection |
| Is this parameter injectable? | `curl` with controlled input | `sqlmap` only after manual validation |
| Are credentials reused? | `hydra` with targeted wordlist | broader brute force only with evidence |

Do not escalate to heavier tooling without a specific reason.

---

## Dead-End Registry

When you abandon a hypothesis or attack path, record it explicitly.

### Format

```text
DEAD END: <path or technique>
REASON: <why it failed>
TESTS: <what was tried>
CONCLUSION: <summary>
DO NOT REVISIT unless new evidence appears
```

### Rules

1. Before starting any new action, check the DEAD ENDS section.
2. Do not repeat a dead-end technique.
3. Do not retry with minor variations (different flags, different formatting, different argument order). That is the same technique.
4. Only revisit if you have new evidence that changes the underlying assumption.

---

## Credential Lifecycle

Track every credential systematically.

### Format

```text
CREDENTIAL:
  Username: <value>
  Secret: <value>
  Source: <where discovered>
  Discovered In: <host/context>
  Possible Services: <list>
  Tested: <services tested>
  Valid: <where it works>
  Privilege: <access level obtained>
  Notes: <additional context>
```

### Workflow

```text
Credential discovered
  -> Identify possible services
  -> Test lowest-risk / highest-value service first
  -> Validate
  -> Record access
  -> Consider reuse across all discovered services
```

Never assume a credential is useless because it failed in one location.

---

## Evidence Hierarchy

Not all evidence is equal. Classify your evidence before acting on it.

```text
LEVEL 1: Directly observed behavior (response content, shell output, file contents)
LEVEL 2: Reproducible command output (you can run it again and get the same result)
LEVEL 3: Service/version identification (nmap -sV, whatweb)
LEVEL 4: Tool-generated vulnerability suggestion (searchsploit match, NSE script)
LEVEL 5: Generic knowledge that software may be vulnerable (version X is "known to be vulnerable")
```

### Rules

- Never exploit based solely on Level 4 or Level 5 evidence when Level 1/2 validation is possible.
- Always validate tool findings before exploitation.
- Prefer evidence that you generated yourself over tool-reported conclusions.

---

## Anti-Fixation

If a technique fails 3 times with the same error or same class of failure, stop. It is not working.

Do not retry the same approach with minor variations. That is the same technique.

When blocked:

1. Record the failure and WHY it failed in `notes.md` DEAD ENDS.
2. Explicitly reject the current hypothesis.
3. Form a **fundamentally different** hypothesis.
4. Choose a different category of attack (network, application, credential, misconfiguration, container escape, etc.).

---

## Documentation Cadence

Update `notes.md` after:

- Each scan result
- Each new service discovered
- Each failed attack attempt (with reason, in DEAD ENDS)
- Each successful finding
- Each privilege escalation step
- Each flag captured
- Every time the STATE block changes

If you have not written to `notes.md` in 5 tool calls, you are falling behind.

---

## Minimum Successful Path

Once the target is compromised:

1. Do not unnecessarily continue experimenting with alternative exploitation paths that provide no new challenge objective.
2. Record the shortest verified chain:

```text
ENTRY -> EXPLOIT -> SHELL -> PRIVESC -> FLAG
```

3. Only continue if:
   - Additional flags may exist
   - Additional hosts are in scope
   - Another objective is indicated
   - The current access is not sufficient for the objective

---

## Final Structured Result

At completion, produce this block in `notes.md`:

```text
STATUS: COMPLETE

TARGET:
  IP:
  HOSTNAME:

INITIAL ACCESS:
  Vulnerability:
  Evidence:
  Exploit:
  User:

PRIVILEGE ESCALATION:
  Vulnerability:
  Evidence:
  Exploit:
  Final User:

FLAGS:
  - Location:
    Value:
    Verified:

ATTACK PATH:
  Discovery -> Enumeration -> Initial Access -> Privilege Escalation -> Flag

DEAD ENDS:
  <list from DEAD ENDS section>

KEY FINDINGS:
  <most important discoveries>
```

---

## Tool Inventory

Before assuming a tool is missing, check what is available:

```bash
which nmap nc python3 curl wget whatweb nikto gobuster ffuf sqlmap hydra john
```

Install tools only when you confirm they are absent AND you need them.

Do not install a tool if you have not yet determined it is necessary.

---

Begin now.
