# -*- coding: utf-8 -*-
from odoo import models, fields, api

class RealEstateProperty(models.Model):
    _name = 'real.estate.property'
    _description = 'Propiedad Inmobiliaria'
    _order = 'id desc'
    _inherit = ['mail.thread', 'mail.activity.mixin']  # ← Añadir esta línea

    # --- Información básica ---
    name = fields.Char(string='Título', required=True)
    reference = fields.Char(string='Referencia', readonly=True, copy=False, default='New')
    description = fields.Html(string='Descripción', help='Descripción detallada de la propiedad')
    
    # --- Ubicación ---
    city = fields.Char(string='Ciudad', required=True)
    street = fields.Char(string='Calle')
    zip = fields.Char(string='Código Postal')
    
    # --- Tipo ---
    property_type_id = fields.Many2one('real.estate.property.type', string='Tipo', required=True)
    
    # --- Características físicas ---
    surface = fields.Float(string='Superficie (m²)', required=True, help='Superficie total construida')
    surface_plot = fields.Float(string='Superficie Parcela (m²)', help='Superficie del terreno/parcela')
    rooms = fields.Integer(string='Habitaciones', default=1)
    bathrooms = fields.Integer(string='Baños', default=1)
    floor = fields.Integer(string='Planta')
    total_floors = fields.Integer(string='Plantas Totales')
    
    # --- Extras ---
    elevator = fields.Boolean(string='Ascensor')
    garage = fields.Boolean(string='Garaje')
    garage_spaces = fields.Integer(string='Plazas Garaje')
    terrace = fields.Boolean(string='Terraza')
    terrace_surface = fields.Float(string='Superficie Terraza (m²)')
    piscina = fields.Boolean(string='Piscina')
    garden = fields.Boolean(string='Jardín')
    storage = fields.Boolean(string='Trastero')
    furnished = fields.Boolean(string='Amueblado')
    heating = fields.Selection([
        ('none', 'Sin Calefacción'),
        ('individual', 'Individual'),
        ('central', 'Central'),
        ('aerothermal', 'Aerotermia'),
    ], string='Calefacción', default='none')
    ac = fields.Boolean(string='Aire Acondicionado')
    energy_certificate = fields.Selection([
        ('a', 'A'), ('b', 'B'), ('c', 'C'), ('d', 'D'),
        ('e', 'E'), ('f', 'F'), ('g', 'G'), ('pending', 'En Trámite'),
    ], string='Certificado Energético')

    # --- Año y estado ---
    year_built = fields.Integer(string='Año Construcción')
    last_renovation = fields.Integer(string='Última Reforma')
    condition = fields.Selection([
        ('new', 'Obra Nueva'),
        ('excellent', 'Excelente'),
        ('good', 'Buen Estado'),
        ('to_reform', 'A Reformar'),
    ], string='Estado Conservación', default='good')

    # --- Operación comercial ---
    operation_type = fields.Selection([
        ('sale', 'Venta'),
        ('rent', 'Alquiler'),
        ('both', 'Venta y Alquiler'),
    ], string='Operación', required=True, default='sale')
    
    # --- Precios ---
    currency_id = fields.Many2one('res.currency', string='Moneda', 
                                   default=lambda self: self.env.company.currency_id)
    sale_price = fields.Monetary(string='Precio Venta', currency_field='currency_id')
    rent_price = fields.Monetary(string='Precio Alquiler/mes', currency_field='currency_id')
    price_per_sqm = fields.Monetary(string='€/m²', compute='_compute_price_per_sqm', 
                                     store=True, currency_field='currency_id')
    community_fees = fields.Monetary(string='Gastos Comunidad/mes', currency_field='currency_id')
    ibi = fields.Monetary(string='IBI/año', currency_field='currency_id')
    
    # --- Estado ---
    state = fields.Selection([
        ('draft', 'Borrador'),
        ('available', 'Disponible'),
        ('reserved', 'Reservado'),
        ('sold', 'Vendido'),
        ('rented', 'Alquilado'),
    ], string='Estado', default='draft')
    
    # --- Agente ---
    agent_id = fields.Many2one('res.users', string='Agente', default=lambda self: self.env.user)

    # --- Contactos ---
    owner_id = fields.Many2one('res.partner', string='Propietario', tracking=True,
                            help='Propietario actual de la propiedad')
    tenant_id = fields.Many2one('res.partner', string='Inquilino Actual', tracking=True,
                                help='Inquilino que ocupa la propiedad actualmente')

    # --- Imágenes ---
    image_count = fields.Integer(string='Nº Imágenes', compute='_compute_image_count')
    image_count = fields.Integer(string='Nº Imágenes', compute='_compute_image_count')
    image_1920 = fields.Image(string='Imagen Principal', max_width=1920, max_height=1920)
    
    # --- Métodos computados ---
    @api.depends('sale_price', 'surface')
    def _compute_price_per_sqm(self):
        for record in self:
            if record.surface > 0 and record.sale_price:
                record.price_per_sqm = record.sale_price / record.surface
            else:
                record.price_per_sqm = 0.0

    def _compute_image_count(self):
        for record in self:
            record.image_count = self.env['ir.attachment'].search_count([
            ('res_model', '=', self._name),
            ('res_id', '=', record.id),
            ('mimetype', 'ilike', 'image')
        ])
    
    # --- Crear referencia automática ---
    @api.model_create_multi
    def create(self, vals_list):
        for vals in vals_list:
            if vals.get('reference', 'New') == 'New':
                vals['reference'] = self.env['ir.sequence'].next_by_code('real.estate.property') or 'PROP-NEW'
        return super().create(vals_list)
    
    # --- Botones ---
    def action_set_available(self):
        self.write({'state': 'available'})
        return True

    def action_set_reserved(self):
        self.write({'state': 'reserved'})
        return True

    def action_set_sold(self):
        self.write({'state': 'sold'})
        return True

    def action_set_rented(self):
        self.write({'state': 'rented'})
        return True

    def action_cancel(self):
        self.write({'state': 'draft'})
        return True

    def action_back_to_available(self):
        """Volver a disponible desde reservado"""
        self.write({'state': 'available'})
        return True

    # --- Acción para abrir galería ---
    def action_view_images(self):
        """Abrir galería de imágenes"""
        self.ensure_one()
        return {
            'type': 'ir.actions.act_window',
            'name': f'Imágenes - {self.name}',
            'res_model': 'ir.attachment',
            'view_mode': 'kanban,list,form',
            'domain': [
                ('res_model', '=', self._name),
                ('res_id', '=', self.id),
                ('mimetype', 'ilike', 'image')
            ],
            'context': {
                'default_res_model': self._name,
                'default_res_id': self.id,
            }
        }