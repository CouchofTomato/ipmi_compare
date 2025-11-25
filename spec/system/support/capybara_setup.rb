# frozen_string_literal: true

# Allow tuning wait time in CI where things can be slower.
Capybara.default_max_wait_time = ENV.fetch('CAPYBARA_DEFAULT_MAX_WAIT_TIME', 2).to_f

# Normalize whitespaces when using `has_text?` and similar matchers,
# i.e., ignore newlines, trailing spaces, etc.
# That makes tests less dependent on slightly UI changes.
Capybara.default_normalize_ws = true

# Where to store system tests artifacts (e.g. screenshots, downloaded files, etc.).
# It could be useful to be able to configure this path from the outside (e.g., on CI).
Capybara.save_path = ENV.fetch('CAPYBARA_ARTIFACTS', './tmp/capybara')

# The Capybara.using_session allows you to manipulate a different browser session, and thus,
# multiple independent sessions within a single test scenario. That’s especially useful for
# testing real-time features, e.g., something with WebSocket.
#
# This patch tracks the name of the last session used. We’re going to use this information to
# support taking failure screenshots in multi-session tests.
Capybara.singleton_class.prepend(Module.new do
  attr_accessor :last_used_session

  def using_session(name, &block)
    self.last_used_session = name
    super
  ensure
    self.last_used_session = nil
  end
end)

Capybara.add_selector(:test_id) do
  css { |value| "[data-test-id='#{value}']" }
end
