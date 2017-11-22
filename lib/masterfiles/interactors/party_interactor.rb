# frozen_string_literal: true

class PartyInteractor < BaseInteractor

  def link_addresses(id, address_ids)
    party_repo.link_addresses(id, address_ids)

    party = party_repo.find_party(id)
    if (party_repo.existing_address_ids_for_party(id) == address_ids)
      success_response('Addresses linked successfully', party)
    else
      failed_response('Some addresses were not linked', party)
    end
  end

  def link_contact_methods(id, contact_method_ids)
    party_repo.link_contact_methods(id, contact_method_ids)

    party = party_repo.find_party(id)
    if (party_repo.existing_contact_method_ids_for_party(id) == contact_method_ids)
      success_response('Contact methods linked successfully', party)
    else
      failed_response('Some contact methods were not linked', party)
    end
  end

  private

  def party_repo
    @party_repo ||= PartyRepo.new
  end

end
