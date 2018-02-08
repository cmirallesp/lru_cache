# Cache

This project implements in elixir a Cache with capacity N that replaces the least recently used element when such capacity is reached.

## API
Has three public operations: 

- create: creates the cache 
- get: obtains an element from the cache 
- put: puts an element into the cache 

More info in module [documentation](doc/Cache.html#functions)

## Internal strucutre
The internal structure used for the implementation is a map with the following fields:

- data: a map \<key, entry\> to keep each element identified by key added to the cache. 
- seq: a counter that is incremented each time an element is accesed (set or get)
- cap: current capacity (goes from init value to 0)

An **entry** is a hash as:

- val: contains the stored content 
- seq: last sequence number that was accessed (set or get)

When the cache is filled up the entry with lowest seq is evicted.

## Instalation and testing

Execute the following instructions in the root folder:

```bash
> mix deps.get
> mix compile
```

To run the tests 

```bash 
> mix test
```




