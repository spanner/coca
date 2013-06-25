FactoryGirl.define do
  
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@spanner.org" }
    uid { SecureRandom.uuid }
    authentication_token "amigo!"
    after(:build) { |u| u.password_confirmation = u.password = "testy" }
  end

  factory :delegate, :class => Coca::Delegate do
    host 'test.spanner.org'
    
    trait :specified do
      port '1234'
      ttl 3600
    end

  end

end