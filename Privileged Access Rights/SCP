### Deployment Steps (Organization Root or Security OU)

Deploy the following SCP guardrails:

- **DenyAdminAccessToNonPrivilegedRoles**
- **BlockIAMPrivilegeEscalationForNonPrivilegedRoles**
- **RestrictPassRoleToAdminAndBreakGlass**

These SCPs enforce the core privileged access restrictions across all accounts within the OU or the entire organization.

---

### Define Privileged Roles

**Privileged Roles:**

- Admin-Role
- BreakGlass-Role

Both roles should have:

- Strong MFA enforcement  
- Short session durations  
- Assignment controlled through AWS IAM Identity Center  

These are the **only** roles allowed to perform administrative actions.

---

### Define Non-Privileged Roles

All other roles such as:

- DevOps roles  
- Developer roles  
- Automation or pipeline roles  

should follow **least-privilege IAM policies** appropriate to their duties.

Even if these roles are mistakenly assigned elevated permissions,  
the SCP guardrails will **block** any attempt to create, grant, or use privileged access.

---
