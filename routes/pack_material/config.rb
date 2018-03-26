# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/BlockLength

class Framework < Roda
  route 'config', 'pack_material' do |r|
    # MATERIAL RESOURCE TYPES
    # --------------------------------------------------------------------------
    r.on 'material_resource_types', Integer do |id|
      interactor = PackMaterial::ConfigInteractor.new(current_user, {}, { route_url: request.path }, {})

      # Check for notfound:
      r.on !interactor.exists?(:material_resource_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do
        raise Crossbeams::AuthorizationError unless authorised?('config', 'edit')
        show_partial { PackMaterial::Config::MatresType::Edit.call(id) }
      end
      r.is do
        r.get do
          raise Crossbeams::AuthorizationError unless authorised?('config', 'read')
          show_partial { PackMaterial::Config::MatresType::Show.call(id) }
        end
        r.patch do
          return_json_response
          res = interactor.update_matres_type(id, params[:matres_type])
          if res.success
            update_grid_row(id, changes: { material_resource_domain_id: res.instance[:material_resource_domain_id],
                                           type_name: res.instance[:type_name] },
                                notice: res.message)
          else
            content = show_partial { PackMaterial::Config::MatresType::Edit.call(id, params[:matres_type], res.errors) }
            update_dialog_content(content: content, error: res.message)
          end
        end
        r.delete do
          return_json_response
          raise Crossbeams::AuthorizationError unless authorised?('config', 'delete')
          res = interactor.delete_matres_type(id)
          delete_grid_row(id, notice: res.message)
        end
      end
    end

    r.on 'material_resource_types' do
      interactor = PackMaterial::ConfigInteractor.new(current_user, {}, { route_url: request.path }, {})
      r.on 'new' do
        raise Crossbeams::AuthorizationError unless authorised?('config', 'new')
        show_partial_or_page(fetch?(r)) { PackMaterial::Config::MatresType::New.call(remote: fetch?(r)) }
      end
      r.post do
        res = interactor.create_matres_type(params[:matres_type])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        elsif fetch?(r)
          content = show_partial do
            PackMaterial::Config::MatresType::New.call(form_values: params[:matres_type],
                                                          form_errors: res.errors,
                                                          remote: true)
          end
          update_dialog_content(content: content, error: res.message)
        else
          flash[:error] = res.message
          stash_page(PackMaterial::Config::MatresType::New.call(form_values: params[:matres_type],
                                                                form_errors: res.errors,
                                                                remote: false))
          r.redirect '/pack_material/config/material_resource_types/new'
        end
      end
    end

    # MATERIAL RESOURCE SUB TYPES
    # --------------------------------------------------------------------------
    r.on 'material_resource_sub_types', Integer do |id|
      interactor = PackMaterial::ConfigInteractor.new(current_user, {}, { route_url: request.path }, {})

      # Check for notfound:
      r.on !interactor.exists?(:material_resource_sub_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do
        raise Crossbeams::AuthorizationError unless authorised?('config', 'edit')
        show_partial { PackMaterial::Config::MatresSubType::Edit.call(id) }
      end
      r.on 'config' do
        r.is 'edit' do
          raise Crossbeams::AuthorizationError unless authorised?('config', 'edit')
          page = stashed_page
          if page
            show_page { page }
          else
            show_page { PackMaterial::Config::MatresSubType::Config.call(id) }
          end
        end
        r.patch do
          return_json_response
          res = interactor.update_matres_config(id, params[:matres_sub_type])
          if res.success
            show_json_notice(res.message)
          else
            show_json_error(res.message)
          end
        end
      end

      r.on 'update_product_code_configuration' do
        r.post do
          res = interactor.update_product_code_configuration(id, params[:product_code_columns])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            flash[:error] = res.message
            stash_page(PackMaterial::Config::MatresSubType::Config.call(id, form_values: params[:product_code_columns],
                                                                               form_errors: res.errors))
            r.redirect "/pack_material/config/material_resource_sub_types/#{id}/config/edit"
          end
        end
      end

      r.is do
        r.get do
          raise Crossbeams::AuthorizationError unless authorised?('config', 'read')
          show_partial { PackMaterial::Config::MatresSubType::Show.call(id) }
        end
        r.patch do
          return_json_response
          res = interactor.update_matres_sub_type(id, params[:matres_sub_type])
          if res.success
            update_grid_row(id, changes: {  material_resource_type_id: res.instance[:material_resource_type_id],
                                            sub_type_name: res.instance[:sub_type_name],
                                            product_code_separator: res.instance[:product_code_separator],
                                            has_suppliers: res.instance[:has_suppliers],
                                            has_marketers: res.instance[:has_marketers],
                                            has_retailer: res.instance[:has_retailer],
                                            product_column_ids: res.instance[:product_column_ids],
                                            product_code_ids: res.instance[:product_code_ids] },
                                notice: res.message)
          else
            content = show_partial { PackMaterial::Config::MatresSubType::Edit.call(id, params[:matres_sub_type], res.errors) }
            update_dialog_content(content: content, error: res.message)
          end
        end
        r.delete do
          return_json_response
          raise Crossbeams::AuthorizationError unless authorised?('config', 'delete')
          res = interactor.delete_matres_sub_type(id)
          delete_grid_row(id, notice: res.message)
        end
      end
    end

    r.on 'material_resource_sub_types' do
      interactor = PackMaterial::ConfigInteractor.new(current_user, {}, { route_url: request.path }, {})
      r.on 'new' do
        raise Crossbeams::AuthorizationError unless authorised?('config', 'new')
        show_partial_or_page(fetch?(r)) { PackMaterial::Config::MatresSubType::New.call(remote: fetch?(r)) }
      end
      r.post do
        res = interactor.create_matres_sub_type(params[:matres_sub_type])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        elsif fetch?(r)
          content = show_partial do
            PackMaterial::Config::MatresSubType::New.call(form_values: params[:matres_sub_type],
                                                             form_errors: res.errors,
                                                             remote: true)
          end
          update_dialog_content(content: content, error: res.message)
        else
          flash[:error] = res.message
          show_page do
            PackMaterial::Config::MatresSubType::New.call(form_values: params[:matres_sub_type],
                                                             form_errors: res.errors,
                                                             remote: false)
          end
        end
      end
    end

    r.on 'link_product_columns' do
      r.post do
        interactor = PackMaterial::ConfigInteractor.new(current_user, {}, { route_url: request.path }, {})
        ids = multiselect_grid_choices(params)
        res = interactor.chosen_product_columns(ids)
        json_actions([OpenStruct.new(type: :replace_multi_options, dom_id: 'product_code_columns_non_variant_product_code_column_ids', options_array: res.instance[:code]),
                      OpenStruct.new(type: :replace_multi_options, dom_id: 'product_code_columns_variant_product_code_column_ids', options_array: res.instance[:var]),
                      OpenStruct.new(type: :replace_input_value, dom_id: 'product_code_columns_chosen_column_ids', value: ids.join(','))],
                     'Re-assigned product columns')
      end
    end
    # PACK MATERIAL PRODUCTS
    # --------------------------------------------------------------------------
    r.on 'pack_material_products', Integer do |id|
      interactor = PackMaterialApp::PmProductInteractor.new(current_user, {}, { route_url: request.path }, {})

      # check for notfound
      r.on !interactor.exists?(:pack_material_products, id) do
        handle_not_found(r)
      end

      r.on 'edit' do
        raise Crossbeams::AuthorizationError unless authorized?('Pack material products', 'edit')
        show_partial { PackMaterial::Config::PmProduct::Edit.call(id) }
      end
      r.is do
        r.get do
          raise Crossbeams::AuthorizationError unless authorised?('config', 'read')
          show_partial { PackMaterial::Config::PmProduct::Show.call(id) }
        end
        r.patch do
          return_json_response
          res = interactor.update_pm_product(id, params[:pm_product])
          if res.success
            update_grid_row(id, changes: { material_resource_sub_type_id: res.instance[:material_resource_sub_type_id],
                                           product_number: res.instance[:product_number],
                                           description: res.instance[:description],
                                           commodity_id: res.instance[:commodity_id],
                                           variety_id: res.instance[:variety_id],
                                           style: res.instance[:style],
                                           assembly_type: res.instance[:assembly_type],
                                           market_major: res.instance[:market_major],
                                           ctn_size_basic_pack: res.instance[:ctn_size_basic_pack],
                                           ctn_size_old_pack: res.instance[:ctn_size_old_pack],
                                           pls_pack_code: res.instance[:pls_pack_code],
                                           fruit_mass_nett_kg: res.instance[:fruit_mass_nett_kg],
                                           holes: res.instance[:holes],
                                           perforation: res.instance[:perforation],
                                           image: res.instance[:image],
                                           length_mm: res.instance[:length_mm],
                                           width_mm: res.instance[:width_mm],
                                           height_mm: res.instance[:height_mm],
                                           diameter_mm: res.instance[:diameter_mm],
                                           thick_mm: res.instance[:thick_mm],
                                           thick_mic: res.instance[:thick_mic],
                                           colour: res.instance[:colour],
                                           grade: res.instance[:grade],
                                           mass: res.instance[:mass],
                                           material_type: res.instance[:material_type],
                                           treatment: res.instance[:treatment],
                                           specification_notes: res.instance[:specification_notes],
                                           artwork_commodity: res.instance[:artwork_commodity],
                                           artwork_marketing_variety_group: res.instance[:artwork_marketing_variety_group],
                                           artwork_variety: res.instance[:artwork_variety],
                                           artwork_nett_mass: res.instance[:artwork_nett_mass],
                                           artwork_brand: res.instance[:artwork_brand],
                                           artwork_class: res.instance[:artwork_class],
                                           artwork_plu_number: res.instance[:artwork_plu_number],
                                           artwork_other: res.instance[:artwork_other],
                                           artwork_image: res.instance[:artwork_image],
                                           marketer: res.instance[:marketer],
                                           retailer: res.instance[:retailer],
                                           supplier: res.instance[:supplier],
                                           supplier_stock_code: res.instance[:supplier_stock_code],
                                           product_alternative: res.instance[:product_alternative],
                                           product_joint_use: res.instance[:product_joint_use],
                                           ownership: res.instance[:ownership],
                                           consignment_stock: res.instance[:consignment_stock],
                                           start_date: res.instance[:start_date],
                                           end_date: res.instance[:end_date],
                                           active: res.instance[:active],
                                           remarks: res.instance[:remarks] },
                                notice: res.message)
          else
            content = show_partial { PackMaterial::Config::PmProduct::Edit.call(id, params[:pm_product], res.errors) }
            update_dialog_content(content: content, error: res.message)
          end
        end
        r.delete do
          return_json_response
          raise Crossbeams::AuthorizationError unless authorised?('config', 'delete')
          res = interactor.delete_pm_product(id)
          delete_grid_row(id, notice: res.message)
        end
      end
    end
    r.on 'pack_material_products' do
      interactor = PackMaterialApp::PmProductInteractor.new(current_user, {}, { route_url: request.path }, {})
      r.on 'new' do
        raise Crossbeams::AuthorizationError unless authorised?('config', 'new')
        show_partial_or_page(fetch?(r)) { PackMaterial::Config::PmProduct::New.call(remote: fetch?(r)) }
      end
      r.post do
        res = interactor.create_pm_product(params[:pm_product])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        elsif fetch?(r)
          content = show_partial do
            PackMaterial::Config::PmProduct::New.call(form_values: params[:pm_product],
                                                         form_errors: res.errors,
                                                         remote: true)
          end
          update_dialog_content(content: content, error: res.message)
        else
          flash[:error] = res.message
          show_page do
            PackMaterial::Config::PmProduct::New.call(form_values: params[:pm_product],
                                                         form_errors: res.errors,
                                                         remote: false)
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/BlockLength
