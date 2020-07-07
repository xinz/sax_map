# SAXMap

[![hex.pm version](https://img.shields.io/hexpm/v/sax_map.svg)](https://hex.pm/packages/sax_map)

Converts an XML String to a Map.

Benefit from [Saxy](https://hex.pm/packages/saxy)'s SAX mode, this library has a good conversion efficiency.

## Installation

```elixir
def deps do
  [
    {:sax_map, "~> 0.2"}
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

By default `SAXMap.from_string` will ignore all attributes of elements in the result, if you want to merge the attributes as the child elements, please use `ignore_attribute` option to achieve this:

```
xml = """
  <data attr1="1" attr2="false" item3="override">
    <item1>item_value1</item1>
    <item2>item_value2</item2>
    <item3>item_value3</item3>
    <groups>
      <group attr="1">a</group>
      <group attr="2">b</group>
    </groups>
  </data>
"""

SAXMap.from_string(xml, ignore_attribute: false)

{:ok,
  %{
    "data" => %{
      "attr1" => "1",
      "attr2" => "false",
      "groups" => %{"attr" => ["1", "2"], "group" => ["a", "b"]},
      "item1" => "item_value1",
      "item2" => "item_value2",
      "item3" => "item_value3"
    }
  }}

SAXMap.from_string(xml, ignore_attribute: {false, "@"})

{:ok,
  %{
    "data" => %{
      "@attr1" => "1",
      "@attr2" => "false",
      "@item3" => "override",
      "groups" => %{"@attr" => ["1", "2"], "group" => ["a", "b"]},
      "item1" => "item_value1",
      "item2" => "item_value2",
      "item3" => "item_value3"
    }
  }}
```

**Notice**: The `ignore_attribute: false` equals `ignore_attribute: {false, ""}`, if the naming of attribute has the same name with the child element in a peer, there will use child element's value to override this naming key.

## Benchmark

Only for your reference, all of credit belong to [Saxy](https://hex.pm/packages/saxy), the details of benchmark can be found in the `bench` directory of the repository.

```bash
Operating System: macOS
CPU Information: Intel(R) Core(TM) i9-9880H CPU @ 2.30GHz
Number of Available Cores: 16
Available memory: 32 GB
Elixir 1.10.3
Erlang 22.3.4.2

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
SAXMap.from_string       25.70 K       38.91 μs    ±28.84%          36 μs          91 μs
XmlToMap.naive_map       14.39 K       69.48 μs    ±21.32%          66 μs         143 μs

Comparison:
SAXMap.from_string       25.70 K
XmlToMap.naive_map       14.39 K - 1.79x slower +30.57 μs

Memory usage statistics:

Name                  Memory usage
SAXMap.from_string        18.40 KB
XmlToMap.naive_map        39.96 KB - 2.17x memory usage +21.56 KB

**All measurements for memory usage were the same**
```
