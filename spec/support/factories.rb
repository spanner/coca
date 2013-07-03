FactoryGirl.define do
  
  factory :user do
    sequence(:email) { |n| "user#{n}@spanner.org" }
    uid { SecureRandom.uuid }
    
    factory :local_user do
      sequence(:name) { |n| "User #{n}" }
      authentication_token "local_token"
      after(:build) { |u| u.password_confirmation = u.password = "testy" }
    end

    factory :remote_user do
      sequence(:name) { |n| "Remote User #{n}" }
      authentication_token "remote_token"
    end
  end

  factory :delegate, :class => Coca::Delegate do
    sequence(:name) { |n| "Delegate #{n}" }
    host 'test.spanner.org'
  end

end