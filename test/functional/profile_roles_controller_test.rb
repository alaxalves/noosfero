require_relative '../test_helper'

class ProfileRolesControllerTest < ActionDispatch::IntegrationTest

  def setup
    @controller = ProfileRolesController.new

    @role = Role.first
  end

  should 'create a custom role' do
    community = fast_create(Community)
    admin = create_user_with_permission('admin_user', 'manage_custom_roles', community)
    login_as_rails5 :admin_user
    post profile_roles_path(community.identifier), params: {:role => {:name => "some_role", :permissions => ["edit_profile"] }}
    role = Role.where(:name => 'some_role').first

    assert_not_nil role
    assert_equal community.id, role.profile_id
  end

  should 'not create a custom role without permission' do
    community = fast_create(Community)
    moderator = create_user_with_permission('profile_admin', 'edit_profile', community)
    login_as_rails5 :profile_admin
    post profile_roles_path(community.identifier), params: {:role => {:name => "new_admin", :permissions => ["edit_profile"] }}

    assert_response 403
    assert_template 'shared/access_denied'

    role = Role.where(:name => 'new_admin')

    assert_empty role
  end


  should 'delete a custom role not used' do
    community = fast_create(Community)
    admin = create_user_with_permission('admin_user', 'manage_custom_roles', community)
    login_as_rails5 :admin_user
    role = Role.create!({:name => 'delete_article', :key => 'profile_delete_article', :profile_id => community.id, :environment => Environment.default}, :without_protection => true)
    post remove_profile_role_path(community.identifier, role)

    assert_response :redirect
    assert_redirected_to :action => 'index'

    assert_not_includes Role.all, role
  end

  should 'delete a custom role being used' do
    community = fast_create(Community)
    admin = create_user_with_permission('admin_user', 'manage_custom_roles', community)
    login_as_rails5 :admin_user
    role = Role.create!({:name => 'delete_article', :key => 'profile_delete_article', :profile_id => community.id, :environment => Environment.default}, :without_protection => true)
    admin.add_role(role, community)
    moderator_role = Role.find_by(name: "moderator")

    assert_not_includes community.members_by_role(moderator_role), admin

    post remove_profile_role_path(community.identifier, role), params: {:roles => [moderator_role.id]}

    assert_response :redirect
    assert_redirected_to :action => 'index'

    assert_not_includes Role.all, role
    assert_includes community.members_by_role(moderator_role), admin
  end

  should 'assign a custom role to single user' do
    community = fast_create(Community)
    admin = create_user_with_permission('admin_user', 'manage_custom_roles', community)
    login_as_rails5 :admin_user
    role = Role.create!({:name => 'delete_article', :key => 'profile_delete_article', :profile_id => community.id, :environment => Environment.default}, :without_protection => true)

    assert_not_includes community.members_by_role(role), admin

    post define_profile_role_path(community.identifier, role), params: {:assign_role_by => "members", :person_id => admin.id}

    assert_includes community.members_by_role(role), admin
  end

  should  'replace a role with a custom role' do
    community = fast_create(Community)
    admin = create_user_with_permission('admin_user', 'manage_custom_roles', community)
    moderator = create_user_with_permission('profile_admin', 'edit_profile', community)
    login_as_rails5 :admin_user
    role = Role.create!({:name => 'delete_article', :key => 'profile_delete_article', :profile_id => community.id, :environment => Environment.default}, :without_protection => true)
    moderator_role = Role.find_by(name: "moderator")
    admin.add_role(moderator_role, community)

    assert_not_includes community.members_by_role(role), admin

    assert_not_includes community.members_by_role(role), moderator
    assert_not_includes community.members_by_role(moderator_role), moderator

    post define_profile_role_path(community.identifier, role), params: {:assign_role_by => "roles", :selected_role => moderator_role.id}

    assert_not_includes community.members_by_role(moderator_role), admin
    assert_includes community.members_by_role(role), admin

    assert_not_includes community.members_by_role(role), moderator
    assert_not_includes community.members_by_role(moderator_role), moderator
  end

  should 'avoid access with person profile' do
    person = create_user('sample_user').person
    login_as_rails5 person.identifier
    get profile_roles_path(person.identifier)

    assert_response 404
  end
end
