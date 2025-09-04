# -*- coding: utf-8 -*-
import logging
from datetime import datetime
from odoo import models, fields, api,_

from odoo.exceptions import UserError, AccessError
_logger = logging.getLogger(__name__)
evaluation_Methods = [
    
    ('1', '1'),
    ('2', '2'),
    ('3', '3'),
    ('4', '4'),
    ('5', '5'),
    ('0', 'N/A')
]
class ApprasalSubjectLine(models.Model):
    _name = 'appraisal.subject.line1'
    name = fields.Char(string='Subject Name', required=True)
    evaluation=fields.Float("Evaluation Point")
    out_of_val = fields.Float("Out Of")
    parameter_id = fields.Many2one('hr.appraisal', string='Parameter Reference', 
    index=True, ondelete='cascade')
    @api.onchange('evaluation')
    def _onchange_evaluation(self):
        _logger.info("------------------------------")
        _logger.info("------------------------------self.out_of_val=%s",self.out_of_val)
        _logger.info("------------------------------self.name=%s",self.name)
        _logger.info("------------------------------self.evaluation=%s",self.evaluation)
        
        if self.out_of_val:
            if self.evaluation > self.out_of_val:
                raise UserError(_("Evaluation point must be less than %s") % self.out_of_val)
    @api.model
    def create(self, vals):
        _logger.info("c------------------------------")
        _logger.info("------------------------------self.out_of_val=%s",self.out_of_val)
        _logger.info("c------------------------------vals.out_of_val=%s", vals.get('out_of_val'))
        _logger.info("c------------------------------vals.evaluation=%s", vals.get('evaluation'))
        
        if float(vals.get('evaluation')) > float(vals.get('out_of_val')) :
            raise UserError(_("Evaluation point must be less than %s") % vals.get('out_of_val'))
        else:
            return super(ApprasalSubjectLine, self).create(vals)
    
       

