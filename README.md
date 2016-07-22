## Sensu-Plugins-Splunk

## Functionality

Metrics and checks that execute against saved Splunk searches and act on the results.

## Files
 * `check-splunk-result-count.rb`
 * `metric-splunk-result-count.rb`

## Usage

**`check-splunk-result-count`**
This check hits Splunk and counts the results of a saved search and alerts based on the comparison method used. The
example here will critical if returned results is >= 10
```
check-splunk-result-count.rb -u USERNAME -p PASSWORD -h splunk.example.com -j "Check Log Health" -m gt -c 10

Usage: check-splunk-result-count.rb (options)
    -m COMPMETHOD                    Comparison method to use for warning/crit, either lt (less than) or gt (greater than)
    -c COUNT                         Critical result number (<= or >= depending on comparison method) (required)
    -h HOST                          Splunk Hostname (required)
    -j JOB                           Splunk Saved Search to execute (enclose in quotes if needed) (required)
    -p PASSWORD                      Splunk Password (required)
    -P PORT                          Splunk API Port (usually 8089)
    -t TIMEOUT                       Time to wait for Search query to finish in seconds
    -u USERNAME                      Splunk Username (required)
    -w COUNT                         Warning result number (<= or >= depending on comparison method) (required)
        --help                       Show this message
```

**`metric-splunk-result-count`**
This metric hits Splunk and counts the results of a saved search and returns that value as a Graphite metric
```
Usage: metric-splunk-result-count.rb (options)
    -h HOST                          Splunk Hostname (required)
    -j JOB                           Splunk Saved Search to execute (enclose in quotes if needed) (required)
    -p PASSWORD                      Splunk Password (required)
    -P PORT                          Splunk API Port (usually 8089)
    -s, --scheme SCHEME              Metric naming scheme, text to prepend to metric
    -u USERNAME                      Splunk Username (required)
        --help                       Show this message
```

## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

## Configuration

Ensure the required gems are installed: `splunk-sdk-ruby`

## Notes
