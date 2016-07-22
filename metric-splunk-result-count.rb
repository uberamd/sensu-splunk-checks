#! /usr/bin/env ruby
#
#   metric-splunk-result-count
#
# DESCRIPTION:
#   Run a saved search in Splunk and output metrics of returned results
#
# OUTPUT:
#   plain text metric
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: splunk-sdk-ruby
#
# USAGE:
#   metric-splunk-result-count.rb -u USERNAME -p PASSWORD -h splunk.example.com -j "Check Log Health"
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
require 'sensu-plugin/metric/cli'
require 'socket'

class MetricSplunkResultCount < Sensu::Plugin::Metric::CLI::Graphite
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

  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.splunk_results"

  option :help,
         :long => '--help',
         :description => 'Show this message',
         :on => :tail,
         :boolean => true,
         :show_options => true,
         :exit => 0


  def run

    num_results = splunk_search

    clean_job_name = config[:job].gsub(/[^0-9A-Za-z]/, '')
    output "#{config[:scheme]}.#{clean_job_name}", num_results

    ok
  end

  def splunk_search

    service = Splunk::connect(:host => config[:host], :port => config[:port], :username => config[:username], :password => config[:password])

    # find the Saved Search
    search_target = service.saved_searches.fetch(config[:job])

    # kick off the saved search
    job = search_target.dispatch

    while !job.is_ready?
      sleep 1
    end

    # create a stream (must be a preview) and load up the results
    stream = job.preview
    results = Splunk::ResultsReader.new(stream)

    # count the number of returned results in this silly way because .count isn't working on the Splunk::ResultsReader :-(
    result_count = 0
    results.each do |result| result_count += 1 end

    return result_count
  end
end
