# CNET Errors & Fixes

This file lists common errors and their solutions.

## POS Machine not communicating with CNET

- **Error:** Failed to open fiscal printer serial port. Please check serial parameter setting or check printer connection
- **Solution:**
  - Restart CNET POS and recheck
  - Check for a faulty connecting (USB) cable, replace, and recheck
  - See if restarting the POS machine itself and restarting CNET after is a fix
- **Note:** If this happens during receipt saving, ensure FS Number isn’t already in CNET Documents so as not to make a double entry.
