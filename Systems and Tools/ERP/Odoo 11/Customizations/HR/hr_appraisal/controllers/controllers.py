# -*- coding: utf-8 -*-
from odoo import http

# class HrAppraisal(http.Controller):
#     @http.route('/hr_appraisal/hr_appraisal/', auth='public')
#     def index(self, **kw):
#         return "Hello, world"

#     @http.route('/hr_appraisal/hr_appraisal/objects/', auth='public')
#     def list(self, **kw):
#         return http.request.render('hr_appraisal.listing', {
#             'root': '/hr_appraisal/hr_appraisal',
#             'objects': http.request.env['hr_appraisal.hr_appraisal'].search([]),
#         })

#     @http.route('/hr_appraisal/hr_appraisal/objects/<model("hr_appraisal.hr_appraisal"):obj>/', auth='public')
#     def object(self, obj, **kw):
#         return http.request.render('hr_appraisal.object', {
#             'object': obj
#         })