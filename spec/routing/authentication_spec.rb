require "spec_helper"

describe "Authentication" do

  it "routes arbitrary scopes" do
    {:get => "/coca/check"}.should route_to(
      :controller => "coca/authentications",
      :action => "show",
      :version => "1",
      :format => "json"
    )

  end
end
