defmodule LoomAwormapTest do
  use ExUnit.Case, async: false
  use Loom

  doctest Loom.AWORMap
  # The Protocol implementation
  doctest Loom.CRDT.Loom.AWORMap

  test "Basic put" do
    ctr = GCounter.new()
    map = KVSet.new() |> KVSet.put(:a, 1, ctr)
    assert 0 == KVSet.get_value(map, 1, GCounter)
    assert 0 == KVSet.get_value(map, 3, GCounter)
    assert true == KVSet.has_key?(map, 1, GCounter)
    assert false == KVSet.has_key?(map, 2, GCounter)
    assert %{{1, Loom.GCounter} => 0} == map |> KVSet.value()
  end

  test "Basic put and delete" do
    ctr = GCounter.new()
    map = KVSet.new() |> KVSet.put(:a, 1, ctr)
    assert 0 == KVSet.get_value(map, 1, ctr)
    map2 = KVSet.delete(map, 1, ctr)
    assert true == KVSet.has_key?(map, 1, GCounter)
    assert false == KVSet.has_key?(map, 2, GCounter)
    assert false == KVSet.has_key?(map2, 1, GCounter)
  end

  test "Keys and values" do
    ctr = GCounter.new() |> GCounter.inc(:a, 5)
    ctr1 = ctr |> GCounter.inc(:b, 10)

    map =
      KVSet.new()
      |> KVSet.put(:a, 1, ctr)
      |> KVSet.put(:a, 1, ctr)
      |> KVSet.put(:b, 1, ctr1)
      |> KVSet.put(:a, 3, ctr)

    assert ctr1 != ctr
    assert [{1, GCounter}, {3, GCounter}] == KVSet.keys(map) |> Enum.sort()
  end

  test "Dict merge" do
    ctrA = GCounter.new() |> GCounter.inc(:a, 10)
    ctrB = GCounter.new() |> GCounter.inc(:b, 10)
    ctrC = GCounter.join(ctrA, ctrB)
    setA = KVSet.new() |> KVSet.put(:a, "counter", ctrA) |> KVSet.put(:a, "lft", ctrA)
    deltaA = KVSet.delta(setA)
    setB = KVSet.new() |> KVSet.put(:b, "counter", ctrB) |> KVSet.put(:b, "rgt", ctrB)
    deltaB = KVSet.delta(setB)

    expected = %{
      {"counter", GCounter} => Loom.CRDT.value(ctrC),
      {"lft", GCounter} => 10,
      {"rgt", GCounter} => 10
    }

    assert expected == KVSet.join(setA, setB) |> KVSet.value()
    assert expected == KVSet.join(setA, deltaB) |> KVSet.value()
    assert expected == KVSet.join(deltaA, setB) |> KVSet.value()
  end
end
