Coca.secret = "Desperado"

Coca.add_master "Master" do |master|
  master.host = "master.spanner.org"
end

Coca.add_servant "Servant" do |servant|
  servant.host = "servant.spanner.org"
end
