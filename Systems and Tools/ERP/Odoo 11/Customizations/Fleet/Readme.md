# Odoo 11 Fleet Customizations

This section documents customizations to the Odoo 11 fleet module, focusing on automated driver assignment in vehicle service logs.

---

## Auto-Fetch Driver in Vehicle Service Log Based on Assigned Vehicle

- **Issue**: Users must manually select the driver (employee) when creating a service log, even though the vehicle is already assigned to an employee, leading to redundant input and potential mismatches.
- **Solution**: Automatically populate the **Driver** (employee) field in the service log when a vehicle is selected, using the employee linked to the vehicle.
  - In `fleet_customization/models/fleet_vehicle_log_services.py`, extend the `_onchange_vehicle` method:
    ```python
    @api.onchange('vehicle_id')
    def _onchange_vehicle(self):
        if self.vehicle_id:
            self.odometer_unit = self.vehicle_id.odometer_unit
            self.purchaser_id = self.vehicle_id.driver_id.id
            self.employee = self.vehicle_id.employee.id
    ```
  - This ensures that selecting a vehicle automatically sets:
    - **Odometer Unit**
    - **Purchaser** (driver contact)
    - **Employee** (assigned driver)
  - No manual input required for the employee field if the vehicle has a valid assignment.
  - Restart Odoo and upgrade the `fleet_customization` module.
  - After implementation, service logs maintain accurate and consistent driver information with reduced user effort.

---

# Fleet Customization — Vehicle Service Log Enhancement

## What

This module extends the **Vehicle Service Log** (`fleet.vehicle.log.services`) to include **Quantity** and **Total Indicative Cost** fields in the Included Services table.

- **Quantity** tracks the amount of each service.
- **Total Indicative Cost** automatically calculates `Quantity × Indicative Cost`.

## Why

- Reduce manual calculations and redundant data entry.
- Ensure accurate cost reporting for vehicle services.
- Improve user experience and consistency in fleet service logs.

## How

### Model Extension

The `fleet.vehicle.cost` model is extended with `quantity` and `total` fields. The `total` is computed automatically whenever `quantity` or `amount` changes.

```python
# fleet_customization/models/fleet_vehicle_cost.py
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
```

### View Extension

The `cost_ids` tree view in the Vehicle Service Log form is updated to display **Quantity** and **Total Indicative Cost**:

```xml
<!-- fleet_customization/views/fleet_vehicle_cost_views.xml -->
<odoo>
    <data>
        <record id="view_fleet_vehicle_log_services_form_inherit" model="ir.ui.view">
            <field name="name">fleet.vehicle.log.services.form.inherit</field>
            <field name="model">fleet.vehicle.log.services</field>
            <field name="inherit_id" ref="fleet.fleet_vehicle_log_services_view_form"/>
            <field name="arch" type="xml">
                <!-- Insert Quantity after cost_subtype_id -->
                <xpath expr="//field[@name='cost_ids']/tree/field[@name='cost_subtype_id']" position="after">
                    <field name="quantity"/>
                </xpath>
                <!-- Insert Total after amount -->
                <xpath expr="//field[@name='cost_ids']/tree/field[@name='amount']" position="after">
                    <field name="total" sum="Total" string="Total Indicative Cost"/>
                </xpath>
            </field>
        </record>
    </data>
</odoo>
```