class hr_appraisal(models.Model):
    _name = 'hr.appraisal'
    def _default_employee(self):
        return self.env.context.get('default_employee_id') or self.env['hr.employee'].search([('user_id', '=', self.env.uid)], limit=1)
    

    job_id = fields.Many2one('hr.job', "Job Title",required=True)
    out_of = fields.Integer("Subject Maximum Point",required=True)
    subject_line = fields.One2many('appraisal.subject.line1', 'parameter_id', string='Subject Lines', copy=True)
    
    employee_name =fields.Many2one('hr.employee',"Employee",required=True)
    date = fields.Datetime("Date",readonly="True",default=fields.Datetime.now)
    date_from = fields.Datetime("From",required=True)
    date_to = fields.Datetime("To",required=True)
    total = fields.Float("Total",readonly="True")
    average = fields.Float("Average",readonly="True")
    immediate_supervisor = fields.Many2one('hr.employee', 
    string="Immediate Supervisor",default=_default_employee)
    # productivity=fields.Selection(evaluation_Methods, "Productivity",help="Great commitment to intensify the outpu.t")
    # work_quality=fields.Selection(evaluation_Methods, "Quality of Work Accuracy",help="Neatness and thoroughness of work effort.")
    # job_knowledge=fields.Selection(evaluation_Methods, "Knowledge of Job",help="Demonstrates the knowledge of fundamental methods and procedures of job.")
    # team_work=fields.Selection(evaluation_Methods, "Teamwork Ability",help="To work well with co-workers and supervisors.")
    # independence=fields.Selection(evaluation_Methods, "Independence",help="Ability to work independently, be resourceful and display initiative.")
    # guest_service=fields.Selection(evaluation_Methods, " Guest Service",help="Ability to work independently, be resourceful and display initiative.")
    # record_report=fields.Selection(evaluation_Methods, "Records and Reports",help="Ability to deal with guests/customers in polite and helpful manner.")
    # safety=fields.Selection(evaluation_Methods, "Safety Ability ",help="To comply with precautions for safety of self and others.")
    # attendance=fields.Selection(evaluation_Methods, "Attendance ",help="Regularity of attendance and absence for legitimate reasons.")
    # character=fields.Selection(evaluation_Methods, "Character ",help="personality or the nature  of the worker for all responds and activities.")
    # new_skill=fields.Selection(evaluation_Methods, "Readiness to know new skills ",help="Self-initiation and eagerness to know new things and systems.")
    # obedience =fields.Selection(evaluation_Methods, "Obedience  ",help="Commitment to the order of immediate boss.")
    # leadership =fields.Selection(evaluation_Methods, "Leadership and Supervision (Management Only)",default="0",help="Ability to plan, organize and supervise so that jobs are completed.")
    supervisor_comment=fields.Text()
    employee_comment=fields.Text()
    reason=fields.Text('Reason')
    status=fields.Boolean(default=False)
    @api.onchange('out_of_val')
    def _onchange_out_of_val(self):
        terms_obj = self.job_id
        if terms_obj:
            for search_result in terms_obj:
                clause_final2 = [('job_position', '=',search_result.id)]
                out_of_val= self.env['hr.appraisal.parameter'].search(clause_final2).out_of_val
                
                self.out_of_val=out_of_val
            
    @api.multi
    def approve_appraisal(self):
        return {
                    'name':'Approve',
                    'view_type':'form',
                    'view_mode':'form',
                    'res_model':'approve.appraisal',
                    'type':'ir.actions.act_window',
                    'target':'new',
                }
            
    #    self.status=True
    
    @api.onchange('job_id')
    def _onchange_job_id(self):
        
        _logger.info("++++++++++++++++++++++++++")
        terms_obj = self.job_id
        terms = []
        request_id=''
        if terms_obj:
            for search_result in terms_obj:
                _logger.info('!!!------------------ search_result = %s',search_result)
                _logger.info('!!!------------------ search_result = %s',search_result.id)
                request_id=search_result.id
                clause_final2 = [('job_position', '=',search_result.id)]
                _logger.info('!!!------------------ clause_final = %s',clause_final2)
                search_results2= self.env['hr.appraisal.parameter'].search(clause_final2).ids
                out_of= self.env['hr.appraisal.parameter'].search(clause_final2).out_of
                self.out_of=out_of
                _logger.info('!!!------------------ out_of_val = %s',out_of)
                for search_result3 in self.env['hr.appraisal.parameter'].browse(search_results2):
                    
                    _logger.info('!!!------------------ search_result3 = %s',search_result3)
                    _logger.info('-------search_result3************ = %s',search_result3.id)
                   
                    clause_final5 = [('parameter_id', '=',search_result3.id)]
                    _logger.info('!!!------------------ clause_finals = %s',clause_final5)
                    search_results5= self.env['appraisal.subject.line'].search(clause_final5).ids
                    if search_results5:
                        _logger.info('-------search_results************ = %s',search_results5)
                        # _logger.info('-------term--------- = %s',terms)
                        # terms=self.env['purchase.order.line'].browse(search_results)
                        for search_result4 in self.env['appraisal.subject.line'].browse(search_results5):
                            _logger.info('-------search_result4************ = %s',search_result4)
                        # _logger.info('-------terms************ = %s',terms)
                            # search_result2.write({'state': 'RFQ')
                            for rec in search_result4:
                                values = {}
                                values['name'] = rec.name
                                values['out_of_val'] =  rec.out_of
                                
                                terms.append((0, 0, values))
                
            _logger.info('-------terms************ = %s',terms)
            self.subject_line=terms
            return 
    
    @api.onchange('employee_name')
    def _onchange_employee_name(self):
        _logger.error('-- self.employee_name.job_id val==%s',self.employee_name.id)
        _logger.error('-- self.employee_name.job_id val==%s',self.employee_name.job_id)
        _logger.error('--self.employee_name.job_id.id val==%s',self.employee_name.job_id.id)
        self.job_id = self.employee_name.job_id
    @api.multi
    def callculate_total(self,res):
        total=0.0
        clause_final = [('parameter_id', '=',res.id)]
        _logger.info('!!!------------------ clause_final = %s',clause_final)
        search_results= self.env['appraisal.subject.line1'].search(clause_final).ids
        if search_results:
            _logger.info('-------search_results************ = %s',search_results)
            # _logger.info('-------term--------- = %s',terms)
            # terms=self.env['purchase.order.line'].browse(search_results)
            for search_result2 in self.env['appraisal.subject.line1'].browse(search_results):
                total = total + search_result2.evaluation
        return total
    @api.multi
    def callculate_average(self,total,res):
        total=self.callculate_total(res)
        
        clause_final = [('parameter_id', '=',res.id)]
        _logger.info('!!!------------------ clause_final = %s',clause_final)
        search_results= self.env['appraisal.subject.line1'].search(clause_final).ids
        if search_results:
            _logger.info('-------search_results************ = %s',search_results)
            search_result2 = self.env['appraisal.subject.line1'].browse(search_results)
            _logger.info('-------search_result2************ = %s',search_result2)
            _logger.info('-------len(search_result2)************ = %s',len(search_result2))
            aver=int(total)/len(search_result2)
            return aver
    @api.model
    def create(self, values):
        
        res= super(hr_appraisal, self).create(values)
        _logger.info('-------res************ = %s',res)
        total=self.callculate_total(res)
        
        _logger.info('-------total************ = %s',total)
        _logger.info('-------Average************ = %s',self.callculate_average(total,res))
        res.write({"total":total})
        res.write({"average":self.callculate_average(total,res)})
        
        return res
    
    # @api.multi
    # def callculate_total(self,vals):
    #     total=0.0
    #     _logger.error('start wite leadership val==%s',vals.get('leadership') )
    #     _logger.error('start wite leadership self val==%s',self.leadership )
    #     _logger.error('start wite productivity self val==%s',self.productivity )
    #     _logger.error('start wite productivity val==%s',vals.get('productivity') )
    #     _logger.error('start wite new_skill self val==%s',self.new_skill )
    #     _logger.error('start wite new_skill  val==%s',vals.get('new_skill') )
    #     productivity=0.0
    #     work_quality=0.0
    #     job_knowledge=0.0
    #     independence=0.0
    #     team_work=0.0
    #     record_report=0.0
    #     leadership=0.0
    #     character=0.0
    #     attendance=0.0
    #     new_skill=0.0
    #     guest_service=0.0
    #     safety=0.0
    #     obedience=0.0
    #     if vals.get('productivity'):
    #         productivity=vals.get('productivity')
    #     else:
    #         productivity=self.productivity
    #     if vals.get('work_quality'):
    #         work_quality=vals.get('work_quality')
    #     else:
    #         work_quality=self.work_quality
    #     if vals.get('job_knowledge'):
    #         job_knowledge=vals.get('job_knowledge')
    #     else:
    #         job_knowledge=self.job_knowledge
    #     if vals.get('team_work'):
    #         team_work=vals.get('team_work')
    #     else:
    #         team_work=self.team_work
    #     if vals.get('independence'):
    #         independence=vals.get('independence')
    #     else:
    #         independence=self.independence
    #     if vals.get('record_report'):
    #         record_report=vals.get('record_report')
    #     else:
    #         record_report=self.record_report
    #     if vals.get('guest_service'):
    #         guest_service=vals.get('guest_service')
    #     else:
    #         guest_service=self.guest_service
    #     if vals.get('safety'):
    #         safety=vals.get('safety')
    #     else:
    #         safety=self.safety

    #     if vals.get('attendance'):
    #         attendance=vals.get('attendance')
    #     else:
    #         attendance=self.attendance
    #     if vals.get('character'):
    #         character=vals.get('character')
    #     else:
    #         character=self.character

    #     if vals.get('new_skill'):
    #         new_skill=vals.get('new_skill')
    #     else:
    #         new_skill=self.new_skill

    #     if vals.get('obedience'):
    #         obedience=vals.get('obedience')
    #     else:
    #         obedience=self.obedience
        
    #     if vals.get('leadership'):
    #         leadership=vals.get('leadership')
    #     else:
    #         leadership=self.leadership
    #     if (leadership != 0) or (leadership== False) :
    #         total= ( int(productivity) + int(work_quality) + int(job_knowledge) +int( team_work ) +
    #         int(independence) + int(record_report) + int(guest_service) + int(safety) +
    #         int(attendance) + int(character) + int(new_skill) + int(obedience) +
    #         int(leadership))

    #     # elif self.leadership == 0:
    #     else:
    #         total= ( int(productivity) + int(work_quality) + int(job_knowledge) + int(team_work)+
    #         int(independence)+ int(record_report) + int(guest_service) + int(safety) +
    #         int(attendance) +int( character )+ int(new_skill) + int(obedience))
    #     _logger.error('start wite total val==%s',total)
    #     return total
    # @api.multi
    # def callculate_average(self,total,leadership):
    #     # total=self.callculate_total()
    #     aver=0.0
    #     if leadership != 0:
    #         aver=int(total)/13
    #     elif leadership == 0:
    #         aver=int(total)/12
    #     return aver
    
    # @api.model
    # def create(self, values):
    #     leadership=0.0
    #     if values.get('leadership'):
    #         leadership=values.get('leadership')
    #     else:
    #         leadership=self.leadership
    #     values['total']=self.callculate_total(values)
    #     values['average']=self.callculate_average(values['total'],leadership)
    #     _logger.error('start wite employee name val==%s',self.employee_name )
    #     _logger.error('start wite job_id val==%s',self.job_id )
    #     # _logger.error('start wite job_id values==%s',values['job_id'] )
    #     if values.get('job_id'):
    #         _logger.error('start wite job_id == values==%s',values.get('job_id'))
    #     # values['job_id']=self.job_id
    #     return super(hr_appraisal, self).create(values)
    #     # return super(hr_appraisal, self.with_context(mail_create_nosubscribe=True)).create(values)
    # @api.multi
    # def write(self, vals):
    #     # user_id change: update date_open
    #     _logger.error('start wite function')
    #     leadership=0.0
    #     if vals.get('leadership'):
    #         leadership=vals.get('leadership')
    #     else:
    #         leadership=self.leadership
    #     vals['total']=self.callculate_total(vals)
    #     vals['average']=self.callculate_average(vals['total'],leadership)
    #     # if vals.get('employee_comment'):
    #     #     vals['status']=True
    #     res = super(hr_appraisal, self).write(vals)
        
    #     return res

