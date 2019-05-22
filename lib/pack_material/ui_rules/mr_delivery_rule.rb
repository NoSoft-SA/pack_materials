# frozen_string_literal: true

module UiRules
  class MrDeliveryRule < Base
    def generate_rules
      @repo = PackMaterialApp::ReplenishRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      @locations_repo = MasterfilesApp::LocationRepo.new
      make_form_object
      apply_form_values

      rules[:can_verify] = can_verify unless @mode == :new
      rules[:can_add_invoice] = can_add_invoice unless @mode == :new
      rules[:can_complete_invoice] = can_complete_invoice unless @mode == :new
      rules[:is_verified] = @form_object.verified if @mode == :edit
      rules[:invoice_completed] = @form_object.invoice_completed unless @mode == :new
      rules[:del_sub_totals] = @repo.del_sub_totals(@options[:id]) if @mode == :edit
      common_values_for_fields case @mode
                               when :edit
                                 rules[:is_verified] ? show_fields : common_fields
                               when :edit_invoice
                                 rules[:invoice_completed] ? show_invoice_fields : invoice_fields
                               else
                                 common_fields
                               end

      form_name 'mr_delivery'
    end

    def show_fields
      receiving_bay_label = @locations_repo.find_location(@form_object.receipt_location_id)&.location_long_code
      {
        status: { renderer: :label },
        transporter: { renderer: :label },
        transporter_party_role_id: { renderer: :hidden },
        receipt_location_id: { renderer: :label, with_value: receiving_bay_label, caption: 'Receiving Bay' },
        driver_name: { renderer: :label },
        client_delivery_ref_number: { renderer: :label },
        delivery_number: { renderer: :label },
        vehicle_registration: { renderer: :label },
        supplier_invoice_ref_number: { renderer: :label },
        supplier_invoice_date: { renderer: :label }
      }
    end

    def common_fields
      {
        status: { renderer: :hidden },
        transporter: { renderer: :hidden },
        transporter_party_role_id: { renderer: :select, options: @party_repo.for_select_party_roles(AppConst::ROLE_TRANSPORTER), caption: 'Transporter' },
        receipt_location_id: { renderer: :select, options: @locations_repo.for_select_receiving_bays, caption: 'Receiving Bay', required: true },
        delivery_number: { renderer: :label, with_value: @form_object.delivery_number },
        driver_name: { required: true },
        client_delivery_ref_number: { required: true },
        vehicle_registration: { required: true }
      }
    end

    def invoice_fields
      {
        supplier_invoice_ref_number: { required: true, with_value: @form_object.supplier_invoice_ref_number },
        supplier_invoice_date:       { subtype: :date, required: true },
      }
    end

    def show_invoice_fields
      {
        supplier_invoice_ref_number: { renderer: :label },
        supplier_invoice_date:       { renderer: :label },
        erp_purchase_order_number:   { renderer: :label },
        erp_purchase_invoice_number: { renderer: :label }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new
      make_new_invoice_form_object && return if @mode == :edit_invoice

      @form_object = @repo.find_mr_delivery(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(transporter_party_role_id: nil,
                                    receipt_location_id: nil,
                                    driver_name: nil,
                                    client_delivery_ref_number: nil,
                                    vehicle_registration: nil,
                                    supplier_invoice_ref_number: nil)
    end

    def make_new_invoice_form_object
      delivery = @repo.find_mr_delivery(@options[:id])
      if delivery.supplier_invoice_ref_number.nil?
        @form_object = OpenStruct.new(supplier_invoice_ref_number: nil,
                                      supplier_invoice_date: UtilityFunctions.weeks_since(Time.now, 1))
      else
        @form_object = delivery
      end
    end

    def can_verify
      res = PackMaterialApp::TaskPermissionCheck::MrDelivery.call(:verify, @options[:id])
      res.success
    end

    def can_add_invoice
      res = PackMaterialApp::TaskPermissionCheck::MrDelivery.call(:add_invoice, @options[:id])
      res.success
    end

    def can_complete_invoice
      res = PackMaterialApp::TaskPermissionCheck::MrDelivery.call(:complete_invoice, @options[:id])
      res.success
    end
  end
end