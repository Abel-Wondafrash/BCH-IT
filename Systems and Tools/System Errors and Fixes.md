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

## UPS (ECO-FLOW E980) Brief AC Output Interruption After Power Fluctuation

- **Issue**: The UPS briefly cuts AC output (~3–4 seconds) shortly after a power fluctuation or grid recovery, potentially disrupting connected equipment despite being in backup mode.
- **Solution**: Apply firmware updates and adjust power settings to maintain uninterrupted output.
  - **Step 1**: Update device firmware to latest stable version:
    - Recommended versions: `V1.0.1.200` or `V1.0.2.60`
    - Ensures improved power switching logic and stability during grid transitions.
  - **Step 2**: Enable "AC Always On" mode:
    - Navigate to: **Settings > Output > AC always on**
    - Set to **Enabled**
    - Ensures AC output resumes automatically after power-on or fluctuation.
    - _Note_: Slight increase in idle power consumption.
  - **Step 3**: Disable auto timeouts:
    - **Settings > Auto timeout > Device timeout > Never**
    - **Settings > Auto timeout > AC timeout > Never**
    - Prevents unintended shutdowns after periods of inactivity.
  - After applying these settings, the UPS maintains consistent AC output during and after power fluctuations, minimizing disruption to connected devices.

---
