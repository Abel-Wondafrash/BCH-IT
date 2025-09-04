from odoo import models, fields, api
from odoo.exceptions import ValidationError

class ResPartnerBankDetail(models.Model):
    _name = 'res.partner.bank.detail'
    _description = 'Bank Detail for Contact'

    partner_id = fields.Many2one('res.partner', string='Partner', ondelete='cascade')
    account_number = fields.Char(string='Account Number')
    bank_name = fields.Many2one(
        'account.journal',
        string='Bank Name',
        domain=[('type', '=', 'bank')]
    )

    @api.model
    def create(self, vals):
        if 'account_number' in vals:
            cleaned = vals['account_number'].replace(" ", "")
            if not cleaned:
                raise ValidationError("Account Number cannot be empty.")
            vals['account_number'] = cleaned
        return super(ResPartnerBankDetail, self).create(vals)

    def write(self, vals):
        if 'account_number' in vals:
            cleaned = vals['account_number'].replace(" ", "")
            if not cleaned:
                raise ValidationError("Account Number cannot be empty.")
            vals['account_number'] = cleaned
        return super(ResPartnerBankDetail, self).write(vals)

class ResPartner(models.Model):
    _inherit = 'res.partner'

    bank_detail_ids = fields.One2many(
        'res.partner.bank.detail', 'partner_id', string='Bank Details'
    )
