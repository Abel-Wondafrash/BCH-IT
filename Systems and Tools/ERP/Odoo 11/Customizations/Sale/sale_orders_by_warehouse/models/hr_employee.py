# -*- coding: utf-8 -*-
from odoo import models, fields

class HrEmployee(models.Model):
    _inherit = "hr.employee"

    is_parcel_dispatcher = fields.Boolean(string="Parcel Dispatcher")
