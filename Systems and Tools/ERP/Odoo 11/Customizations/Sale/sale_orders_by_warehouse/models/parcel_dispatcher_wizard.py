from odoo import models, fields, api
from odoo.exceptions import UserError

class ParcelDispatcherWizard(models.TransientModel):
    _name = "parcel.dispatcher.wizard"
    _description = "Parcel Dispatcher Wizard"

    dispatcher_id = fields.Many2one(
        "hr.employee",
        string="Dispatcher",
        domain=[('is_parcel_dispatcher', '=', True)],  # <-- filter
        required=True,
    )

    @api.multi
    def confirm_dispatcher(self):
        self.ensure_one()
        ctx = dict(self._context or {})
        active_ids = ctx.get('active_ids')
        if not active_ids:
            raise UserError("No sales orders selected.")

        orders = self.env['sale.order'].browse(active_ids)
        unprocessed_orders = orders.filtered(lambda o: not o.loj_parcel_batch_id)

        if not unprocessed_orders:
            raise UserError("All selected orders have already been processed in a batch.")

        warehouses = unprocessed_orders.mapped('warehouse_id')
        if len(warehouses) > 1:
            raise UserError("You can only process orders from the same warehouse into one batch.")

        batch = self.env['loj.parcel.batch'].create({
            'warehouse_id': warehouses[0].id,
            'dispatcher_id': self.dispatcher_id.id,
        })
        unprocessed_orders.write({'loj_parcel_batch_id': batch.id})
        batch.create_xml_for_batch()
        return {'type': 'ir.actions.act_window_close'}
