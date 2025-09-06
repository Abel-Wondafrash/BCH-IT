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
