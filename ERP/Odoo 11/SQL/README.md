# Database Fixes

This section documents solutions for database-related issues, including configuration adjustments and error resolutions for database management tools and systems.

---

## pgAdmin3 Fails to Launch: "wxbase28u_xml_vc_custom.dll Was Not Found" and Related DLL Errors

- **Issue**: pgAdmin3 fails to start with the error:  
  _"The code execution cannot proceed because wxbase28u_xml_vc_custom.dll was not found. Reinstalling the program may fix this problem."_  
  This occurs for multiple `wx*` DLLs (`wxbase28u_net_vc_custom`, `wxmsw28u_adv_vc_custom`, etc.) due to missing DLL paths in the system environment.
- **Solution**: Add the PostgreSQL bin directory from the Odoo 11 installation to the system PATH.
  - Press **Windows + Pause**, click **Advanced system settings**.
  - Click **Environment Variables** under System Variables.
  - Select **Path**, then click **Edit**.
  - Click **New** and add the following path:
    ```
    C:\Program Files (x86)\Odoo 11.0\PostgreSQL\bin
    ```
  - Click **OK** to save all changes.
  - Restart any open command prompts or pgAdmin3; the DLLs will now be resolved and the application should launch successfully.

---
