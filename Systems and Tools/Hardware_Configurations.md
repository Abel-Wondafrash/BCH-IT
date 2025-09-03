# Hardware Configurations

This section documents configurations and fixes for hardware peripherals, such as printers, scanners, and other devices, to ensure optimal functionality in business operations.

---

## Printer Configuration for A5 Draft Printing with Landscape Feed (Model IP: 192.168.1.180)

- **Issue**: Printer settings must be precisely configured to support A5 paper, draft/economode quality, and landscape feed orientation for label or document printing; incorrect setup order or conflicting settings can lock out color mode or cause misalignment.
- **Solution**: Configure both Windows driver and web interface settings in correct sequence to ensure consistent behavior.
  - **Step 1: Windows Printer Setup**
    - Go to **Settings > Devices > Printers & Scanners**.
    - Click **Add a printer or scanner** > **Add printer**.
    - Select the target printer > **Manage** > **Printing Preferences**.
    - Under **Printing Shortcuts** tab:
      - **Paper size**: A5
      - **Paper source**: Tray 1
      - **Paper type**: Unspecified
      - **Print on both sides**: No
      - **Pages per sheet**: 1
    - Under **Paper/Quality** tab:
      - **Print Quality**: Economode
  - **Step 2: Web Interface Setup (https://192.168.1.180)**
    - Navigate to: `https://192.168.1.180/#hId-pgPrintSettings`
    - Enter PIN: `28651792`
    - Set **Print Quality** to _Draft_
    - Click **Apply**
    - Navigate to: `https://192.168.1.180/#hId-pgTrayAndPaperMgmt`
    - Go to **Advanced** > Set **A5 Feed Orientation** to _Landscape_
    - Click **Apply**
  - **Important**: Follow steps **in order**. Misconfiguration may cause Windows driver settings to override web settings, disabling color mode.
  - **If settings are locked**: Perform a **Secure Erase**:
    - Go to `https://192.168.1.180/#hId-pgSecureErase`
    - Click **Start Secure Erase** > Confirm with **Yes**
    - Reapply the above configuration steps.

---
