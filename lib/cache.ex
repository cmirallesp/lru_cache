defmodule Cache do

  @moduledoc """
  This module implements a cache that evicts the least recent used LRU element
  when its capacity is 0
  """

  @opaque data_entry :: map 

  @opaque tcache :: map


### cache API: new, put, get

  @doc """
  Creates a cache to allocate __capacity__ values

  ## Parameters

    - capacity: Max number of elements in the cache

  ## Examples
      iex> Cache.create(3)
      %{data: %{}, seq: 0, cap: 3}
  """
  @spec create(integer) :: tcache
  def create(capacity) do
    # {:ok, pid} =Agent.start_link fn -> %{ @default_state | cap: capacity } end
    %{data: %{}, seq: 0, cap: capacity}
  end

  @doc """
  Given an element and a cache:
    i) Inserts the element  if is not already in the cache, or 
    ii) Updates its content if already exists.
  If the cache has no free slots, the least recently used element is evicted before the insertion.
  
  ## Parameters

    - self: a cache in which the element is being added
    - key: identifier of the value
    - value: content being cached

  ## Examples  
      iex> Cache.create(10) |> Cache.put(:a,"a")
      %{data: %{a: %{val: "a", seq: 1}}, cap: 9, seq: 1}
  """
  @spec put(tcache,any, any) :: tcache
  def put(self,key,content) do
    cache = next_seq(self)
    entry = %{val: content, seq: cache.seq}
    {new_data, dec} =
      cond do 
        in_cache?(cache, key)    -> {Map.put(cache.data,key,entry), 1}
        has_space?(cache)        -> {Map.put(cache.data,key,entry), 1}
        true -> # not in_cache and !has_space? => delete lru
          lru_k = lru_entry(cache) 
          { Map.delete(cache.data, lru_k)
            |> Map.put(key,entry), 
            0
          }
      end
    %{cache | data: new_data, cap: max(0, cache.cap - dec) }
  end 

  @doc """
  Gets the cache entry identified by __key__ or nil if does not exist

  ## Parameters

    - self: the cache
    - key: the key of the value

  ## Examples
      iex> Cache.create(10) |> Cache.get(:a)
      {nil,  %{cap: 10, data: %{}, seq: 0}}

      iex> Cache.create(10) |> Cache.put(:a,"a") |> Cache.get(:a)
      { %{val: "a", seq: 2}, %{data: %{a: %{val: "a", seq: 2}}, seq: 2, cap: 9} }
    
  """
  @spec get(tcache, any) :: {data_entry , tcache} 
  def get(self,key) do
    entry     = Map.get(self.data,key)
      if entry == nil do
      # no changes if missing key
        {entry, self}
      else 
      # update global seq counter of val to seq+1
        state    = next_seq(self)
      # update seq counter of the entry
        entry = %{entry | seq: state.seq}
        data  = %{state.data | key => entry}
        {entry, %{state | data: data}}
      end
  end

##### PRIVATE FUNCTIONS
  @spec lru_entry(tcache) :: data_entry
  defp lru_entry(cache) do
    # returns the least recently used element from the cache, ie. the
    # element with lowest seq.
    {key, _} = Enum.min_by(cache.data, fn ({_,v}) -> v.seq end)
    key
    # Alternative sorting: 
    #  [key | _ ] =
    #    Enum.sort(cache.data, fn ({_,v1},{_,v2}) -> v1.seq < v2.seq  end) 
    #    |> Enum.take(1)
    #    |> Keyword.keys
    # with sorting O(log(n)*n) (providing a decent sort alg.)
    # with min O(n)
  end

  @spec in_cache?(tcache, any) :: boolean
  defp in_cache?(cache,k), do: Map.has_key?(cache.data, k)
  
  @spec has_space?(tcache) :: boolean
  defp has_space?(cache), do: cache.cap > 0
  # defp full?(cache), do: Map.keys(cache.data) |> Enum.count > cache.cap - 1   
  
  @spec next_seq(tcache) :: map
  defp next_seq(self) do
    %{self | seq: self.seq + 1}
  end
end
