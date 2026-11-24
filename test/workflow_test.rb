# frozen_string_literal: true

require 'minitest/autorun'
require 'open3'
require 'yaml'

class WorkflowDispatchTest < Minitest::Test
  def setup
    workflow = YAML.safe_load_file(File.expand_path('../.github/workflows/run.yml', __dir__))
    steps = workflow.fetch('jobs').fetch('run').fetch('steps')
    @command = steps.find { |step| step['name'] == 'count workflow dispatch' }.fetch('run')
  end

  def test_rejects_blank_owners_before_invoking_ruby
    [nil, '', '   ', " \t\r\n"].each do |owner|
      stdout, stderr, status = dispatch(owner)
      assert_equal 1, status.exitstatus
      assert_empty stdout
      assert_includes stderr, 'Enter a GitHub organization or username'
    end
  end

  def test_preserves_nonblank_owner_as_one_argument
    ['balter-test-org', ' owner with spaces '].each do |owner|
      stdout, stderr, status = dispatch(owner)
      assert_predicate status, :success?
      assert_empty stderr
      assert_equal "<exec>\n<ruby>\n<loc.rb>\n<#{owner}>\n", stdout
    end
  end

  private

  def dispatch(owner)
    stub = <<~'BASH'
      bundle() { printf '<%s>\n' "$@"; }
    BASH
    Open3.capture3({ 'COUNT_OWNER' => owner }, 'bash', '-e', '-c', "#{stub}#{@command}")
  end
end
