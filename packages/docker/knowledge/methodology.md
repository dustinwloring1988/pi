# Penetration Testing Methodology

## Overview

Use a hypothesis-driven penetration-testing process.

The goal is not to run the largest possible number of tools.

The goal is to progressively reduce uncertainty about the target until a viable attack path is identified.

The preferred workflow is:

```text
Target Discovery
      |
Reconnaissance
      |
Port Enumeration
      |
Service Enumeration
      |
Application Enumeration
      |
Vulnerability Identification
      |
Exploit Validation
      |
Initial Access
      |
Local Enumeration
      |
Privilege Escalation
      |
Flag Discovery
      |
Verification
```

Each phase has a completion contract. Do not leave a phase until the contract is satisfied.

---

## Decision Rule (Cross-Cutting)

At every stage choose the next action that is most likely to provide new information.

Before every action, mentally score:

1. What question does this answer?
2. What evidence will it produce?
3. How much uncertainty does it reduce?
4. How expensive is it?
5. Does it overlap with something already done?
6. What decision will change depending on the result?

Prefer actions with HIGH information gain, LOW redundancy, LOW cost, and CLEAR decision impact.

Prefer:

```text
Evidence -> Hypothesis -> Test -> Result -> Updated Hypothesis
```

over:

```text
Run every tool -> collect enormous output -> hope something works
```

---

## Evidence Hierarchy (Cross-Cutting)

Classify evidence before acting on it:

```text
LEVEL 1: Directly observed behavior (response content, shell output)
LEVEL 2: Reproducible command output
LEVEL 3: Service/version identification
LEVEL 4: Tool-generated vulnerability suggestion
LEVEL 5: Generic knowledge that software may be vulnerable
```

Never exploit based solely on Level 4 or Level 5 evidence when Level 1/2 validation is possible.

---

# 1. Identify the Target

**Phase:** target_identification

Determine exactly which vulnerable container is being assessed.

Obtain:

- IP address
- hostname
- reachable protocols
- exposed ports

If the target IP is already supplied by the CTF platform, use that address rather than attempting unnecessary discovery.

### Phase Completion

- [ ] Target IP/hostname confirmed
- [ ] Target is reachable (or reachability failure recorded)
- [ ] notes.md STATE block updated

---

# 2. Reconnaissance

**Phase:** network_recon, port_enumeration

Start with a broad view of the target.

Questions:

- Is the host reachable?
- Which ports are open?
- Which protocols are exposed?
- Is HTTP/HTTPS available?
- Is SSH available?
- Are databases exposed?
- Are unusual high ports exposed?

### Scan Budgets

| Scan | Budget | Justification Required |
|------|--------|----------------------|
| Initial TCP discovery | 1 scan | No |
| Service detection | 1 scan per port | No |
| Full TCP (-p-) | 1 scan | Yes |

Useful tools include:

- `nmap`
- `rustscan`
- `arp-scan`
- `ping`
- `netcat`

Start with a relatively fast scan, then perform more detailed scans against discovered services.

### Output Discipline

Save full nmap output to a file. Extract only the interesting results for reasoning:

```bash
nmap -Pn -sC -sV TARGET -oN /workspace/nmap-initial.txt
grep "open" /workspace/nmap-initial.txt
```

### Phase Completion

- [ ] Target reachability confirmed
- [ ] TCP ports identified
- [ ] Services identified
- [ ] Versions collected where possible
- [ ] notes.md attack surface table updated

---

# 3. Port Enumeration

**Phase:** port_enumeration

Do not stop after finding the first few ports.

A service listening on an unexpected port can be the intended attack vector.

Example workflow:

```bash
nmap -Pn -sC -sV TARGET
```

Then perform a broader TCP scan when appropriate (budget: 1 scan):

```bash
nmap -Pn -p- TARGET
```

Follow newly discovered ports with targeted enumeration.

For each port record:

```text
PORT
PROTOCOL
SERVICE
VERSION
NOTES
```

### Phase Completion

- [ ] All open ports identified
- [ ] Service version collected for each port
- [ ] notes.md attack surface table updated

---

# 4. Service Enumeration

**Phase:** service_enumeration

Every discovered service should have an enumeration strategy.

