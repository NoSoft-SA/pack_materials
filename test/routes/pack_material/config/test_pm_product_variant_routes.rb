# frozen_string_literal: true

require File.join(File.expand_path('./../../../', __dir__), 'test_helper_for_routes')

class TestPmProductVariantRoutes < RouteTester

  INTERACTOR = PackMaterialApp::PmProductInteractor

  def test_edit
    authorise_pass!
    ensure_exists!(INTERACTOR)
    PackMaterial::Config::PmProductVariant::Edit.stub(:call, bland_page) do
      get 'pack_material/config/pack_material_product_variants/1/edit', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_edit_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'pack_material/config/pack_material_product_variants/1/edit', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_clone
    authorise_pass!
    ensure_exists!(INTERACTOR)
    PackMaterial::Config::PmProductVariant::Clone.stub(:call, bland_page) do
      get 'pack_material/config/pack_material_product_variants/1/clone', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_clone_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'pack_material/config/pack_material_product_variants/1/clone', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_show
    authorise_pass!
    ensure_exists!(INTERACTOR)
    PackMaterial::Config::PmProductVariant::Show.stub(:call, bland_page) do
      get 'pack_material/config/pack_material_product_variants/1', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_show_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'pack_material/config/pack_material_product_variants/1', {}, 'rack.session' => { user_id: 1 }
    refute last_response.ok?
    assert_match(/permission/i, last_response.body)
  end

  def test_update
    authorise_pass!
    ensure_exists!(INTERACTOR)
    row_vals = Hash.new(1)
    INTERACTOR.any_instance.stubs(:update_pm_product_variant).returns(ok_response(instance: row_vals))
    patch_as_fetch 'pack_material/config/pack_material_product_variants/1', {}, 'rack.session' => { user_id: 1, last_grid_url: '/' }
    expect_json_update_grid
  end

  def test_update_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:update_pm_product_variant).returns(bad_response)
    PackMaterial::Config::PmProductVariant::Edit.stub(:call, bland_page) do
      patch_as_fetch 'pack_material/config/pack_material_product_variants/1', {}, 'rack.session' => { user_id: 1, last_grid_url: '/' }
    end
    expect_json_replace_dialog(has_error: true)
  end

  def test_delete
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_pm_product_variant).returns(ok_response)
    delete_as_fetch 'pack_material/config/pack_material_product_variants/1', {}, 'rack.session' => { user_id: 1, last_grid_url: '/' }
    expect_json_delete_from_grid
  end

  def test_new
    authorise_pass!
    ensure_exists!(INTERACTOR)
    PackMaterial::Config::PmProductVariant::New.stub(:call, bland_page) do
      get  'pack_material/config/pack_material_products/1/pack_material_product_variants/new', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_new_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'pack_material/config/pack_material_products/1/pack_material_product_variants/new', {}, 'rack.session' => { user_id: 1 }
    refute last_response.ok?
    assert_match(/permission/i, last_response.body)
  end

  def test_create
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:create_pm_product_variant).returns(ok_response)
    post_as_fetch 'pack_material/config/pack_material_products/1/pack_material_product_variants', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_ok_json_redirect
  end

  def test_create_remotely
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:create_pm_product_variant).returns(ok_response)
    post_as_fetch 'pack_material/config/pack_material_products/1/pack_material_product_variants', {}, 'rack.session' => { user_id: 1, last_grid_url: '/' }
    expect_ok_json_redirect
  end

  def test_create_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:create_pm_product_variant).returns(bad_response)
    PackMaterial::Config::PmProductVariant::New.stub(:call, bland_page) do
      post_as_fetch 'pack_material/config/pack_material_products/1/pack_material_product_variants', {}, 'rack.session' => { user_id: 1, last_grid_url: '/' }
    end
    expect_bad_page

    PackMaterial::Config::PmProductVariant::New.stub(:call, bland_page) do
      post 'pack_material/config/pack_material_products/1/pack_material_product_variants', {}, 'rack.session' => { user_id: 1, last_grid_url: '/' }
    end
    expect_bad_redirect(url: '/pack_material/config/pack_material_products/1/pack_material_product_variants/new')
  end

  def test_create_remotely_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:create_pm_product_variant).returns(bad_response)
    PackMaterial::Config::PmProductVariant::New.stub(:call, bland_page) do
      post_as_fetch 'pack_material/config/pack_material_products/1/pack_material_product_variants', {}, 'rack.session' => { user_id: 1, last_grid_url: '/' }
    end
    expect_json_replace_dialog
  end

  def test_clone_post
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:clone_pm_product_variant).returns(ok_response)
    post 'pack_material/config/pack_material_products/1/pack_material_product_variants/clone/1', {}, 'rack.session' => { user_id: 1, last_grid_url: '/list/users' }
    expect_ok_redirect

    post_as_fetch 'pack_material/config/pack_material_products/1/pack_material_product_variants/clone/1', {}, 'rack.session' => { user_id: 1, last_grid_url: '/' }
    expect_ok_json_redirect
  end

  def test_clone_post_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:clone_pm_product_variant).returns(bad_response)
    PackMaterial::Config::PmProductVariant::Clone.stub(:call, bland_page) do
      post 'pack_material/config/pack_material_products/1/pack_material_product_variants/clone/1', {}, 'rack.session' => { user_id: 1, last_grid_url: '/' }
    end
    assert last_response.redirect?
    assert_equal '/pack_material/config/pack_material_product_variants/clone/1', last_response.location
    refute last_response.ok?

    PackMaterial::Config::PmProductVariant::Clone.stub(:call, bland_page) do
      post_as_fetch 'pack_material/config/pack_material_products/1/pack_material_product_variants/clone/1', {}, 'rack.session' => { user_id: 1, last_grid_url: '/' }
    end
    expect_json_replace_dialog
  end
end
