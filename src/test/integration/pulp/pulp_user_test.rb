# Copyright 2012 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

require 'rubygems'
require 'minitest/autorun'
require 'test/integration/pulp/vcr_pulp_setup'


module TestPulpUserBase

  def setup
    @resource = Resources::Pulp::User
    VCR.insert_cassette('pulp_user')
  end

  def teardown
    VCR.eject_cassette
  end

end

class TestPulpUser < MiniTest::Unit::TestCase
  include TestPulpUserBase

  def setup
    @username = "admin"
    super
  end

  def test_path_without_username
    path = @resource.path
    assert_match("/api/users/", path)
  end

  def test_path_with_username
    path = @resource.path(@username)
    assert_match("/api/users/" + @username, path)
  end

  def test_find
    response = @resource.find(@username)
    assert response.length > 0
    assert(@username, response["login"])
  end

end


class TestPulpUserCreate < MiniTest::Unit::TestCase
  include TestPulpUserBase

  def setup
    @username = "integration_test_user"
    super
  end

  def teardown
    super
    @resource.destroy("integration_test_user")
  rescue Exception => e
  end

  def test_create
    response = @resource.create(:login => "integration_test_user", :name => "integration_test_user", :password => "integration_test_password")
    assert response.length > 0
    @resource.destroy("integration_test_user")
  end
end


class TestPulpUserDestroy < MiniTest::Unit::TestCase
  include TestPulpUserBase

  def setup
    super
    @username = "integration_test_user"
    @resource.create(:login => "integration_test_user", :name => "integration_test_user", :password => "integration_test_password")
  end

  def test_destroy
    response = @resource.destroy("integration_test_user")
    assert response == 200
  end

end
