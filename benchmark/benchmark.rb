$:.unshift(File.join(File.dirname(__FILE__), %w{.. lib}))

require 'benchmark'
require 'ipaddr'
require 'consistent_hashing'

def ip(offset)
  address = IPAddr.new('10.0.0.0').to_i + offset
  [24, 16, 8, 0].collect {|b| (address >> b) & 255}.join('.')
end

def rand_emails()
  fnames = ["Adam", "Benjamin", "Caleb", "Daniel", "Frank", "Gideon"]
  lnames = ["Smith", "Jones", "Washington", "Jefferson", "Gardener", 
"Cooper"]
  domains = ["asdfads", "oioiau", "idius-iosud", "qwieu9", "aodfou", "oiinnus-d"]
  tlds = ["com", "edu", "org"]
  fnames[rand(6)] + lnames[rand(6)] + "@" + domains[rand(6)] + "." + tlds[rand(3)]
end

def benchmark_insertions_lookups()
  # The initial ring implementation using a combination of hash and sorted list
  # had the following results when benchmarked:
  #                  user     system      total        real
  # Insertions:  1.260000   0.000000   1.260000 (  1.259346)
  # Look ups:   20.080000   0.020000  20.100000 ( 20.111773)
  #
  # The ring implementation using an AVLTree has the following results
  # when benchmarked on the same system:
  #                  user     system      total        real
  # Insertions:  0.060000   0.000000   0.060000 (  0.062302)
  # Look ups:    1.020000   0.000000   1.020000 (  1.028172)
  #
  # The performance improvement is ~20x for both insertions and lookups.

  emails = []
  100_000.times {
    emails.push(rand_emails)
  }

  bucket_counts = {}

  Benchmark.bm(10) do |x|
    ring = ConsistentHashing::Ring.new(nil, 163)
    x.report("Insertions:") {for i in 1..70; ring << ip(i); end}
    x.report("Look ups:  ") do
      emails.each {|email|
        node = ring.node_for(email)
        bucket_count = bucket_counts[node]
        bucket_counts[node] = bucket_count.nil? == true ? 1 : bucket_count + 1 
      }
    end
  end

  puts "\nRing Distribution:"
  puts "Node \t\t\t Values"
  keys = bucket_counts.keys.sort
  keys.each {|k|
    puts "#{k} \t\t #{bucket_counts[k]}"
  }
end

benchmark_insertions_lookups
