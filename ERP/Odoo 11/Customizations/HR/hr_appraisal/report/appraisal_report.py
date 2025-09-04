# class hr_appraisal(models.Model):
#     _name = 'appraisal.report'
    
#     job_id = fields.Many2one('hr.job', "Job Title",readonly="True")
#     employee_name =fields.Many2one('hr.employee',"Employee",required=True)
#     date = fields.Datetime("Date",readonly="True",default=fields.Datetime.now)
#     date_from = fields.Datetime("From",required=True)
#     date_to = fields.Datetime("To",required=True)
#     total = fields.Float("Total",readonly="True")
#     average = fields.Float("Average",readonly="True")
#     immediate_supervisor = fields.Many2one('hr.employee', string="Immediate Supervisor",readonly=True,default=_default_employee)
#     productivity=fields.Selection(evaluation_Methods, "Productivity",help="Great commitment to intensify the outpu.t")
#     work_quality=fields.Selection(evaluation_Methods, "Quality of Work Accuracy",help="Neatness and thoroughness of work effort.")
#     job_knowledge=fields.Selection(evaluation_Methods, "Knowledge of Job",help="Demonstrates the knowledge of fundamental methods and procedures of job.")
#     team_work=fields.Selection(evaluation_Methods, "Teamwork Ability",help="To work well with co-workers and supervisors.")
#     independence=fields.Selection(evaluation_Methods, "Independence",help="Ability to work independently, be resourceful and display initiative.")
#     guest_service=fields.Selection(evaluation_Methods, " Guest Service",help="Ability to work independently, be resourceful and display initiative.")
#     record_report=fields.Selection(evaluation_Methods, "Records and Reports",help="Ability to deal with guests/customers in polite and helpful manner.")
#     safety=fields.Selection(evaluation_Methods, "Safety Ability ",help="To comply with precautions for safety of self and others.")
#     attendance=fields.Selection(evaluation_Methods, "Attendance ",help="Regularity of attendance and absence for legitimate reasons.")
#     character=fields.Selection(evaluation_Methods, "Character ",help="personality or the nature  of the worker for all responds and activities.")
#     new_skill=fields.Selection(evaluation_Methods, "Readiness to know new skills ",help="Self-initiation and eagerness to know new things and systems.")
#     obedience =fields.Selection(evaluation_Methods, "Obedience  ",help="Commitment to the order of immediate boss.")
#     leadership =fields.Selection(evaluation_Methods, "Leadership and Supervision (Management Only)",default="0",help="Ability to plan, organize and supervise so that jobs are completed.")
#     supervisor_comment=fields.Text()
#     employee_comment=fields.Text()
#     status=fields.Boolean(default=False)
    
#     @api.model_cr
#     def init(self):
#         tools.drop_view_if_exists(self._cr, 'appraisal_report')
#         self._cr.execute("""
#             create view appraisal_report as (
#                 WITH currency_rate as (%s)
#                 select
#                     min(l.id) as id,
#                     s.date_order as date_order,
#                     s.state,
#                     s.date_approve,
#                     s.dest_address_id,
#                     spt.warehouse_id as picking_type_id,
#                     s.partner_id as partner_id,
#                     s.create_uid as user_id,
#                     s.company_id as company_id,
#                     s.fiscal_position_id as fiscal_position_id,
#                     l.product_id,
#                     p.product_tmpl_id,
#                     t.categ_id as category_id,
#                     s.currency_id,
#                     t.uom_id as product_uom,
#                     sum(l.product_qty/u.factor*u2.factor) as unit_quantity,
#                     extract(epoch from age(s.date_approve,s.date_order))/(24*60*60)::decimal(16,2) as delay,
#                     extract(epoch from age(l.date_planned,s.date_order))/(24*60*60)::decimal(16,2) as delay_pass,
#                     count(*) as nbr_lines,
#                     sum(l.price_unit / COALESCE(cr.rate, 1.0) * l.product_qty)::decimal(16,2) as price_total,
#                     avg(100.0 * (l.price_unit / COALESCE(cr.rate,1.0) * l.product_qty) / NULLIF(ip.value_float*l.product_qty/u.factor*u2.factor, 0.0))::decimal(16,2) as negociation,
#                     sum(ip.value_float*l.product_qty/u.factor*u2.factor)::decimal(16,2) as price_standard,
#                     (sum(l.product_qty * l.price_unit / COALESCE(cr.rate, 1.0))/NULLIF(sum(l.product_qty/u.factor*u2.factor),0.0))::decimal(16,2) as price_average,
#                     partner.country_id as country_id,
#                     partner.commercial_partner_id as commercial_partner_id,
#                     analytic_account.id as account_analytic_id,
#                     sum(p.weight * l.product_qty/u.factor*u2.factor) as weight,
#                     sum(p.volume * l.product_qty/u.factor*u2.factor) as volume
#                 from purchase_order_line l
#                     join purchase_order s on (l.order_id=s.id)
#                     join res_partner partner on s.partner_id = partner.id
#                         left join product_product p on (l.product_id=p.id)
#                             left join product_template t on (p.product_tmpl_id=t.id)
#                             LEFT JOIN ir_property ip ON (ip.name='standard_price' AND ip.res_id=CONCAT('product.template,',t.id) AND ip.company_id=s.company_id)
#                     left join product_uom u on (u.id=l.product_uom)
#                     left join product_uom u2 on (u2.id=t.uom_id)
#                     left join stock_picking_type spt on (spt.id=s.picking_type_id)
#                     left join account_analytic_account analytic_account on (l.account_analytic_id = analytic_account.id)
#                     left join currency_rate cr on (cr.currency_id = s.currency_id and
#                         cr.company_id = s.company_id and
#                         cr.date_start <= coalesce(s.date_order, now()) and
#                         (cr.date_end is null or cr.date_end > coalesce(s.date_order, now())))
#                 group by
#                     s.company_id,
#                     s.create_uid,
#                     s.partner_id,
#                     u.factor,
#                     s.currency_id,
#                     l.price_unit,
#                     s.date_approve,
#                     l.date_planned,
#                     l.product_uom,
#                     s.dest_address_id,
#                     s.fiscal_position_id,
#                     l.product_id,
#                     p.product_tmpl_id,
#                     t.categ_id,
#                     s.date_order,
#                     s.state,
#                     spt.warehouse_id,
#                     u.uom_type,
#                     u.category_id,
#                     t.uom_id,
#                     u.id,
#                     u2.factor,
#                     partner.country_id,
#                     partner.commercial_partner_id,
#                     analytic_account.id
#             )
#         """ % self.env['res.currency']._select_companies_rates())