Examples:

| Service | Investigate |
|---|---|
| HTTP | directories, technologies, virtual hosts, parameters |
| HTTPS | certificates, routes, technologies, virtual hosts |
| SSH | version, authentication methods, usernames |
| FTP | anonymous access, files, version |
| SMB | shares, users, permissions |
| DNS | records, zones, subdomains |
| LDAP | directory information |
| MySQL | authentication, databases |
| PostgreSQL | authentication, databases |
| Redis | unauthenticated access, exposed data |
| NFS | exports and permissions |

Do not assume the service version alone represents the vulnerability.

### Phase Completion

- [ ] Each service has an enumeration plan
- [ ] Services enumerated according to plan
- [ ] Interesting findings recorded
- [ ] Hypotheses generated for promising services

---

# 5. Web Applications

**Phase:** web_enumeration

When HTTP or HTTPS is discovered, treat the web application as a separate enumeration target.

Determine:

- framework
- server
- application name
- application version
- technologies
- login pages
- administrative interfaces
- API endpoints
- hidden directories
- backup files
- configuration files
- parameters
- file upload functionality
- authentication mechanisms
- authorization behavior

Useful tools include:

- `curl`
- `wget`
- `whatweb`
- `nikto`
- `ffuf`
- `gobuster`
- `feroxbuster`
- browser developer tools
- Burp Suite

Do not rely on directory enumeration alone.

Manually inspect the application.

### Scan Budget

Use one directory enumeration tool initially. Expand only with evidence.

### Phase Completion

- [ ] Application technology identified
- [ ] Interesting endpoints known
- [ ] Authentication behavior understood
- [ ] Important parameters identified
- [ ] Attack surface mapped
- [ ] notes.md updated

---

# 6. Vulnerability Analysis

**Phase:** vulnerability_analysis

For each interesting service ask:

1. What software is running?
2. What version is running?
3. Is the version vulnerable?
4. Is the vulnerable functionality reachable?
5. Is authentication required?
6. Can the vulnerability be reproduced?
7. What access would exploitation provide?

Useful resources and tools include:

- `searchsploit`
- Nmap NSE scripts
- service-specific enumeration tools
- local exploit references
- application source code
- configuration inspection

### Hypothesis Tracking

Every potential vulnerability is a hypothesis. Track it:

```text
H#N: <statement>
CONFIDENCE: High / Medium / Low
EVIDENCE FOR: <list>
EVIDENCE AGAINST: <list>
TESTS PERFORMED: <count>
NEXT TEST: <what to try>
ABANDON IF: <condition>
```

A vulnerability should be treated as a hypothesis until validated.

### Phase Completion

- [ ] Vulnerability hypotheses generated for each service
- [ ] Hypotheses ranked by evidence strength
- [ ] Top hypotheses selected for testing
- [ ] notes.md hypotheses table updated

---

# 7. Exploitation

**Phase:** exploitation

Prioritize attack paths by scoring:

```text
ATTACK PATH SCORE

Evidence strength       0-5
Likelihood              0-5
Reliability             0-5
Required privileges     0-5
Expected access         0-5

Total: /25
```

Score each candidate path. Choose the highest-scoring path.

Prefer simple, reliable exploitation over unnecessarily complex attacks.

After obtaining access, immediately establish:

```text
Who am I?
Where am I?
What system am I on?
What privileges do I have?
What network access do I have?
What useful credentials or files are available?
```

### Phase Completion

- [ ] Attack path selected and justified
- [ ] Exploitation attempted
- [ ] Access level recorded (or failure recorded in DEAD ENDS)
- [ ] notes.md ACCESS table updated

---

# 8. Initial Access Enumeration

**Phase:** initial_access

Once inside a target, enumerate the local environment.

Useful commands:

```bash
id
whoami
hostname
uname -a
pwd
ip addr
ip route
env
```

Then investigate:

- users
- groups
- processes
- services
- scheduled tasks
- SUID binaries
- capabilities
- writable files
- configuration files
- credentials
- SSH keys
- application secrets
- environment variables

### Privilege-Level Tracking

Track your current access:

```text
CURRENT USER:
UID:
GROUPS:
SUDO:
CAPABILITIES:
SHELL:
CONTAINER:
HOST:
NETWORK ACCESS:
```

