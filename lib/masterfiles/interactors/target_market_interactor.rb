# frozen_string_literal: true

class TargetMarketInteractor < BaseInteractor
  def create_tm_group_type(params)
    res = validate_tm_group_type_params(params)
    return validation_failed_response(res) unless res.messages.empty?
    @tm_group_type_id = target_market_repo.create_tm_group_type(res.to_h)
    success_response("Created target market group type #{tm_group_type.target_market_group_type_code}",
                     tm_group_type)
  end

  def update_tm_group_type(id, params)
    @tm_group_type_id = id
    res = validate_tm_group_type_params(params)
    return validation_failed_response(res) unless res.messages.empty?
    target_market_repo.update_tm_group_type(id, res.to_h)
    success_response("Updated target market group type #{tm_group_type.target_market_group_type_code}",
                     tm_group_type(false))
  end

  def delete_tm_group_type(id)
    @tm_group_type_id = id
    name = tm_group_type.target_market_group_type_code
    target_market_repo.delete_tm_group_type(id)
    success_response("Deleted target market group type #{name}")
  end

  def create_tm_group(params)
    res = validate_tm_group_params(params)
    return validation_failed_response(res) unless res.messages.empty?
    @tm_group_id = target_market_repo.create_tm_group(res.to_h)
    success_response("Created target market group #{tm_group.target_market_group_name}", tm_group)
  end

  def update_tm_group(id, params)
    @tm_group_id = id
    res = validate_tm_group_params(params)
    return validation_failed_response(res) unless res.messages.empty?
    target_market_repo.update_tm_group(id, res.to_h)
    success_response("Updated target market group #{tm_group.target_market_group_name}", tm_group(false))
  end

  def delete_tm_group(id)
    @tm_group_id = id
    name = tm_group.target_market_group_name
    target_market_repo.delete_tm_group(id)
    success_response("Deleted target market group #{name}")
  end

  def create_target_market(params)
    country_ids = params.delete(:country_ids)
    tm_group_ids = params.delete(:tm_group_ids)
    res = validate_target_market_params(params)
    return validation_failed_response(res) unless res.messages.empty?
    @target_market_id = target_market_repo.create_target_market(res.to_h)
    country_response = link_countries(@target_market_id, country_ids)
    tm_groups_response = link_tm_groups(@target_market_id, tm_group_ids)
    success_response("Created target market #{target_market.target_market_name}, #{country_response.message}, #{tm_groups_response.message}", target_market)
  end

  def update_target_market(id, params)
    country_ids = params.delete(:country_ids)
    tm_group_ids = params.delete(:tm_group_ids)
    @target_market_id = id
    res = validate_target_market_params(params)
    return validation_failed_response(res) unless res.messages.empty?
    country_response = link_countries(@target_market_id, country_ids)
    tm_groups_response = link_tm_groups(@target_market_id, tm_group_ids)
    target_market_repo.update_target_market(id, res.to_h)
    success_response("Updated target market #{target_market.target_market_name}, #{country_response.message}, #{tm_groups_response.message}", target_market(false))
  end

  def delete_target_market(id)
    @target_market_id = id
    name = target_market.target_market_name
    target_market_repo.delete_target_market(id)
    success_response("Deleted target market #{name}")
  end

  def link_countries(target_market_id, country_ids)
    DB.transaction do
      target_market_repo.link_countries(target_market_id, country_ids)
    end

    existing_ids = target_market_repo.target_market_country_ids(target_market_id)
    if existing_ids.eql?(country_ids.sort)
      success_response('Countries linked successfully')
    else
      failed_response('Some countries were not linked')
    end
  end

  def link_tm_groups(target_market_id, tm_group_ids)
    DB.transaction do
      target_market_repo.link_tm_groups(target_market_id, tm_group_ids)
    end

    existing_ids = target_market_repo.target_market_tm_group_ids(target_market_id)
    if existing_ids.eql?(tm_group_ids.sort)
      success_response('Target market groups linked successfully')
    else
      failed_response('Some target market groups were not linked')
    end
  end

  private

  def target_market_repo
    @target_market_repo ||= TargetMarketRepo.new
  end

  def tm_group_type(cached = true)
    if cached
      @tm_group_type ||= target_market_repo.find_tm_group_type(@tm_group_type_id)
    else
      @tm_group_type = target_market_repo.find_tm_group_type(@tm_group_type_id)
    end
  end

  def validate_tm_group_type_params(params)
    TargetMarketGroupTypeSchema.call(params)
  end

  def tm_group(cached = true)
    if cached
      @tm_group ||= target_market_repo.find_tm_group(@tm_group_id)
    else
      @tm_group = target_market_repo.find_tm_group(@tm_group_id)
    end
  end

  def validate_tm_group_params(params)
    TargetMarketGroupSchema.call(params)
  end

  def target_market(cached = true)
    if cached
      @target_market ||= target_market_repo.find_target_market(@target_market_id)
    else
      @target_market = target_market_repo.find_target_market(@target_market_id)
    end
  end

  def validate_target_market_params(params)
    TargetMarketSchema.call(params)
  end
end
