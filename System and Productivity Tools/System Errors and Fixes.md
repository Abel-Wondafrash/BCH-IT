# System Errors & Fixes

This section documents solutions for system-related issues spanning operating systems and environments, including configuration adjustments and error resolutions for user access, security policies, and system functionality.

---

## "The Referenced Account is Locked Out" Due to Excessive Failed Login Attempts

- **Issue**: Users encounter the error _"The Referenced Account is Locked Out"_ after exceeding the allowed number of failed login attempts, typically due to incorrect password entry.
- **Solution**: Temporarily bypass lockout by adjusting system date or disable lockout policy.
  - **Immediate Fix**:
    - Restart the machine.
    - At boot, enter **System Settings** (BIOS/UEFI or OS-level).
    - Change the **Date & Time** to a future date (beyond the lockout duration).
    - Restart and log in with the correct password.
    - After successful login, reset the system time to current.
  - **Permanent Fix**:
    - Press **Win + R**, type `secpol.msc`, and press Enter.
    - Navigate to **Account Policies > Account Lockout Policy**.
    - Double-click **Account lockout threshold**.
    - Set value to `0` (disabled) or increase to desired attempt limit.
    - Click **OK** to apply.
  - **Note**: Setting threshold to `0` disables lockout; use cautiously in secure environments.

---
