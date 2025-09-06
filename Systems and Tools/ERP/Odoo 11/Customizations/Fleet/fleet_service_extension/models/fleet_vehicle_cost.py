from odoo import models, fields, api

class FleetVehicleCost(models.Model):
    _inherit = 'fleet.vehicle.cost'

    quantity = fields.Float(
        string="Quantity",
        default=1.0
    )
    total = fields.Float(
        string="Total",
        compute="_compute_total",
        store=True
    )

    @api.depends('quantity', 'amount')
    def _compute_total(self):
        for rec in self:
            rec.total = (rec.quantity or 0.0) * (rec.amount or 0.0)
