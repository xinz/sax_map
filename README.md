# SAXMap

[![hex.pm version](https://img.shields.io/hexpm/v/sax_map.svg?v=1)](https://hex.pm/packages/sax_map)

Converts an XML String or an XML file stream to a Map.

Benefit from [Saxy](https://hex.pm/packages/saxy)'s SAX mode, this library has a good conversion efficiency.

## Installation

```elixir
def deps do
  [
    {:sax_map, "~> 1.4"}
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
  <thread version="1">
    <title color="red" font="16">Hello</title>
    <items size="3">
      <item font="12">item1</item>
      <item font="12">item2</item>
      <item font="12">item3</item>
    </items>
  </thread>
"""

SAXMap.from_string(xml, ignore_attribute: false)

{:ok,
  %{
    "thread" => %{
      "content" => %{
        "items" => %{
          "content" => %{
            "item" => [
              %{"content" => "item1", "font" => "12"},
              %{"content" => "item2", "font" => "12"},
              %{"content" => "item3", "font" => "12"}
            ]
          },
          "size" => "3"
        },
        "title" => %{"color" => "red", "content" => "Hello", "font" => "16"}
      },
      "version" => "1"
    }
  }}

SAXMap.from_string(xml, ignore_attribute: {false, "@"})
{:ok,
  %{
    "thread" => %{
      "@version" => "1",
      "content" => %{
        "items" => %{
          "@size" => "3",
          "content" => %{
            "item" => [
              %{"@font" => "12", "content" => "item1"},
              %{"@font" => "12", "content" => "item2"},
              %{"@font" => "12", "content" => "item3"}
            ]
          }
        },
        "title" => %{"@color" => "red", "@font" => "16", "content" => "Hello"}
      }
    }
  }}
```

**Please note**: The `ignore_attribute: false` equals `ignore_attribute: {false, ""}`, in this case, the child elements will be automatically naming with `"content"` as the key of the key-value pair to distinct this key-value pair is from XML text content or attribute. Currently, the `"content"` naming is a reserved keyword, please be careful to distinguish it from the XML node name when transfer an XML to a Map be with XML attributes.

## Benchmark

Only for your reference, all credit goes to [Saxy](https://hex.pm/packages/saxy), the details of benchmark can be found in the `bench` directory of the repository.

Run:

```bash
mix run xml_to_map.exs
```

Output:

```bash
Operating System: macOS
CPU Information: Apple M2 Pro
Number of Available Cores: 10
Available memory: 16 GB
Elixir 1.19.5
Erlang 28.2
JIT enabled: true

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 10 s
memory time: 2 s
reduction time: 0 ns
parallel: 1
inputs: none specified
Estimated total run time: 56 s

Benchmarking SAXMap.from_string ignore attribute ...
Benchmarking SAXMap.from_string with attribute ...
Benchmarking XmlToMap.naive_map ignore attribute ...
Benchmarking XmlToMap.nested_map with attribute ...
Calculating statistics...
Formatting results...

Name                                          ips        average  deviation         median         99th %
SAXMap.from_string ignore attribute      200.24 K        4.99 μs   ±224.70%        4.75 μs        8.79 μs
SAXMap.from_string with attribute        189.12 K        5.29 μs   ±219.38%        5.04 μs       10.58 μs
XmlToMap.nested_map with attribute       183.05 K        5.46 μs   ±151.45%        5.25 μs       13.79 μs
XmlToMap.naive_map ignore attribute      144.77 K        6.91 μs   ±137.97%        6.58 μs       16.17 μs

Comparison:
SAXMap.from_string ignore attribute      200.24 K
SAXMap.from_string with attribute        189.12 K - 1.06x slower +0.29 μs
XmlToMap.nested_map with attribute       183.05 K - 1.09x slower +0.47 μs
XmlToMap.naive_map ignore attribute      144.77 K - 1.38x slower +1.91 μs

Memory usage statistics:

Name                                   Memory usage
SAXMap.from_string ignore attribute        14.98 KB
SAXMap.from_string with attribute          16.17 KB - 1.08x memory usage +1.20 KB
XmlToMap.nested_map with attribute         31.62 KB - 2.11x memory usage +16.64 KB
XmlToMap.naive_map ignore attribute        34.26 KB - 2.29x memory usage +19.28 KB

**All measurements for memory usage were the same**
Operating System: macOS
CPU Information: Apple M2 Pro
Number of Available Cores: 10
Available memory: 16 GB
Elixir 1.19.5
Erlang 28.2
JIT enabled: true

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 10 s
memory time: 2 s
reduction time: 0 ns
parallel: 1
inputs: none specified
Estimated total run time: 28 s

Benchmarking SAXMap.from_string mixed content ...
Benchmarking XmlToMap.nested_map mixed content ...
Calculating statistics...
Formatting results...

Name                                        ips        average  deviation         median         99th %
SAXMap.from_string mixed content         556.11        1.80 ms     ±7.62%        1.77 ms        2.08 ms
XmlToMap.nested_map mixed content        455.80        2.19 ms     ±7.48%        2.18 ms        2.70 ms

Comparison:
SAXMap.from_string mixed content         556.11
XmlToMap.nested_map mixed content        455.80 - 1.22x slower +0.40 ms

Memory usage statistics:

Name                                 Memory usage
SAXMap.from_string mixed content          6.04 MB
XmlToMap.nested_map mixed content         9.47 MB - 1.57x memory usage +3.43 MB

**All measurements for memory usage were the same**
```
