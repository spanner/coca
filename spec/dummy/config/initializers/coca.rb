Coca.secret = "Desperado"

Coca.delegate_to do |master|
  master.host = "master.spanner.org"
end

Coca.delegate_from do |servant|
  servant.host = "servant.spanner.org"
end
