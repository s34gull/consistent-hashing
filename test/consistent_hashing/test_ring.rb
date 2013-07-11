require File.join(File.dirname(__FILE__), %w{ .. test_consistent_hashing})

class TestRing < ConsistentHashing::TestCase
  def setup

    @examples = {
      "192.168.1.100:6379" => "me@me.com",
      "192.168.1.101:6379" => "you@you.edu",
      "192.168.1.101:6389" => "him@her.org",
    }

    @ring = ConsistentHashing::Ring.new()
    @ring.add("192.168.1.100:6379")
    @ring.add("192.168.1.101:6379")
    @ring.add("192.168.1.101:6389")
  end

  def test_init
    ring = ConsistentHashing::Ring.new
    assert_equal 0, ring.length
  end

  def test_length
    ring = ConsistentHashing::Ring.new([], 3)
    assert_equal 0, ring.length

    ring << "192.168.1.100:6379" << "192.168.1.101:6379"
    assert_equal 6, ring.length
  end

  # It is easily the case that two values might map back to the same
  # virtualpoint if that is how their hashes are distributed. What ranges
  # the keys claim is independent of the computed value of the objects 
  # they might hold.
  def test_get_node
    assert @examples.keys.include?(@ring.point_for(@examples["192.168.1.100:6379"]).node)
    assert @examples.keys.include?(@ring.point_for(@examples["192.168.1.101:6379"]).node)
    assert @examples.keys.include?(@ring.point_for(@examples["192.168.1.101:6389"]).node)
  end

  # should fall back to the first node, if key > last node
  def test_get_node_fallback_to_first
    ring = ConsistentHashing::Ring.new ["192.168.1.100:6379"], 1

    point = ring.point_for(@examples["not_found"])

    assert_equal "192.168.1.100:6379", point.node
    assert_not_equal 0, point.index
  end

  # if I remove node C, all keys previously mapped to C should be moved clockwise to
  # the next node. That's a virtual point of B here
  def test_remove_node
    assert @examples.keys.include?(@ring.point_for(@examples["192.168.1.101:6389"]).node)
    @ring.delete("192.168.1.101:6389")
    assert ["192.168.1.100:6379", "192.168.1.101:6379"].include?(
      @ring.point_for(@examples["192.168.1.101:6389"]).node)
  end

  def test_point_for
    assert @examples.keys.include?(@ring.node_for(@examples["192.168.1.101:6389"]))
  end

  def test_nodes
    nodes = @ring.nodes

    assert_equal 3, nodes.length
    assert_not_equal nil, nodes.index("192.168.1.100:6379")
    assert_not_equal nil, nodes.index("192.168.1.101:6379")
    assert_not_equal nil, nodes.index("192.168.1.101:6389")
  end

  def test_points
    ring = ConsistentHashing::Ring.new @examples.keys, 3

    points = ring.points
    assert_equal 9, points.length
  end
end
