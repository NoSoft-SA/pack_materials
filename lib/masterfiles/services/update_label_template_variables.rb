# frozen_string_literal: true

module MasterfilesApp
  class UpdateLabelTemplateVariables < BaseService
    attr_reader :label_template, :xml, :repo, :user

    def initialize(id, xml, user)
      @repo = LabelTemplateRepo.new

      @label_template = repo.find_label_template(id)
      @xml = xml
      @user = user
    end

    def call
      res = variables_from_xml(xml)
      return res unless res.success

      store_new_label_variables(res.instance)
    end

    private

    def store_new_label_variables(package) # rubocop:disable Metrics/AbcSize
      repo.transaction do
        repo.update_label_template(label_template.id, package)
        repo.log_action(user_name: user.user_name, context: 'NSLD label refreshed')
        repo.log_status('label_templates', label_template.id, 'VARIABLE_LIST_UPDATED', comment: 'from refresh event', user_name: user.user_name)
      end
      success_response('Variables stored', label_template)
    end

    def variables_from_xml(xml_string)
      doc = Nokogiri::XML(xml_string)
      return failed_response('This is not an NSLD label definition') if doc.css('nsld_schema').empty?

      var_list = doc.css('variable_type').map(&:text)
      res = validate_variable_names(label_template, var_list)
      return res unless res.success

      success_response('ok', variables: var_list.empty? ? nil : repo.array_for_db_col(var_list), variable_rules: create_variable_rules(var_list))
    end

    def validate_variable_names(instance, var_list)
      messages = check_variables(instance, var_list)
      if messages.empty?
        success_response('ok')
      else
        validation_failed_response(OpenStruct.new(messages: { base: messages }))
      end
    rescue Crossbeams::FrameworkError => e
      failed_response(e.message)
    end

    def shared_label_config
      @shared_label_config ||= begin
                                 config_repo = LabelApp::SharedConfigRepo.new
                                 config_repo.packmat_labels_config
                               end
    end

    def check_variables(instance, var_list)
      messages = []
      var_list.each do |varname|
        next if varname.start_with?('CMP:')
        settings = shared_label_config[varname]
        if settings.nil?
          messages << "There is no configuration for variable \"#{varname}\""
        else
          messages << "Variable \"#{varname}\" is not available for application \"#{instance.application}\"" unless settings[:applications].include?(instance.application)
        end
      end
      messages
    end

    def create_variable_rules(var_list)
      return nil if var_list.empty?
      hash = { variables: [] }
      var_array = hash[:variables]

      var_list.each do |varname|
        if varname.start_with?('CMP:')
          resolver = 'CMP:' # TODO: build this up...
          var_array << { varname => { group: 'Composites', resolver: resolver, applications: [label_template.application] } }
        else
          var_array << { varname => shared_label_config[varname] }
        end
      end
      repo.hash_for_jsonb_col(hash)
    end
  end
end