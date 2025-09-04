# -*- coding: utf-8 -*-
{
    'name': "payment_request",

    'summary': """
        Manage and process internal or external payment requests within your company.""",

    'description': """
        Long description of module's purpose
    """,

    'author': "My Company",
    'website': "http://www.yourcompany.com",

    # Categories can be used to filter modules in modules listing
    # Check https://github.com/odoo/odoo/blob/master/odoo/addons/base/module/module_data.xml
    # for the full list
    'category': 'Uncategorized',
    'version': '0.1',

    # any module necessary for this one to work correctly
    'depends': ['base'],

    # always loaded
    'data': [
        'security/security_groups.xml',    # Load groups first
        'security/ir.model.access.csv',    # Then load access rights referencing the groups
        'views/views.xml',
        'views/templates.xml',
        'reports/payment_request.xml',
        'reports/report.xml',
        'views/payment_request_export_wizard_views.xml',
        'views/payment_request_menu.xml',
    ],
    'images': ['static/description/icon.png'],
    # only loaded in demonstration mode
    'demo': [
        'demo/demo.xml',
    ],
}