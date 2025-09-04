# Odoo 11 Custom Modules

This section documents custom-developed modules for Odoo 11, including new functionality, field extensions, and enhancements to support business-specific requirements.

---

## Added Purchase Requests CSV Export Wizard with Filtering

- **Issue**: Users lack a built-in way to export purchase request data for reporting, requiring manual data extraction that is time-consuming and error-prone.
- **Solution**: Develop a dedicated export wizard that generates a filtered CSV with key purchase request details.

  - **Features**:
    - Accessible via **Purchases > Export > Export Purchase Requests**
    - Exports the following fields:
      - Request ID
      - Requested By
      - Department
      - Site
      - Description (product name + optional line description)
      - UoM
      - Quantity
      - Unit Price
      - Total Price
      - Created On
      - Approved On
    - Filters:
      - Date Range (Start Date / End Date)
      - Approved Only (checkbox)
    - Security: Restricted to users in `group_purchase_reporter`
  - **Implementation**:

    - Created module `purchase_request_export` with:
      - Wizard model: `purchase.request.export.wizard`
      - Form and action views
      - Controller or server action to generate CSV
    - Sample CSV generation logic:

      ```python
      def action_export_csv(self):
          # Apply filters
          domain = []
          if self.start_date: domain.append(('date_order', '>=', self.start_date))
          if self.end_date: domain.append(('date_order', '<=', self.end_date))
          if self.approved_only: domain.append(('state', '=', 'PR Approved'))

          requests = self.env['purchase.request'].search(domain)

          output = io.StringIO()
          writer = csv.writer(output)
          writer.writerow([
              'Request ID', 'Requested By', 'Department', 'Site', 'Description',
              'UoM', 'Quantity', 'Unit Price', 'Total Price', 'Created On', 'Approved On'
          ])

          for req in requests:
              for line in req.line_ids:
                  writer.writerow([
                      req.name,
                      req.create_uid.name,
                      req.department_id.name,
                      req.site_id.name,
                      f"{line.product_id.name} {line.name or ''}".strip(),
                      line.uom_id.name,
                      line.qty,
                      line.unit_price,
                      line.total_price,
                      req.date_order,
                      req.approve_date or ''
                  ])

          # Return HTTP response with CSV
      ```

    - Added menu item under **Purchases > Export**

  - Restart Odoo and install the module.
  - After deployment, authorized users can export filtered, structured purchase request data with one click.

---
