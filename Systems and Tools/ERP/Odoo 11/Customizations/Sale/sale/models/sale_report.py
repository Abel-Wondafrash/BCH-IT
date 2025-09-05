from odoo import fields, models


class SaleReport(models.Model):
    _inherit = "sale.report"

    location = fields.Many2one('sale.locations', 'Location')
    plate_no = fields.Char(string='Plate No')

    def _select(self):
        return super(SaleReport, self)._select() + ", s.location as location"

    def _group_by(self):
        return super(SaleReport, self)._group_by() + ", s.location"

    def _select(self):
        return super(SaleReport, self)._select() + ", s.plate_no as plate_no"

    def _group_by(self):
        return super(SaleReport, self)._group_by() + ", s.plate_no"

