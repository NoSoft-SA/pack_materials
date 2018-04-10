# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/BlockLength

# TODO: Get rubocop in from the start....

require 'roda'
require 'rodauth'
require 'awesome_print'
# require 'sequel'
require 'crossbeams/layout'
require 'crossbeams/dataminer'
# require 'crossbeams/dataminer_interface'
require 'crossbeams/label_designer'
require 'crossbeams/rack_middleware'
require 'roda/data_grid'
require 'yaml'
require 'pstore'
require 'base64'
require 'dry/inflector'
require 'dry-struct'
require 'dry-validation'
require 'asciidoctor'
require'yard'

module Types
  include Dry::Types.module

  # Strips leading and trailing spaces from the input string.
  # Returns nil if the new result is blank.
  # Non-string input (including nil) passes through to be handled by the dry-validation schema.
  StrippedString = Types::String.constructor do |str|
    if str&.is_a?(::String)
      newstr = str.strip.chomp
      newstr.empty? ? nil : newstr
    else
      str
    end
  end
end

require './lib/crossbeams_responses'
require './lib/repo_base'
require './lib/base_interactor'
require './lib/base_service'
require './lib/local_store' # Will only work for processes running from one dir.
require './lib/ui_rules'
require './lib/library_versions'
require './lib/dataminer_connections'
Dir['./helpers/**/*.rb'].each { |f| require f }
Dir['./lib/applets/*.rb'].each { |f| require f }

ENV['ROOT'] = File.dirname(__FILE__)
ENV['VERSION'] = File.read('VERSION')
ENV['GRID_QUERIES_LOCATION'] ||= File.expand_path('grid_definitions/dataminer_queries', __dir__)

DM_CONNECTIONS = DataminerConnections.new

