require "spec_helper"

describe "Authentication" do

  it "routes without scope" do
    {:post => "/coca/check.json"}.should route_to(
      :controller => "coca/authentications",
      :action => "show",
      :format => "json"
    )
  end

  it "routes with scope" do
    {:post => "/coca/check/thing.json"}.should route_to(
      :controller => "coca/authentications",
      :action => "show",
      :format => "json",
      :scope => "thing"
    )
  end
  
  it "defaults to json" do
    {:post => "/coca/check"}.should route_to(
      :controller => "coca/authentications",
      :action => "show",
      :format => "json"
    )
  end
  
end
