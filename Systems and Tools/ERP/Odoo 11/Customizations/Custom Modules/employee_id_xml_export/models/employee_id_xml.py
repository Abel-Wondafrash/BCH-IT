import os
import base64
from datetime import datetime
from xml.dom import minidom
from odoo import models, api
from odoo.exceptions import UserError

class EmployeeIdXmlExport(models.Model):
    _name = "employee.id.xml.export"
    _description = "Employee ID XML Export Helper"

    @api.model
    def export_employee_ids(self, employee_ids):
        employees = self.env['hr.employee'].browse(employee_ids)
        if not employees:
            raise UserError("No employees selected.")

        # Base export directory
        BASE_DIR = r"C:\Users\TOP ID\XMLs\EmployeeIDs"
        os.makedirs(BASE_DIR, exist_ok=True)

        # Timestamped folder for this export
        now_str = datetime.today().strftime('%Y%m%d_%H%M%S')
        export_dir = os.path.join(BASE_DIR, f"employee_ids_{now_str}")
        os.makedirs(export_dir, exist_ok=True)

        # Photos folder
        photos_dir = os.path.join(export_dir, 'photos')
        os.makedirs(photos_dir, exist_ok=True)

        # XML document
        doc = minidom.Document()
        root = doc.createElement('Employees')
        doc.appendChild(root)

        for emp in employees:
            emp_el = doc.createElement('Employee')
            root.appendChild(emp_el)

            def add_node(tag, value):
                el = doc.createElement(tag)
                el.appendChild(doc.createTextNode(value or ''))
                emp_el.appendChild(el)

            # Basic fields
            add_node('FullName', emp.name)
            add_node('Department', emp.department_id.name if emp.department_id else '')
            add_node('Position', emp.job_id.name if emp.job_id else '')
            add_node('IDNumber', emp.identification_id or '')
            add_node('Phone', emp.mobile_phone or '')
            add_node('EmploymentDate', str(emp.employment_date or ''))
            add_node('IDExpiryDate', str(emp.id_expiry_date or ''))
            add_node('ContractType', emp.contract_id.type_id.name if emp.contract_id else '')

            # Emergency contact (first only)
            emergency = self.env['hr.emergency.contact'].search(
                [('employee_obj', '=', emp.id)], limit=1
            )
            add_node('EmergencyContactNumber', emergency.number if emergency else '')
            add_node('EmergencyContactRelation', emergency.relation if emergency else '')

            # Photo export
            if emp.image:
                try:
                    image_path = os.path.join(photos_dir, f"{emp.id}.png")
                    image_data = base64.b64decode(emp.image)
                    with open(image_path, 'wb') as f:
                        f.write(image_data)
                    add_node('PhotoPath', f"photos/{emp.id}.png")
                except Exception:
                    add_node('PhotoPath', '')
            else:
                add_node('PhotoPath', '')

        # Meta information
        activity_el = doc.createElement('Activity')
        root.appendChild(activity_el)

        import socket
        device_el = doc.createElement('deviceName')
        device_el.appendChild(doc.createTextNode(socket.gethostname()))
        activity_el.appendChild(device_el)

        user_el = doc.createElement('user')
        activity_el.appendChild(user_el)

        full_name_el = doc.createElement('fullName')
        full_name_el.appendChild(doc.createTextNode(self.env.user.name))
        user_el.appendChild(full_name_el)

        user_name_el = doc.createElement('userName')
        user_name_el.appendChild(doc.createTextNode(self.env.user.login))
        user_el.appendChild(user_name_el)

        # Write XML file
        xml_file_path = os.path.join(export_dir, 'employees.xml')
        with open(xml_file_path, 'w+', encoding='utf-8') as f:
            f.write(doc.toprettyxml(indent='\t'))

        return True
