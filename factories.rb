require 'factory_girl'

FactoryGirl.define do
  factory :classification do
    resource
    name {Faker::Lorem.characters(12)}
    purchased_previous true
    spend 1000000
    aggrement_end Time.now.to_date

    after(:create) do |classification|
      classification.supply_attributes = FactoryGirl.attributes_for :supply
      classification.save
    end
  end

  factory :user do
    company
    currency
    email {Faker::Internet.email}
    office_phone {Faker::PhoneNumber.cell_phone}
    country 'IN'
  end

  factory :resource do
    name 'resouce name'
    description 'test description'
    currency
    company_spend 150000000
    user
  end
end