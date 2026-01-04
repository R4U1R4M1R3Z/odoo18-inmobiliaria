# -*- coding: utf-8 -*-
from odoo import models, fields, api


class RealEstatePropertyType(models.Model):
    _name = 'real.estate.property.type'
    _description = 'Tipo de Propiedad'
    _order = 'sequence, name'

    name = fields.Char(string='Nombre', required=True, translate=True)
    sequence = fields.Integer(string='Secuencia', default=10)
    active = fields.Boolean(string='Activo', default=True)
    description = fields.Text(string='Descripción')
    
    property_count = fields.Integer(
        string='Nº Propiedades',
        compute='_compute_property_count'
    )

    @api.depends('name')
    def _compute_property_count(self):
        for record in self:
            record.property_count = self.env['real.estate.property'].search_count([
                ('property_type_id', '=', record.id)
            ])
    
    def action_view_properties(self):
        """Abrir propiedades de este tipo"""
        self.ensure_one()
        return {
            'type': 'ir.actions.act_window',
            'name': f'Propiedades - {self.name}',
            'res_model': 'real.estate.property',
            'view_mode': 'kanban,list,form',
            'domain': [('property_type_id', '=', self.id)],
            'context': {'default_property_type_id': self.id}
        }