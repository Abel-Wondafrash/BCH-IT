from odoo import models, fields, api
from odoo.http import request
from odoo.tools import DEFAULT_SERVER_DATE_FORMAT

class PaymentRequestExportWizard(models.TransientModel):
    _name = 'payment_request_export_wizard'
    _description = 'Wizard to export payment requests as CSV'

    start_date = fields.Date(string='Start Date', required=True)
    end_date = fields.Date(string='End Date', required=True)
    filter_approved = fields.Boolean(string='Approved Only', default=True)

    def action_export(self):
        url = '/export/payment_requests?start=%s&end=%s&approved=%s' % (
            self.start_date,
            self.end_date,
            'true' if self.filter_approved else 'false'
        )
        return {
            'type': 'ir.actions.act_url',
            'url': url,
            'target': 'self',
        }
