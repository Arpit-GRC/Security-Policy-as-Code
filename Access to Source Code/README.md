ISO/IEC 27002:2022 — Control 8.4  
## Access to Source Code (From Paper Compliance to Enforceable Controls)

---

## Overview

Most organizations claim compliance with **ISO/IEC 27002:2022 – Control 8.4 (Access to Source Code)**.  
In practice, this control is often implemented through **policies, procedures, and manual reviews**, creating a gap between **control intent** and **control reality**.

This repository demonstrates how **GRC Engineering** can be used to implement ISO 27002:8.4 as **enforceable, non-bypassable guardrails**, rather than paper-based controls.

This is **not**:
- A DevSecOps pipeline demo  
- A GitHub hardening checklist  
- A policy document repository  

This **is**:
- A reference implementation of **policy-as-code for GRC**
- A practical example of turning compliance requirements into **system-enforced controls**
- A demonstration of **continuous, provable compliance**

---

## Control in Scope

**ISO/IEC 27002:2022 — Control 8.4: Access to Source Code**

> Read and write access to source code, development tools and software libraries should be appropriately managed to prevent the introduction of unauthorized functionality, avoid unintentional or malicious changes, and maintain the confidentiality of valuable intellectual property.

---

## Why Traditional GRC Fails for Control 8.4

Traditional implementations typically rely on:
- Written access control policies  
- Manual approval workflows  
- Periodic access reviews  
- Audit-time evidence collection  

This approach leads to:
- Privilege creep over time  
- Inconsistent enforcement across teams  
- Detection of violations only during audits  
- High audit effort with low real assurance  

**Root cause:** controls are documented, but **not enforced by design**.

---

## The GRC Engineering Approach

**GRC Engineering principle:**

> Governance defines what must never be possible.  
> Engineering ensures it never becomes possible.

In this model:
- Controls are **machine-readable**
- Enforcement is **automatic**
- Violations are **prevented**, not detected later
- Audit evidence is **generated continuously**

Audits become **validation**, not discovery.

---

## Guardrails Implementing ISO 27002:8.4

Each guardrail represents a **hard control boundary**, not a guideline.

---

### 1. Access Policy Guardrail  
**File:** `access-policy.yaml`

**ISO intent:**  
Control read and write access to source code based on role and risk.

**Traditional GRC:**  
- Policy statements  
- Manual approvals  
- Periodic access reviews  

**GRC Engineering enforcement:**  
- Default-deny access model  
- Explicit separation of read vs write access  
- MFA, device posture, and network constraints  
- Just-in-time, time-bound privileged write access  

**Risk reduced:**  
Unauthorized access, privilege creep, IP exposure

---

### 2. Branch Protection Guardrail  
**File:** `branch-protection.yaml`

**ISO intent:**  
Prevent unauthorized or unreviewed changes to source code.

**Traditional GRC:**  
- Change management procedures  
- Developer guidelines  

**GRC Engineering enforcement:**  
- Protected main branches  
- No direct commits or force pushes  
- Mandatory peer review  
- Mandatory code owner approval  
- Required security checks before merge  

**Risk reduced:**  
Unauthorized, accidental, or malicious code changes

---

### 3. Commit Integrity Guardrail  
**File:** `commit-integrity.yaml`

**ISO intent:**  
Ensure integrity and accountability of source code changes.

**Traditional GRC:**  
- Trust-based accountability  
- Manual review of commit history  

**GRC Engineering enforcement:**  
- Signed commits only  
- Trusted signing authorities enforced  
- History rewrite blocked  

**Risk reduced:**  
Code tampering, lack of attribution, non-repudiation failures

---

### 4. Dependency / Supply Chain Guardrail  
**File:** `dependency-policy.yaml`

**ISO intent:**  
Prevent introduction of unauthorized or malicious functionality.

**Traditional GRC:**  
- Developer awareness  
- Informal reviews  

**GRC Engineering enforcement:**  
- Controlled dependency sources  
- Restricted publishing and modification rights  
- Supply-chain boundaries enforced  

**Risk reduced:**  
Dependency poisoning, third-party code abuse

---

### 5. Audit Logging Guardrail  
**File:** `audit-logging.yaml`

**ISO intent:**  
Maintain audit logs of all access and changes to source code.

**Traditional GRC:**  
- Logs spread across tools  
- Manual evidence collection during audits  

**GRC Engineering enforcement:**  
- Access, changes, approvals, and denials logged automatically  
- Tamper-evident retention  
- Continuous export to a dedicated audit evidence store  

**Risk reduced:**  
Audit gaps, delayed detection, manual evidence effort

---

## GRC Enforcement Layer

Guardrails are enforced through a dedicated **GRC enforcement layer**, which includes:

- **GitHub Actions** — PR gating, signature verification, approval enforcement  
- **Terraform** — Consistent branch protection and repository settings  
- **Scripts** — Policy synchronization, validation, and drift detection  

This layer ensures:
- Controls cannot be bypassed  
- Enforcement is consistent at scale  
- Drift from policy is detectable  

---

## Audit Evidence and Continuous Assurance

Audit evidence is:
- Generated automatically by the system  
- Stored in a dedicated `audit-evidence` repository  
- Append-only and tamper-evident  
- Available at any time, not only during audits  

Auditors validate **operating effectiveness**, not reconstruct history.

---

## Why This Approach Works

| Traditional GRC | GRC Engineering |
|-----------------|----------------|
| Documents intent | Enforces behavior |
| Relies on people | Relies on systems |
| Point-in-time audits | Continuous assurance |
| Manual evidence | Automatic evidence |
| Detects late | Prevents early |

Compliance becomes a **side-effect of good control design**.

---

## Framework Alignment

Although demonstrated using **ISO/IEC 27002:8.4**, the same guardrail pattern aligns with:

- SOC 2 (CC6, CC8)  
- NIST SP 800-53 (AC, CM, SA families)  
- PCI DSS (access and change control requirements)  

This approach is **framework-agnostic**.


## Key Takeaway

If access to source code is only documented, it will eventually fail.  
If access to source code is engineered, it becomes reliable.

This repository demonstrates what **modern, enforceable GRC** looks like.

---


