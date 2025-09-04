# Odoo 11 Custom Modules

This section documents custom-developed modules for Odoo 11, including new functionality, field extensions, and enhancements to support business-specific requirements.

---

## Added Export Wizard for Payment Requests with Date Filtering

- **Issue**: No built-in method exists to export payment request data, forcing users to manually copy data or rely on technical exports, increasing effort and risk of inconsistency.
- **Solution**: Implement a user-friendly CSV export wizard accessible from the reporting menu, allowing filtered data extraction.
  - **Features**:
    - Accessible via **Payment Requests > Reporting > Export Payment Requests**
    - Exports the following fields:
      - Request Number
      - Requested By
      - Department
      - Description
      - Amount
      - Approval Status
      - Approved By
      - Approved On
      - Created On
    - Filters:
      - **Start Date / End Date**: Limit export to a specific period
      - **Approved Only**: Pre-checked to include only approved requests (can be unchecked)
    - Output: Downloadable CSV file with timestamped filename
  - **Implementation**:
    - Created wizard model `payment.request.export` with:
      ```python
      start_date = fields.Date(string='Start Date')
      end_date = fields.Date(string='End Date')
      approved_only = fields.Boolean(string='Approved Only', default=True)
      ```
    - Defined wizard form view and action.
    - On confirmation, query filtered payment requests:
      ```python
      domain = [('state', '!=', 'draft')]
      if self.approved_only:
          domain.append(('selection_field', '=', 'approved'))
      if self.start_date:
          domain.append(('create_date', '>=', self.start_date))
      if self.end_date:
          domain.append(('create_date', '<=', self.end_date))
      ```
    - Generate CSV with `io.StringIO` and return via `request.make_response`.
    - Added menu item under **Reporting** with appropriate group restrictions.
  - Restart Odoo and upgrade `payment_request` module.
  - After deployment, users can export payment request data with one click, enabling efficient financial analysis and audit preparation.

---
