# CNET Errors & Fixes

This file lists common errors and their solutions.

## POS Machine not communicating with CNET

- **Error:** Failed to open fiscal printer serial port. Please check serial parameter setting or check printer connection
- **Solution:**
  - Restart CNET POS and recheck
  - Check for a faulty connecting (USB) cable, replace, and recheck
  - See if restarting the POS machine itself and restarting CNET after is a fix
- **Note:** If this happens during receipt saving, ensure FS Number isn’t already in CNET Documents so as not to make a double entry.
---

## Please register your device first
Comes up when trying to open any of CNET's .exe _(POS, BackOffice, +)_

This can happen as a result of a few different things:
  - **[1] Connectivity Issues:** Issue with network connectivity with Server (Possibly faulty cable, disconnected Wi-Fi, faulty net software/network card, +)
  - **[2] Service not Running:** The service 'CNET ERP V6 Service' is not running on the Server
  - **[3] Expired Password:** Microsoft SQL Server password has expired and needs to be changed
  - **[4] Misconfiguration:** CNET's 'ServiceConfigTool.exe' is misconfigured

### Solutions
**[1] Connectivity Issues:**
  - Check network connectivity (cable, Wi-Fi, ...)
  - Troubleshoot and Reset Network adapter
  - Restart computer

**[2] Service not Running:**
  - On the server's Services, start the service 'CNET ERP V6 Service'

**[3] Expired Password:**
  - On the server, open up 'SQL Server Management Studio' (SSMS)
  - In the 'Connect to Server' window, entering known password may show an error like:
    Cannot connect to ..... Additional information — Login failed for user 'sa'. (Microsoft SQL Server, Error: 18456)
    Trying again with another password brings:
    Cannot connect to ...
    _Additional information:_
    A connection was successfully established with the server, but then an error occurred during the login process. (providier: Shared memory Provider, error: 0 - No process is on the other end of the pipe.) (Microsoft SQL Server, Error: 233)
    No process is on the other end of the pipe

    **In rare cases where SSMS does not respond, restarting these services may be necessary.**
    'SQL Server (CNET)' and SQL Server Agent (CNET)
    
    **Enter password to in SSMS**
    Note the window that appears titled 'Change Password'
    _Your password is expired. You must enter another password before you can log on_
    
    **Providing a weak password brings another error:    **
    Password could not be changed. Microsoft.SqlServer.connectionInfo)
    Additional information:
    _Login failed for user 'sa'. Reason: Password change failed. The passowrd does not meet Windows policy requirements because it is not complex enough.
    Change database context to 'master'.
    Change language setting to us_english. (Microsoft SQL Server, Error: 18466)_

**[4] Misconfiguration:**
  - Open 'ServiceConfigTool.exe' on the POS computer
  - Change the password to the newly set password in SSMS
  - Click on 'Test Connection' to ensure correct entry
  - Click on 'Save' and close Window
---
