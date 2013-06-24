require "spec_helper"

describe "Authentication" do

  it "routes arbitrary scopes" do
    {:get => "/coca/1/user"}.should route_to(
      :controller => "coca/authentications",
      :action => "check",
      :scope => "user",
      :version => "1",
      :format => "json"
    )

    {:post => "/coca/1/foo"}.should route_to(
      :controller => "coca/authentications",
      :action => "check",
      :scope => "foo",
      :version => "1",
      :format => "json"
    )
  end
end