class approve_appraisal(models.Model):
    _name = 'approve.appraisal'

    @api.multi
    def yes(self, context):

        _logger.error("******----------------------------")
        _logger.error("*******active_id = %s",context.get('active_id'))
        clause_final = [('id', '=', context.get('active_id'))]
        search_results= self.env['hr.appraisal'].search(clause_final).ids
        if search_results:
            for search_result in self.env['hr.appraisal'].browse(search_results):
                search_result.write({'status': True})
class AppraisalParameter(models.Model):
    _name = 'hr.appraisal.parameter'
    job_position = fields.Many2one('hr.job', "Job Title")
    out_of = fields.Float( "Out Of")
    subject_line = fields.One2many('appraisal.subject.line', 'parameter_id', string='Subject Lines', copy=True)
    
class SubjectLine(models.Model):
    _name = 'appraisal.subject.line'
    name = fields.Char(string='Subject Name', required=True)
    parameter_id = fields.Many2one('hr.appraisal.parameter', string='Parameter Reference', 
    index=True, ondelete='cascade')
    out_of = fields.Float(related='parameter_id.out_of', store=True)
  
 
#     description = fields.Text()
#
#     @api.depends('value')
#     def _value_pc(self):
#         self.value2 = float(self.value) / 100

# @api.multi
# def print_report(self):
#    return self.env['report'].get_action(self,'hr.appraisal.REPORT_NAME')
# def print_report(self, context=None):
#     active_id = context.get('active_id', [])
#     datas = {'ids' : [active_id]}
#     return {
#         'type': 'ir.actions.report.xml',
#         'report_name': 'pos.receipt',
#         'datas': datas,
#     }