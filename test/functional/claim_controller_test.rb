require 'test_helper'

class ClaimControllerTest < ActionController::TestCase
  def test_find
    get :find
    assert_response :success
  end
end
