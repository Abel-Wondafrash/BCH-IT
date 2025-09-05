# -*- coding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

import uuid

from itertools import groupby
from datetime import datetime, timedelta
from werkzeug.urls import url_encode

from odoo import api, fields, models, _
from odoo.exceptions import UserError, AccessError
from odoo.osv import expression
from odoo.tools import float_is_zero, float_compare, DEFAULT_SERVER_DATETIME_FORMAT

from odoo.tools.misc import formatLang

from odoo.addons import decimal_precision as dp

from xml.dom import minidom
import os
import xml.etree.ElementTree as etree
import os.path

import logging

_logger = logging.getLogger(__name__)



class SaleLocations(models.Model):
    _name = "sale.locations"
    name = fields.Char(string='Sale location', required=True)
    description = fields.Char(string='Description', required=True)
    is_rural = fields.Boolean(string='Is Rural')
    # plate_no = fields.Char(string='Plate No')
    pricelist_id = fields.Many2one('product.pricelist', string="Default Pricelist", required=True)



