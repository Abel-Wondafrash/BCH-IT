from datetime import datetime
import time
from odoo import api, models, _
from odoo.exceptions import UserError
from odoo.tools import DEFAULT_SERVER_DATE_FORMAT


class ReportPartnerLedger(models.AbstractModel):
    _name = 'report.account.report_partnerledger'
    
    def _sum_partner(self):
     return 7