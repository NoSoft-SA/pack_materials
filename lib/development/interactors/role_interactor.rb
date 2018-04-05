# frozen_string_literal: true

module DevelopmentApp
  class RoleInteractor < BaseInteractor
    def repo
      @repo ||= RoleRepo.new
    end

    def role(cached = true)
      if cached
        @role ||= repo.find_role(@id)
      else
        @role = repo.find_role(@id)
      end
    end

    def validate_role_params(params)
      RoleSchema.call(params)
    end

    def create_role(params)
      res = validate_role_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      @id = repo.create_role(res)
      success_response("Created role #{role.name}",
                       role)
    end

    def update_role(id, params)
      @id = id
      res = validate_role_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      repo.update_role(id, res)
      success_response("Updated role #{role.name}",
                       role(false))
    end

    def delete_role(id)
      @id = id
      name = role.name
      repo.delete_role(id)
      success_response("Deleted role #{name}")
    end
  end
end
