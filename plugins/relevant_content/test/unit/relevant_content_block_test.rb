require_relative '../test_helper'

class RelevantContentBlockTest < ActiveSupport::TestCase

  include AuthenticatedTestHelper
  fixtures :users, :environments

  def setup
    @controller = CommentController.new

    @profile = create_user('testinguser').person
    @environment = @profile.environment
  end
  attr_reader :profile, :environment

  should 'have a default title' do
    relevant_content_block = RelevantContentPlugin::RelevantContentBlock.new
    block = Block.new
    assert_not_equal block.default_title, relevant_content_block.default_title
  end

  should 'have a help tooltip' do
    relevant_content_block = RelevantContentPlugin::RelevantContentBlock.new
    block = Block.new
    assert_not_equal "", relevant_content_block.help
  end

  should 'describe itself' do
    assert_not_equal Block.description, RelevantContentPlugin::RelevantContentBlock.description
  end

  should 'is editable' do
    block = RelevantContentPlugin::RelevantContentBlock.new
    assert block.editable?
  end

  should 'expire' do
    assert_equal RelevantContentPlugin::RelevantContentBlock.expire_on, {:environment=>[:article], :profile=>[:article]}
  end


  should 'check most voted articles from profile with relevant content block' do
    community = fast_create(Community)
    article = fast_create(Article, {:name=>'2 votes', :profile_id => community.id})
    2.times{
      person = fast_create(Person)
      person.vote_for(article)
    }
    article = fast_create(Article, {:name=>'10 votes', :profile_id => community.id})
    10.times{
        person = fast_create(Person)
        person.vote_for(article)
    }

    Box.create!(owner: community)
    community.boxes[0].blocks << RelevantContentPlugin::RelevantContentBlock.new

    data = Article.most_voted(community, 5)
    assert_equal false, data.empty?
  end

end

require 'boxes_helper'

class RelevantContentBlockViewTest < ActionView::TestCase
  include BoxesHelper

  def setup
    @profile = create_user('testinguser').person
  end

  should 'not crash if vote plugin is not found' do
    box = fast_create(Box, :owner_id => @profile.id, :owner_type => 'Profile')
    block = RelevantContentPlugin::RelevantContentBlock.new(:box => box)

    Environment.any_instance.stubs(:enabled_plugins).returns(['RelevantContent'])
    ActionView::Base.any_instance.expects(:block_title).returns("")
    # When the plugin is disabled from noosfero instance, its constant name is
    # undefined.  To test this case, I have to manually undefine the constant
    # if necessary.
    Object.send(:remove_const, VotePlugin.to_s) if defined? VotePlugin

    assert_nothing_raised do
      render_block_content(block)
    end
  end

  should 'not escape html in block content' do
    fast_create(Article, profile_id: @profile.id, hits: 10)
    box = fast_create(Box, :owner_id => @profile.id, :owner_type => 'Profile')
    block = RelevantContentPlugin::RelevantContentBlock.new(:box => box)

    Environment.any_instance.stubs(:enabled_plugins).returns(['RelevantContent'])
    ActionView::Base.any_instance.expects(:block_title).returns("")
    ActionView::Base.any_instance.stubs(:font_awesome).returns("")

    assert_tag_in_string render_block_content(block), tag: 'span', attributes: { class: 'title mread' }
  end
end
