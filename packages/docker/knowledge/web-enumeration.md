# Web Enumeration

## Purpose

Identify functionality, technologies, endpoints, authentication mechanisms, files, parameters, and vulnerabilities in HTTP/HTTPS applications.

## When to Use

Use when HTTP or HTTPS is discovered during reconnaissance or service enumeration.

## Inputs Required

- Target IP or hostname
- Open HTTP/HTTPS ports
- Any discovered virtual hostnames

## Questions to Answer

- What technology stack is the application built on?
- What endpoints and directories exist?
- How does authentication work?
- What parameters are exposed?
- What is the attack surface?

---

# 1. Identify the Application

Start with:

```bash
curl -i http://TARGET/
```

Then inspect technology:

```bash
whatweb http://TARGET/
```

Look for:

- server
- framework
- CMS
- programming language
- application version
- cookies
- redirects
- authentication
- interesting headers

---

# 2. Inspect Manually

Fetch important pages:

```bash
curl -i http://TARGET/
curl -i http://TARGET/login
curl -i http://TARGET/robots.txt
```

Check:

```text
robots.txt
sitemap.xml
security.txt
login pages
registration
password reset
admin interfaces
API endpoints
file upload functionality
```

---

# 3. Directory Enumeration

Use one enumeration tool initially.

Example:

```bash
ffuf -u http://TARGET/FUZZ \
     -w /usr/share/wordlists/dirb/common.txt
```

Alternative:

```bash
gobuster dir \
    -u http://TARGET/ \
    -w /usr/share/wordlists/dirb/common.txt
```

Investigate interesting responses manually.

Pay attention to:

- 200
- 204
- 301
- 302
- 401
- 403
- unusual response sizes

### Information-Gain

Before running directory enumeration, state:

```text
WHAT QUESTION: What directories and files exist on this application?
EXPECTED RESULT: A list of accessible paths
WHAT I'LL DO WITH IT: Identify endpoints for further testing
```

Do not run a second enumeration tool unless the first produces results that justify it.

---

# 4. File Extensions

If the application appears to use a particular technology, enumerate relevant extensions.

For example:

```bash
ffuf -u http://TARGET/FUZZ \
     -w /usr/share/wordlists/dirb/common.txt \
     -e .php,.txt,.bak,.old,.zip
```

Choose extensions based on evidence about the target.

Do not blindly enumerate every possible extension.

---

# 5. Virtual Hosts

If the server appears to use name-based routing, investigate virtual hosts.

Potential clues include:

- redirects
- TLS certificates
- page content
- DNS
- HTTP headers
- application references

Use discovered hostnames rather than blindly generating huge numbers of candidates.

---

# 6. Parameters

Identify parameters in:

- GET requests
- POST requests
- forms
- APIs
- cookies
- JSON bodies
- URL paths

Interesting parameters may indicate:

```text
file
path
url
redirect
id
user
page
cmd
query
search
template
```

Treat these as candidates for further testing, not automatic vulnerabilities.

### Hypothesis Tracking

For each interesting parameter, create a hypothesis:

```text
H#N: Parameter <name> may allow <injection type>.
CONFIDENCE: Low (until tested)
EVIDENCE FOR: Parameter exists, accepts user input
EVIDENCE AGAINST: <none yet>
NEXT TEST: Send controlled input and observe behavior
ABANDON IF: No behavioral difference after targeted validation
```

---

# 7. Authentication

Investigate:

- default credentials
- registration
- password reset
- session cookies
- authorization checks
- role separation
- exposed administrative endpoints

If credentials are discovered elsewhere on the target, test whether they are reused by the application.

---

# 8. Vulnerability Investigation

Potential areas include:

- SQL injection
- command injection
- path traversal
- local/remote file inclusion
- insecure file upload
- server-side request forgery
- authentication bypass
- broken access control
- template injection
- deserialization
- exposed secrets
- vulnerable dependencies

Use the application's behavior and discovered technology stack to prioritize testing.

### Evidence Hierarchy

Before exploiting, classify your evidence:

- Level 1-2: Direct observation, reproducible output -> may proceed
- Level 3: Service/version identification -> proceed with caution
- Level 4-5: Tool suggestion, generic knowledge -> must validate first

---

# 9. Burp Suite

Use Burp when manual request manipulation is required.

Useful workflows include:

```text
Browser
   |
Burp Proxy
   |
Application
```

Use Burp to inspect and modify:

- headers
- cookies
- parameters
- request methods
- JSON
- authorization information

---

# Notes

Record useful findings in `notes.md`.

For each interesting endpoint record:

```text
URL:
Method:
Parameters:
Authentication:
Interesting behavior:
Potential vulnerability:
Evidence:
```

---

## Common Misinterpretations

- **A parameter is not a vulnerability.** A parameter accepting user input is expected behavior. The vulnerability is in how it is processed.
- **403 does not mean unreachable.** It means access is denied. The resource may exist. Try other methods, paths, or credentials.
- **Directory enumeration completeness is not guaranteed.** Wordlists are limited. Missing a directory does not mean it does not exist.
- **Technology detection is approximate.** `whatweb` and headers report the best guess. Verify manually.

---

## Scan Budget

| Action | Budget | Justification Required |
|--------|--------|----------------------|
| Directory enumeration (primary tool) | 1 | No |
| Additional enumeration tool | 1 | Yes (evidence must justify) |
| File extension enumeration | 1 | No |
| Virtual host enumeration | 1 | Yes (only if vhost routing suspected) |

---

## Stop Condition

Move from web enumeration to vulnerability analysis when:

- application technology is identified
- interesting endpoints are known
- authentication behavior is understood
- important parameters are identified
- likely attack surfaces have been identified

---

## Phase Completion

- [ ] Application technology identified
- [ ] Endpoints and directories enumerated
- [ ] Authentication behavior understood
- [ ] Parameters identified and recorded
- [ ] Vulnerability hypotheses generated
- [ ] notes.md updated with findings
- [ ] STATE block updated to next phase
