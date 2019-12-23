# SAXMap

[![hex.pm version](https://img.shields.io/hexpm/v/sax_map.svg)](https://hex.pm/packages/sax_map)

Converts an XML String to a Map.

Benefit from [Saxy](https://hex.pm/packages/saxy)'s SAX mode, this library has a good conversion efficiency.

## Installation

```elixir
def deps do
  [
    {:sax_map, "~> 0.1"}
  ]
end
```

## Example

```elixir

iex(1)> xml = """
...(1)> <?xml version="1.0" encoding="UTF-8"?>
...(1)> <thread>
...(1)>   <title>Hello</title>
...(1)>   <items>
...(1)>     <item>item1</item>
...(1)>     <item>item2</item>
...(1)>   </items>
...(1)> </thread>
...(1)> """
iex(2)> SAXMap.from_string(xml)
{:ok,
 %{
   "thread" => %{"items" => %{"item" => ["item1", "item2"]}, "title" => "Hello"}
 }}
```

Please **notice** that both XML attributes and comments are ignored.

## Benchmark

Only for your reference, all of credit belong to [Saxy](https://hex.pm/packages/saxy), the details of benchmark can be found in the `bench` directory of the repository.

```bash
Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-4258U CPU @ 2.40GHz
Number of Available Cores: 4
Available memory: 8 GB
Elixir 1.9.4
Erlang 22.1.8

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 10 s
memory time: 2 s
parallel: 1
inputs: none specified
Estimated total run time: 28 s

Benchmarking SAXMap.from_string...
Benchmarking XmlToMap.naive_map...

Name                         ips        average  deviation         median         99th %
SAXMap.from_string       24.15 K       41.40 μs    ±67.10%          35 μs         131 μs
XmlToMap.naive_map       16.28 K       61.42 μs    ±89.04%          49 μs         224 μs

Comparison:
SAXMap.from_string       24.15 K
XmlToMap.naive_map       16.28 K - 1.48x slower +20.02 μs

Memory usage statistics:

Name                  Memory usage
SAXMap.from_string        14.82 KB
XmlToMap.naive_map        33.20 KB - 2.24x memory usage +18.38 KB

**All measurements for memory usage were the same**
```
