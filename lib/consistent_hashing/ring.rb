require 'digest/md5'

module ConsistentHashing
  class Ring
    attr_reader :ring

    # Public: returns a new ring object
    def initialize(nodes = [], replicas = 3)
      @replicas = replicas
      @sorted_keys = []
      @ring = Hash.new

      nodes.each { |node| add(node) }
    end

    # Public: returns the (virtual) points in the hash ring
    #
    # Returns: a Fixnum
    def length
      @ring.length
    end

    # Public: adds a new node into the hash ring
    #
    def add(node)
      @replicas.times do |i|
        # generate the key of this (virtual) point in the hash
        key = hash_key(node, i)

        @ring[key] = node
        @sorted_keys << key
      end

      @sorted_keys.sort!

      self
    end
    alias :<< :add

    # Public: removes a node from the hash ring
    #
    def delete(node)
      @replicas.times do |i|
        key = hash_key(node, i)

        @ring.delete key
        @sorted_keys.delete key
      end

      self
    end

    # Public: gets the node for an arbitrary key
    #
    #
    def node_for(key)
      return [nil, 0] if @ring.empty?

      key = hash_key(key)

      @sorted_keys.each do |i|
        return [@ring[i], i] if key <= i
      end

      [@ring[@sorted_keys[0]], 0]
    end

    protected

    # Internal: hashes the key
    #
    # Returns: a String
    def hash_key(key, index = nil)
      key = "#{key}:#{index}" if index
      Digest::MD5.hexdigest(key.to_s)[0..16].hex
    end
  end
end