After any privilege change, update this block.

### Phase Completion

- [ ] Current user/privileges documented
- [ ] Local environment enumerated
- [ ] Privilege escalation hypotheses generated
- [ ] notes.md updated

---

# 9. Privilege Escalation

**Phase:** privilege_escalation

Privilege escalation should be evidence-driven.

Investigate:

- `sudo`
- SUID/SGID binaries
- Linux capabilities
- cron jobs
- systemd services
- writable service files
- writable scripts
- PATH hijacking
- credentials
- exposed secrets
- kernel information
- container configuration
- Docker access

Useful tools include:

- `linpeas`
- `pspy`
- `sudo`
- `find`
- `getcap`
- `systemctl`

Do not assume a tool's output is automatically exploitable.

Validate the finding.

### Hypothesis Tracking

Track each privesc vector as a hypothesis with the standard format.

### Phase Completion

- [ ] Privesc vectors investigated
- [ ] Hypotheses tracked and ranked
- [ ] Escalation attempted (or failure recorded)
- [ ] Current privilege level updated
- [ ] notes.md PRIVESC table updated

---

# 10. Credential Reuse

Whenever credentials are discovered, determine where they may legitimately work within the challenge environment.

Check:

- local accounts
- SSH
- web applications
- databases
- SMB
- other services discovered on the target

Record credentials in `notes.md` using the CREDENTIAL format.

Never assume a discovered username/password pair is useless simply because it failed in one location.

---

# 11. Lateral Movement

If the challenge contains multiple intentionally vulnerable containers, investigate whether the compromised host provides access to other challenge hosts.

Look for:

- additional network interfaces
- routing information
- internal hostnames
- DNS records
- credentials
- configuration files
- SSH keys
- application secrets
- internal services

Treat every newly discovered host as a new enumeration target.

---

# 12. Flag Hunting

**Phase:** flag_hunting

Once sufficient access is obtained, search methodically.

### Priority Order

Search these locations in order:

1. `/home/*/`
2. `/root/`
3. `/opt/`
4. `/var/www/`
5. `/srv/`
6. `/tmp/`

Then search based on discovered challenge/application context.

Prefer targeted searches:

```bash
find / -name "flag*" -o -name "*.flag" -o -name "proof*" 2>/dev/null
grep -r "FLAG{" /home/ /root/ /opt/ /var/www/ /srv/ 2>/dev/null
```

Do not stop after finding one flag if the challenge may contain multiple objectives.

### Phase Completion

- [ ] All priority locations searched
- [ ] Flags found and recorded
- [ ] Flag values verified
- [ ] notes.md FLAGS table updated

---

# 13. Verification

**Phase:** verification

Before declaring success:

- reproduce the successful attack
- verify the privilege level
- verify the flag
- confirm which vulnerability enabled the attack
- record the minimal successful attack path

The final result should explain:

```text
Initial Access:
    vulnerability -> exploit -> shell

Privilege Escalation:
    weakness -> exploit -> elevated shell

Flag:
    location -> flag
```

### Minimum Successful Path

Record the shortest verified chain:

```text
ENTRY -> EXPLOIT -> SHELL -> PRIVESC -> FLAG
```

Only continue if:

- additional flags may exist
- additional hosts are in scope
- another objective is indicated
- the current access is not sufficient

### Phase Completion

- [ ] Attack reproduced
- [ ] Privilege level verified
- [ ] Flags verified
- [ ] Minimal attack path recorded
- [ ] Final result block written to notes.md

---

# 14. Adaptation

The methodology is iterative.

If an attack fails:

1. Record why it failed in DEAD ENDS.
2. Reassess the assumptions.
3. Form a fundamentally different hypothesis.
4. Look for alternative attack paths.
5. Return to enumeration if necessary.

Do not repeatedly retry a failed technique without new evidence.

### Dead-End Registry

When abandoning a path, record:

```text
DEAD END: <path or technique>
REASON: <why it failed>
TESTS: <what was tried>
CONCLUSION: <summary>
DO NOT REVISIT unless new evidence appears
```

Before starting any new action, check the DEAD ENDS section to avoid repeating failed approaches.
