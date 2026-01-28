RSpec.configure do |config|
  config.include Warden::Test::Helpers, type: :system

  config.before(:suite) do
    Warden.test_mode!
  end

  config.after(:suite) do
    Warden.test_reset!
  end

  config.after do
    Warden.test_reset!
  end
end
