# SAXMap

[![hex.pm version](https://img.shields.io/hexpm/v/sax_map.svg?v=1)](https://hex.pm/packages/sax_map)

Converts an XML String or an XML file stream to a Map.

Benefit from [Saxy](https://hex.pm/packages/saxy)'s SAX mode, this library has a good conversion efficiency.

## Installation

```elixir
def deps do
  [
    {:sax_map, "~> 1.0"}
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

**Notice**: The `ignore_attribute: false` equals `ignore_attribute: {false, ""}`, in this case, the child elements will be automatically naming with "content" as the key of the key-value pair to distinct this key-value pair is from content or attribute.

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
Estimated total run time: 42 s

Benchmarking SAXMap.from_string ignore attribute...
Benchmarking SAXMap.from_string with attribute...
Benchmarking XmlToMap.naive_map...

Name                                          ips        average  deviation         median         99th %
SAXMap.from_string ignore attribute       42.42 K       23.57 μs    ±28.32%          23 μs          43 μs
SAXMap.from_string with attribute         38.51 K       25.96 μs    ±27.96%          25 μs          47 μs
XmlToMap.naive_map                        15.25 K       65.58 μs    ±13.78%          63 μs          95 μs

Comparison:
SAXMap.from_string ignore attribute       42.42 K
SAXMap.from_string with attribute         38.51 K - 1.10x slower +2.39 μs
XmlToMap.naive_map                        15.25 K - 2.78x slower +42.00 μs

Memory usage statistics:

Name                                   Memory usage
SAXMap.from_string ignore attribute        12.34 KB
SAXMap.from_string with attribute          14.42 KB - 1.17x memory usage +2.08 KB
XmlToMap.naive_map                         39.96 KB - 3.24x memory usage +27.62 KB

**All measurements for memory usage were the same**
```
