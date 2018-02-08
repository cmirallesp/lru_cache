defmodule CacheTest do
  use ExUnit.Case
  doctest Cache
  @capacity 4

  setup do
    cache = Cache.create(@capacity)
    [c: cache]
  end

  test "seq is incremented +1 every time an element is accessed (set/get)" , ctx do
    cache = ctx[:c]
    assert 0  = cache.seq

    # after setting non existent value => +1 
    cache = Cache.set(cache, :a,1)
    assert 1 = cache.seq

     # after setting existent a value => +1 
    cache = Cache.set(cache, :a,1)
    assert 2 = cache.seq   

    # after getting an existent value => +1
    {_, cache} = Cache.get(cache, :a)
    assert 3 = cache.seq

    # after getting an non existent value => +0
    {nil, cache} = Cache.get(cache,:b)
    assert 3 = cache.seq
  end

  test "get(entry)" ,ctx do
    cache = ctx[:c]
    cache = Cache.set(cache, :a,"a")
    {entry, _} = Cache.get(cache, :a)
    # set, get = 2 accesses
    assert %{seq: 2, val: "a"} = entry
  end

  test "get(entry) => no changes when entry is not in the cache", ctx do
    cache = ctx[:c] 
    assert {nil, ^cache} = Cache.get(cache,:a)
  end

  test "add(cache) full cache=> removes the lru_entry", ctx do
    cache = ctx[:c]
    cache = Cache.set(cache, :a, "a")
    cache = Cache.set(cache, :b, "b")
    cache = Cache.set(cache, :c, "c")
    cache = Cache.set(cache, :d, "d")
    assert %{cap: 0} = cache
    # cache is full, lru (:a) will be evicted
    cache = Cache.set(cache, :e, "e")
    # evicted :a, in cache :b,:c,:d,:e 
    assert {nil, %{cap: 0}} = Cache.get(cache, :a)
    cache = assert_in_cache(cache,[b: "b", c: "c", d: "d", e: "e"])
    # update b value
    cache = Cache.set(cache,:b,"bb")
    # no entries evicted
    cache = assert_in_cache(cache,[b: "bb", c: "c", d: "d", e: "e"])
    # :a is back => :b is evicted
    cache = Cache.set(cache,:a,"a")
    assert {nil, %{cap: 0}} = Cache.get(cache, :b)
    assert_in_cache(cache,[a: "a", c: "c", d: "d", e: "e"])
  end
  
  def assert_in_cache(cache,lst) do
    result = Enum.reduce(lst, cache, fn ({k,v}, acc) -> 
      assert {%{val: ^v}, acc} = Cache.get(acc,k)
      acc
    end)
    # IO.puts inspect(result)
    result
  end


end
