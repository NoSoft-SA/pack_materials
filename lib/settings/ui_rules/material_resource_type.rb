# frozen_string_literal: true

module UiRules
  class MaterialResourceTypeRule < Base
    def generate_rules
      @this_repo = PackMaterialRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      form_name 'material_resource_type'
    end

    def set_show_fields
      # material_resource_domain_id_label = PackMaterialRepo.new.find_material_resource_domain(@form_object.material_resource_domain_id)&.domain_name
      material_resource_domain_id_label = @this_repo.find(:material_resource_domains, MaterialResourceDomain, @form_object.material_resource_domain_id)&.domain_name
      fields[:material_resource_domain_id] = { renderer: :label, with_value: material_resource_domain_id_label, caption: 'Domain' }
      fields[:type_name] = { renderer: :label }
    end

    def common_fields
      {
        material_resource_domain_id: { renderer: :select, options: PackMaterialRepo.new.for_select_matres_domains, caption: 'Domain' },
        type_name: {}
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @this_repo.find_material_resource_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(material_resource_domain_id: nil,
                                    type_name: nil)
    end
  end
end