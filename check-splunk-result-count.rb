#! /usr/bin/env ruby
#
#   check-splunk-result-count
#
# DESCRIPTION:
#   Run a saved search in Splunk and decide to alert based on number of returned results
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: splunk-sdk-ruby
#
# USAGE:
#   check-splunk-result-count.rb -u USERNAME -p PASSWORD -h splunk.example.com -j "Check Log Health" -m gt -c 10
#
# NOTES:
#
# LICENSE:
#   2016 Steve Morrissey <smorrissey@olson.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'splunk-sdk-ruby'
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'

class CheckSplunkResultCount < Sensu::Plugin::Check::CLI
  option :username,
         short: '-u USERNAME',
         description: 'Splunk Username',
         required: true

  option :password,
         short: '-p PASSWORD',
         description: 'Splunk Password',
         required: true

  option :port,
         short: '-P PORT',
         description: 'Splunk API Port (usually 8089)',
         required: false,
         default: 8089,
         proc: proc(&:to_i)

  option :host,
         short: '-h HOST',
         description: 'Splunk Hostname',
         required: true

  option :job,
         short: '-j JOB',
         description: 'Splunk Saved Search to execute (enclose in quotes if needed)',
         required: true

  option :timeout,
         short: '-t TIMEOUT',
         description: 'Time to wait for Search query to finish in seconds',
         required: false,
         default: 5,
         proc: proc(&:to_i)

  option :warn,
         short: '-w COUNT',
         description: 'Warning result number (<= or >= depending on comparison method)',
         default: 5,
         proc: proc(&:to_i),
         required: true

  option :crit,
         short: '-c COUNT',
         description: 'Critical result number (<= or >= depending on comparison method)',
         default: 0,
         proc: proc(&:to_i),
         required: true

  option :compmethod,
         short: '-m COMPMETHOD',
         description: 'Comparison method to use for warning/crit, either lt (less than) or gt (greater than)',
         default: 'lt',
         required: false

  option :help,
         :long => '--help',
         :description => 'Show this message',
         :on => :tail,
         :boolean => true,
         :show_options => true,
         :exit => 0

  def run
    unless %w(lt gt).include?(config[:compmethod])
      unknown "Invalid comparison method specified (-m): #{config[:compmethod]}"
    end

    num_results = splunk_search

    unless num_results.is_a? Numeric
      unknown "Non-numeric result returned from splunk_search method: #{num_results.class}"
    end

    # Logic for determining if it's a critical, warning, or OK
    if config[:compmethod] == 'lt'
      compare_lt(num_results)
    elsif config[:compmethod] == 'gt'
      compare_gt(num_results)
    end
  end

  def splunk_search

    service = Splunk::connect(:host => config[:host], :port => config[:port], :username => config[:username], :password => config[:password])

    # find the Saved Search
    search_target = service.saved_searches.fetch(config[:job])

    # kick off the saved search
    job = search_target.dispatch

    # wait for the search job to complete. we'll die if it takes longer than :timeout seconds to complete
    sleep_iteration = 0
    while !job.is_ready?
      sleep 1

      sleep_iteration += 1
      if sleep_iteration >= config[:timeout]
        unknown "Splunk didn't return valid results before the timeout period of #{config[:timeout]}"
      end
    end

    # create a stream (must be a preview) and load up the results
    stream = job.preview
    results = Splunk::ResultsReader.new(stream)

    # count the number of returned results in this silly way because .count isn't working on the Splunk::ResultsReader :-(
    result_count = 0
    results.each do |result| result_count += 1 end

    return result_count
  end

  def compare_lt(result_count)

    if result_count <= config[:crit]
      critical "Search returned #{result_count} results which is at or below defined critical threshold of #{config[:crit]}"
    elsif result_count <= config[:warn]
      warning "Search returned #{result_count} results which is at or below the defined warning threshold of #{config[:warn]}"
    else
      ok "Search returned #{result_count} results"
    end
  end

  def compare_gt(result_count)

    if result_count >= config[:crit]
      critical "Search returned #{result_count} results which is at or above defined critical ceiling of #{config[:crit]}"
    elsif result_count >= config[:warn]
      warning "Search returned #{result_count} results which is at or above the defined warning ceiling of #{config[:warn]}"
    else
      ok "Search returned #{result_count} results"
    end
  end
end
