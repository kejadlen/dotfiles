require "minitest/autorun"

require_relative "workflow"

class TestWorkflow < Minitest::Test
  def test_i18n_failure
    workflow = Workflow::Faker.new("a")
    workflow.items.to_xml
  end
end