class Framework < Roda
  include CommonHelpers
  include MenuHelpers
  include DataminerHelpers

  # Store the name of this class for use in scaffold generating.
  ENV['RODA_KLASS'] = to_s

  use Rack::Session::Cookie, secret: 'some_other_nice_long_random_string_DSKJH4378EYR7EGKUFH', key: '_myapp_session'
  use Rack::MethodOverride # Use with all_verbs plugin to allow 'r.delete' etc.
  use Crossbeams::RackMiddleware::Banner, template: 'views/_page_banner.erb' # , session: request.session

  plugin :data_grid, path: File.dirname(__FILE__),
                     list_url: '/list/%s/grid',
                     list_nested_url: '/list/%s/nested_grid',
                     list_multi_url: '/list/%s/grid_multi',
                     search_url: '/search/%s/grid',
                     filter_url: '/search/%s',
                     run_search_url: '/search/%s/run',
                     run_to_excel_url: '/search/%s/xls'
  plugin :all_verbs
  plugin :render
  plugin :partials
  plugin :assets, css: 'style.scss', precompiled: 'prestyle.css'  # , js: 'behave.js'
  plugin :public # serve assets from public folder.
  plugin :view_options
  plugin :multi_route
  plugin :content_for, append: true
  plugin :symbolized_params    # - automatically converts all keys of params to symbols.
  plugin :flash
  plugin :csrf, raise: true, skip_if: ->(_) { ENV['RACK_ENV'] == 'test' }  # , :skip => ['POST:/report_error'] # FIXME: Remove the +raise+ param when going live!
  plugin :rodauth do
    db DB
    enable :login, :logout # , :change_password
    logout_route 'a_dummy_route' # Override 'logout' route so that we have control over it.
    # logout_notice_flash 'Logged out'
    session_key :user_id
    login_param 'login_name'
    login_label 'Login name'
    login_column :login_name
    accounts_table :vw_active_users # Only active users can login.
    account_password_hash_column :password_hash
  end
  # plugin :error_handler do |e|
  #   # TODO: how to handle AJAX/JSON etc...
  #   view(inline: "An error occurred - #{e.message}") # TODO: refine this to handle certain classes of errors in certain ways.
  #   # (could do something like - inline: render errorview(e) ...)
  # end
  Dir['./routes/*.rb'].each { |f| require f }

  route do |r|
    r.assets unless ENV['RACK_ENV'] == 'production'
    r.public

    r.rodauth
    rodauth.require_authentication
    r.redirect('/login') if current_user.nil? # Session might have the incorrect user_id

    r.root do
      # flash.now[:error] = 'A TEST' # <=== Add this...
      s = <<-HTML
      <h2>Kromco packhouse</h2>
      <p>There are currently 99 bins and 99 pallets on site.</p>
      <p>Since 1 December 2016: <ul>
      <li>99 deliveries have been received</li>
      <li>99 cartons have been packed</li>
      </p>
      HTML
      view(inline: s)
    end

    r.on 'developer_documentation', String do |file|
      # Docs are in developer_documentation in asciidoc format named file.adoc.
      # Guide to writing docs: http://asciidoctor.org/docs/asciidoc-writers-guide
      content = File.read(File.join(File.dirname(__FILE__), 'developer_documentation', "#{file.chomp('.adoc')}.adoc"))
      view(inline: <<~HTML)
        <% content_for :late_head do %>
          <link rel="stylesheet" href="/css/asciidoc.css">
        <% end %>
        <div id="asciidoc-content">
          #{Asciidoctor.convert(content, safe: :safe)}
        </div>
      HTML
    end

    r.on 'yarddocthis', String do |file|
      # Reads Yard doc comments for a file and displays them.
      # NB: The file param must have all '/' in the name replaced with '='.
      filename = File.join(File.dirname(__FILE__), file.tr('=', '/'))
      YARD::Registry.clear
      YARD.parse_string(File.read(filename))
      mds = YARD::Registry.all(:method)
      toc = []
      out = []
      mds.each do |m|
        next if m.visibility == :private
        toc << m.name
        parms = m.tags.select { |t| t.tag_name == 'param' }.map { |t| "#{t.name} (#{t.types.join(', ')}): #{t.text}" }
        rets = m.tags.select { |t| t.tag_name == 'return' }.map(&:text)
        out << <<~HTML
          <a id="#{m.name}"></a><h2>#{m.name}</h2>
          <table>
          <tr><th>Method:</th><td>#{m.signature.sub('def ', '')}</td></tr>
          <tr><th>       </th><td><pre>#{m.docstring}</pre></td></tr>
          <tr><th>Params:</th><td>#{parms.empty? ? '' : "<ul><li>#{parms.join('</li><li>')}</ul>"}</td></tr>
          <tr><th>Return:</th><td>#{rets.empty? ? '' : rets.join(', ')}</td></tr>
          </table>
        HTML
      end

      view(inline: <<~HTML)
        <% content_for :late_head do %>
          <link rel="stylesheet" href="/css/asciidoc.css">
        <% end %>
        <div id="asciidoc-content">
          <h1>Yard documentation for methods in #{file.tr('=', '/')}</h1>
          #{request.referer.nil? ? '' : "<p><a href='#{request.referer}'>Back</a></p>"}
          <p>NB. This reads the source file to build the docs, so it is always up-to-date.
          Note that this simple code might pick up some extra definitions and also note that
          it uses Yard in a way it was not designed for, so this could all break with an update to Yard.</p>
          <ul>#{toc.map { |t| "<li><a href='##{t}'>#{t}</a></li>" }.join("\n")}</ul>
          #{out.join("\n")}
        </div>
      HTML
    end

    r.multi_route

    r.on 'iframe', Integer do |id|
      repo = SecurityApp::MenuRepo.new
      pf = repo.find_program_function(id)
      view(inline: %(<iframe src="#{pf.url}" title="#{pf.program_function_name}" width="100%" style="height:80vh"></iframe>))
    end

    r.is 'test' do
      view('test_view')
    end

    r.is 'logout' do
      rodauth.logout
      flash[:notice] = 'Logged out'
      r.redirect('/login')
    end

    r.is 'versions' do
      versions = LibraryVersions.new(:layout,
                                     :dataminer,
                                     :label_designer,
                                     :rackmid,
                                     :datagrid,
                                     :ag_grid,
                                     :selectr,
                                     :sortable,
                                     :konva,
                                     :lodash,
                                     :multi,
                                     :sweetalert)
      @layout = Crossbeams::Layout::Page.build do |page, _|
        page.section do |section|
          section.add_text('Gem and Javascript library versions', wrapper: :h2)
          section.add_table(versions.to_a, versions.columns, alignment: { version: :right })
        end
      end
      view('crossbeams_layout_page')
    end

    r.is 'not_found' do
      response.status = 404
      view(inline: '<div class="crossbeams-error-note"><strong>Error</strong><br>The requested resource was not found.</div>')
    end

    # Generic grid lists.
    r.on 'list' do
      r.on :id do |id|
        r.is do
          session[:last_grid_url] = "/list/#{id}"
          show_page { render_data_grid_page(id) }
        end

        r.on 'with_params' do
          if fetch?(r)
            show_partial { render_data_grid_page(id, query_string: request.query_string) }
          else
            session[:last_grid_url] = "/list/#{id}/with_params?#{request.query_string}"
            show_page { render_data_grid_page(id, query_string: request.query_string) }
          end
        end

        r.on 'multi' do
          if fetch?(r)
            show_partial { render_data_grid_page_multiselect(id, params) }
          else
            show_page { render_data_grid_page_multiselect(id, params) }
          end
        end

        r.on 'grid' do
          response['Content-Type'] = 'application/json'
          begin
            if params && !params.empty?
              render_data_grid_rows(id, ->(program, permission) { auth_blocked?(program, permission) }, params)
            else
              render_data_grid_rows(id, ->(program, permission) { auth_blocked?(program, permission) })
            end
          rescue StandardError => e
            show_json_exception(e)
          end
        end

        r.on 'grid_multi', String do |key|
          response['Content-Type'] = 'application/json'
          begin
            render_data_grid_multiselect_rows(id, ->(program, permission) { auth_blocked?(program, permission) }, key, params)
          rescue StandardError => e
            show_json_exception(e)
          end
        end

        r.on 'nested_grid' do
          response['Content-Type'] = 'application/json'
          begin
            render_data_grid_nested_rows(id)
          rescue StandardError => e
            show_json_exception(e)
          end
        end
      end
    end

    r.on 'print_grid' do
      @layout = Crossbeams::Layout::Page.build(grid_url: params[:grid_url]) do |page, _|
        page.add_grid('crossbeamsPrintGrid', params[:grid_url], caption: 'Print', for_print: true)
      end
      view('crossbeams_layout_page', layout: 'print_layout')
    end

    # - :url: "/list/users/multi?key=program_users&id=$:id$/"

    # In-page grids (no last grid_url)
    # 1) list with multi-select - might need last_grid
    # 2) list_section - never use last_grid
    r.on 'list_section' do
      # list_section/users/?user_id=123&multi_select=fredo
      # open users yml & look for fredo multiselect to get rules
      #
      # list_section/users/?user_id=123
      # open users yml & apply user_id param
      #
    end

    # Generic code for grid searches.
    r.on 'search' do
      r.on :id do |id|
        r.is do
          render_search_filter(id, params)
        end

        r.on 'run' do
          session[:last_grid_url] = "/search/#{id}?rerun=y"
          show_page { render_search_grid_page(id, params) }
        end

        r.on 'grid' do
          response['Content-Type'] = 'application/json'
          render_search_grid_rows(id, params, ->(program, permission) { auth_blocked?(program, permission) })
        end

        r.on 'xls' do
          caption, xls = render_excel_rows(id, params)
          response.headers['content_type'] = 'application/vnd.ms-excel'
          response.headers['Content-Disposition'] = "attachment; filename=\"#{caption.strip.gsub(%r{[/:*?"\\<>\|\r\n]}i, '-') + '.xls'}\""
          response.write(xls) # NOTE: could this use streaming to start downloading quicker?
        rescue Sequel::DatabaseError => e
          view(inline: <<-HTML)
          <p style='color:red;'>There is a problem with the SQL definition of this report:</p>
          <p>Report: <em>#{caption}</em></p>The error message is:
          <pre>#{e.message}</pre>
          <button class="pure-button" onclick="crossbeamsUtils.toggleVisibility('sql_code', this);return false">
            <i class="fa fa-info"></i> Toggle SQL
          </button>
          <pre id="sql_code" style="display:none;"><%= sql_to_highlight(@rpt.runnable_sql) %></pre>
          HTML
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/BlockLength
