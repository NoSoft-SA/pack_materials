# frozen_string_literal: true

module UiRules
  class MrDeliveryItemRule < Base
    def generate_rules
      @repo = PackMaterialApp::ReplenishRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields @mode == :preselect ? preselect_fields : common_fields

      set_show_fields if @mode == :show
      add_behaviours if @mode == :preselect

      form_name 'mr_delivery_item'
    end

    def set_show_fields
      fields[:mr_product_variant_code] = { renderer: :label, with_value: product_variant_code, caption: 'Product Code' }
      fields[:quantity_on_note] = { renderer: :label }
      fields[:quantity_over_supplied] = { renderer: :label }
      fields[:quantity_under_supplied] = { renderer: :label }
      fields[:quantity_received] = { renderer: :label }
      fields[:invoiced_unit_price] = { renderer: :label }
      fields[:remarks] = { renderer: :label }
    end

    def common_fields
      {
        mr_delivery_id: { renderer: :hidden },
        mr_purchase_order_item_id: { renderer: :hidden },
        mr_product_variant_id: { renderer: :hidden },
        product_variant_code: { renderer: :label, with_value: product_variant_code },
        quantity_on_note: { renderer: :numeric, required: true },
        quantity_over_supplied: { renderer: :numeric },
        quantity_under_supplied: { renderer: :numeric },
        quantity_received: { renderer: :numeric, required: true },
        invoiced_unit_price: { renderer: :numeric, required: true },
        remarks: {}
      }
    end

    def preselect_fields
      {
        purchase_order_id: {
          renderer: :select,
          options: @repo.for_select_purchase_orders_with_supplier,
          selected: @options[:purchase_order_id],
          caption: 'Purchase Order',
          required: true,
          prompt: true
        },
        mr_delivery_id: { renderer: :hidden },
        mr_purchase_order_item_id: {
          renderer: :select,
          options: @options[:purchase_order_id] ? available_purchase_order_items : nil,
          caption: 'Item',
          required: true
        }
      }
    end

    def make_form_object
      make_preselect_form_object && return if @mode == :preselect
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_mr_delivery_item(@options[:id])
    end

    def make_preselect_form_object
      @form_object = OpenStruct.new(purchase_order_id: nil)
    end

    def make_new_form_object
      @form_object = OpenStruct.new(mr_delivery_id: @options[:parent_id],
                                    mr_purchase_order_item_id: @options[:item_id],
                                    mr_product_variant_id: @repo.find_mr_purchase_order_item(@options[:item_id])&.mr_product_variant_id,
                                    quantity_on_note: nil,
                                    quantity_over_supplied: nil,
                                    quantity_under_supplied: nil,
                                    quantity_received: nil,
                                    invoiced_unit_price: nil,
                                    remarks: nil)
    end

    def product_variant_code
      PackMaterialApp::ConfigRepo.new.find_matres_product_variant(@form_object.mr_product_variant_id)&.product_variant_code
    end

    def available_purchase_order_items
      @repo.for_select_remaining_purchase_order_items(@options[:purchase_order_id], @options[:parent_id])
    end

    def selected_purchase_order
      @options[:purchase_order_id]
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :purchase_order_id, notify: [{ url: "/pack_material/replenish/mr_deliveries/#{@options[:parent_id]}/mr_delivery_items/purchase_order_changed" }]
      end
    end
  end
end
