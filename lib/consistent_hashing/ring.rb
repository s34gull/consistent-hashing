require 'set'

require 'murmurhash3'

module ConsistentHashing

  # Public: the hash ring containing all configured nodes
  #
  class Ring

    @@seed = 1500450271

    # Public: returns a new ring object
    # 160 is the default in libmemcached; we chose next larger prime 
    # shows good performance and reasonable distribution of keys with murmur3
    def initialize(nodes=[], replicas=163)
      nodes ||= []
      replicas ||= 163

      @replicas = replicas
      @ring = AVLTree.new
      @seed = @@seed

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

        @ring[key] = VirtualPoint.new(node, key)
      end

      self
    end
    alias :<< :add

    # Public: removes a node from the hash ring
    #
    def delete(node)
      @replicas.times do |i|
        key = hash_key(node, i)

        @ring.delete key
      end

      self
    end

    # Public: gets the point for an arbitrary key
    #
    #
    def point_for(key)
      return nil if @ring.empty?
      key = hash_key(key)
      _, value = @ring.next_gte_pair(key)
      _, value = @ring.minimum_pair unless value
      value
    end

    # Public: gets the node where to store the key
    #
    # Returns: the node Object
    def node_for(key)
      point_for(key).node
    end

    # Public: get all nodes in the ring
    #
    # Returns: an Array of the nodes in the ring
    def nodes
      nodes = points.map { |point| point.node }
      nodes.uniq
    end

    # Public: gets all points in the ring
    #
    # Returns: an Array of the points in the ring
    def points
      @ring.map { |point| point[1] }
    end

    protected

    # Internal: hashes the key
    #    We use Murmurhash3 to obtain better key distribution over small
    #    _n_ (e.g. number of servers to shard between) in less time than MD5.
    #    We get better distribution when indexing if we str_hash the add
    #    index to that Integer value, and int64_hash the results. This
    #    is helpful when initializing a ring where the index is the replica
    #    count. When no index is present (i.e. when we are hashing a value
    #    to find where in the ring it should live), just use the str_hash of 
    #    the key.
    # Returns: a 32 bit Integer
    def hash_key(key, index = nil)
      if index
        MurmurHash3::V32.int64_hash(
          MurmurHash3::V32.str_hash(key.to_s, @seed) + index.to_i
        )
      else
        MurmurHash3::V32.str_hash(key.to_s, @seed)
      end
    end
  end
end
