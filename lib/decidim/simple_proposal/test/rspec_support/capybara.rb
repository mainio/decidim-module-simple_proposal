# frozen_string_literal: true

require "selenium-webdriver"

Capybara.register_driver :headless_chrome do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new
  options.args << "--headless=new"
  options.args << "--no-sandbox"
  # Do not limit browser resources
  options.args << "--disable-dev-shm-usage"
  options.args << if ENV["BIG_SCREEN_SIZE"].present?
                    "--window-size=1920,3000"
                  else
                    "--window-size=1920,1080"
                  end
  options.args << "--ignore-certificate-errors" if ENV["TEST_SSL"]
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    capabilities: [options]
  )
end
