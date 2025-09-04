from odoo import http
from odoo.http import request
import csv
import io
from datetime import datetime

class ExportCustomerBalanceController(http.Controller):

    @http.route('/export/customers_balance', type='http', auth='user')
    def export_customers_balance(self, **kwargs):
        query = """
        SELECT
            p.name,
            p.partner_code,
            COALESCE(
                p.inital_balance
                + COALESCE((
                    SELECT SUM(am.amount_val)
                    FROM account_move am
                    WHERE am.partner = p.id
                    AND am.state = 'posted'
                    AND am.ref LIKE 'BKDP%'
                ), 0)
                - COALESCE((
                    SELECT SUM(amr.amount_val)
                    FROM account_move am
                    JOIN account_move amr ON amr.ref = CONCAT('reversal of: ', am.name)
                    WHERE am.partner = p.id
                    AND am.state = 'posted'
                    AND am.ref LIKE 'BKDP%'
                    AND amr.state = 'posted'
                    AND amr.partner = p.id
                ), 0)
                - COALESCE((
                    SELECT SUM(ai.amount_total)
                    FROM account_invoice ai
                    WHERE ai.partner_id = p.id
                    AND ai.state = 'paid'
                    AND ai.type = 'out_invoice'
                ), 0)
                + COALESCE((
                    SELECT SUM(ai.amount_total)
                    FROM account_invoice ai
                    WHERE ai.partner_id = p.id
                    AND ai.state = 'open'
                    AND ai.type = 'out_refund'
                ), 0)
            , 0) AS current_balance
        FROM res_partner p
        WHERE
            p.customer = 't'
            AND p.active = 't'
            AND p.partner_code IS NOT NULL
            AND p.vat IS NOT NULL
        """

        request.cr.execute(query)
        rows = request.cr.fetchall()

        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(['Name', 'Partner Code', 'Current Balance'])
        for row in rows:
            writer.writerow(row)

        csv_data = output.getvalue()
        output.close()

        timestamp = datetime.now().strftime("ccb-%b-%d-%Y-%H-%M-%S").upper()
        filename = f"{timestamp}.csv"

        return request.make_response(
            csv_data,
            headers=[
                ('Content-Disposition', f'attachment; filename="{filename}"'),
                ('Content-Type', 'text/csv')
            ]
        )
