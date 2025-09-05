from odoo import models, fields

class ResPartner(models.Model):
    _inherit = 'res.partner'

    inital_balance = fields.Float(
        string="Initial Balance",
        track_visibility='onchange'
    )
