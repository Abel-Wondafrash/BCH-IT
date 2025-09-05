from odoo import http
from odoo.http import request
import csv
import io
from datetime import datetime

class ExportPaymentRequestController(http.Controller):

    @http.route('/export/payment_requests', type='http', auth='user')
    def export_payment_requests(self, start=None, end=None, approved='true', **kwargs):
        if not start or not end:
            return request.not_found()

        approved_only = approved.lower() == 'true'

        # Your SQL query, replace placeholders with %s for params
        query = """
        SELECT
            pr.name AS "Request ID",
            requester.name AS "Requested By",
            dept.name AS "Department",
            br.name AS "Site",
            pr.description AS "Description",
            NULL AS "UoM",
            NULL AS "Quantity",
            NULL AS "Unit Price",
            pr.amount_birr AS "Total Price",
            pr.start_datetime AS "Created On",
            pr.approve_date AS "Approved On"
        FROM payment_request pr
        LEFT JOIN hr_employee requester ON pr.requester_id = requester.id
        LEFT JOIN hr_department dept ON requester.department_id = dept.id
        LEFT JOIN hr_employee emp ON pr.employee_id = emp.id
        LEFT JOIN LATERAL (
            SELECT rp.name
            FROM res_partner rp
            WHERE pr.partner_id ~ '^\d+$' AND rp.id = pr.partner_id::integer
            LIMIT 1
        ) rp ON TRUE
        LEFT JOIN company_branch br ON pr.branch_2 = br.id
        LEFT JOIN res_users au ON pr.approve_uid = au.id
        LEFT JOIN res_partner approver_partner ON au.partner_id = approver_partner.id
        WHERE pr.start_datetime BETWEEN %s AND %s
        """

        if approved_only:
            query += " AND pr.approve_date IS NOT NULL"

        query += " ORDER BY pr.start_datetime ASC"

        request.cr.execute(query, (start, end))
        rows = request.cr.fetchall()

        # CSV Output
        output = io.StringIO()
        writer = csv.writer(output)
        # header names in order
        writer.writerow([
            "Request ID", "Requested By", "Department", "Site", "Description",
            "UoM", "Quantity", "Unit Price", "Total Price", "Created On", "Approved On"
        ])
        for row in rows:
            writer.writerow(row)

        csv_data = output.getvalue()
        output.close()

        filename = f"PYR-{start}-{end}.csv"

        return request.make_response(
            csv_data,
            headers=[
                ('Content-Disposition', f'attachment; filename="{filename}"'),
                ('Content-Type', 'text/csv')
            ]
        )
