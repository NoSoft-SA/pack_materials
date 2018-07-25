# frozen_string_literal: true

module PackMaterialApp
  class PmProductInteractor < BaseInteractor
    def create_pm_product(params)
      res = validate_pm_product_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      pm_product_create(res)
    end

    def clone_pm_product(params)
      res = validate_clone_pm_product_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      pm_product_create(res)
    end

    def pm_product_create(res)
      id = nil
      DB.transaction do
        id = repo.create_pm_product(res)
      end
      instance = pm_product(id)
      success_response('Created product', instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { product_number: ['This product already exists'] }))
    end

    def update_pm_product(id, params)
      res = validate_pm_product_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      repo.update_pm_product(id, res)
      instance = pm_product(id)
      success_response("Updated product #{instance.product_code}", instance)
    end

    def delete_pm_product(id)
      name = pm_product(id).product_code
      repo.delete_pm_product(id)
      success_response("Deleted product #{name}")
    end

    def create_pm_product_variant(parent_id, params)
      params[:pack_material_product_id] = parent_id
      res = validate_pm_product_variant_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      pm_product_variant_create(res)
    end

    def clone_pm_product_variant(parent_id, params)
      params[:pack_material_product_id] = parent_id
      res = validate_clone_pm_product_variant_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      pm_product_variant_create(res)
    end

    def pm_product_variant_create(res)
      id = nil
      DB.transaction do
        id = repo.create_pm_product_variant(res)
      end
      instance = pm_product_variant(id)
      success_response('Created product variant', instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { unit: ['This product variant already exists'] }))
    end

    def update_pm_product_variant(id, params)
      res = validate_pm_product_variant_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      DB.transaction do
        repo.update_pm_product_variant(id, res)
      end
      instance = pm_product_variant(id)
      success_response("Updated pack material product variant #{instance.product_variant_number}", instance)
    end

    def delete_pm_product_variant(id)
      name = pm_product_variant(id).unit
      DB.transaction do
        repo.delete_pm_product_variant(id)
      end
      success_response("Deleted pack material product variant #{name}")
    end

    private

    def repo
      @repo ||= PmProductRepo.new
    end

    def pm_product(id)
      repo.find_pm_product(id)
    end

    def pm_product_variant(id)
      repo.find_pm_product_variant(id)
    end

    def validate_pm_product_params(params)
      PmProductSchema.call(params)
    end

    def validate_clone_pm_product_params(params)
      ClonePmProductSchema.call(params)
    end

    def validate_completed_pm_product_params(params)
      CompletedPmProductSchema.call(params)
    end

    def validate_pm_product_variant_params(params)
      PmProductVariantSchema.call(params)
    end

    def validate_clone_pm_product_variant_params(params)
      ClonePmProductVariantSchema.call(params)
    end

    def validate_completed_pm_product_variant_params(params)
      CompletedPmProductVariantSchema.call(params)
    end
  end
end
