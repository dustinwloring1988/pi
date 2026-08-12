# Reconnaissance

## Purpose

Establish the basic identity and network accessibility of the target before performing detailed enumeration.

## When to Use

Use at the start of every engagement, and again when you need to verify reachability or discover additional hosts.

## Inputs Required

- Target IP or hostname (from CTF platform or challenge description)

## Questions to Answer

- Is the host reachable?
- Which TCP ports are open?
- Which services are running on each port?
- What versions are detected?
- Are there other hosts on the Docker network?

---

## Network Scope

Before scanning, determine the authorized network range.

```bash
ip addr
ip route
cat /etc/resolv.conf
```

Identify the Docker network range. Restrict all scanning to that range. Never scan external, host, or unrelated networks.

---

## Target Connectivity

Determine whether the target responds.

```bash
ping -c 3 TARGET
```

If ICMP is unavailable, do not assume the target is offline.

Proceed with TCP-based discovery.

---

## Nmap

### Basic scan

```bash
nmap -Pn TARGET
```

### Service detection

```bash
nmap -Pn -sC -sV TARGET
```

### All TCP ports

```bash
nmap -Pn -p- --min-rate 2000 TARGET
```

After discovering unusual ports, scan them specifically:

```bash
nmap -Pn -sC -sV -p PORTS TARGET
```

### Useful NSE categories

When appropriate:

```bash
nmap -Pn --script vuln TARGET
```

Use NSE results as leads rather than proof of exploitation.

---

## Scan Budgets

| Scan | Budget | Justification Required |
|------|--------|----------------------|
| Initial TCP discovery | 1 scan | No |
| Service detection per port | 1 scan | No |
| Full TCP (-p-) | 1 scan | Yes |
| NSE scripts | 1 targeted set | Yes |

Before running an expensive scan, state:

```text
WHY: <reason>
WHAT QUESTION: <specific question>
EXPECTED RESULT: <what you expect>
WHAT I'LL DO WITH IT: <how result changes approach>
```

---

## RustScan

If installed, RustScan can quickly identify candidate ports.

```bash
rustscan -a TARGET
```

Use Nmap for detailed service identification after discovering ports.

---

## Netcat

Test individual services:

```bash
nc -nv TARGET PORT
```

This can be useful for understanding whether a port is:

- HTTP
- a text protocol
- a database
- a custom service
- a remote shell interface

---

## Output Discipline

Save full nmap output to a file. Extract only the interesting results for reasoning:

```bash
nmap -Pn -sC -sV TARGET -oN /workspace/nmap-initial.txt
grep "open" /workspace/nmap-initial.txt
```

Never paste full scan output into your reasoning. Filter first.

---

## What to Record

After reconnaissance, update `notes.md`.

Record:

```text
Target:
IP:
Hostname:

Open Ports:
- PORT / PROTOCOL / SERVICE / VERSION

Interesting Findings:
- ...
```

Update the ATTACK SURFACE table in notes.md.

---

## Common Misinterpretations

- **No ICMP response does not mean offline.** Many hosts block ICMP. Always try TCP.
- **Filtered does not mean closed.** Filtered means a firewall is responding. The port may still be accessible through other means.
- **A port is not a vulnerability.** An open port is information. The vulnerability is in the service running on it.
- **Version detection is approximate.** `nmap -sV` reports the best guess. Verify manually.

---

## Stop Condition

Move to detailed enumeration when:

- target reachability is understood
- TCP ports have been identified
- services have been identified
- versions have been collected where possible

Do not repeatedly perform identical discovery scans without a reason.

---

## Phase Completion

- [ ] Target reachability confirmed
- [ ] TCP ports identified
- [ ] Services identified
- [ ] Versions collected
- [ ] notes.md ATTACK SURFACE table updated
- [ ] STATE block updated to next phase
