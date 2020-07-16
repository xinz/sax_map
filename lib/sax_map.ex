defmodule SAXMap do
  @moduledoc """
  XML to Map conversion.

  SAXMap uses a SAX parser (built on top of [Saxy](https://hex.pm/packages/saxy)) to transfer an XML string or file stream into a `Map` containing a collection
  of pairs where the key is the element name and the value is its content, and it is a optional to process element attribute into the result.
  """

  @doc ~S'''
  Use `Saxy.parse_string/4` with a custom SAX parse handler to extract a `Map` containing a collection of pairs where the key is the element name
  and the value is its content, there can optionally append the key-value pair from the attribute of element.

  ## Example

  Here is an example:

      iex> xml = """
      ...> <?xml version="1.0" encoding="UTF-8"?>
      ...> <thread>
      ...>   <title>Hello</title>
      ...>   <items>
      ...>     <item>item1</item>
      ...>     <item>item2</item>
      ...>   </items>
      ...> </thread>
      ...> """
      iex> SAXMap.from_string(xml)
      {:ok,
       %{
         "thread" => %{"items" => %{"item" => ["item1", "item2"]}, "title" => "Hello"}
       }}

  ## Options

  * `:ignore_attribute`, whether to ignore the attributes of elements in the final map, by default is `true` so
    there will not see any attributes in the result; when set this option as `false`, it equals `{false, ""}`,
    in this case, there with append the attributes of all elements by the processing order, and put the attributes
    key-value pair into the peer child elements, and automatically naming child elements with "content",
    we can also set this option as `{false, "@"}` or `{false, "-"}`, any proper naming prefix you perfer should be fine to process.

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

    # set ignore_attribute: false
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

    # set ignore_attribute: {false, "@"}
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

  Please notice that the comments of XML are ignored.
  '''
  @spec from_string(xml :: String.t()) ::
          {:ok, map :: map()} | {:error, exception :: Saxy.ParseError.t()}
  def from_string(xml, opts \\ []) do
    ignore_attribute = Keyword.get(opts, :ignore_attribute, true)
    parse_from_string(xml, ignore_attribute)
  end

  defp parse_from_string(xml, true) do
    Saxy.parse_string(xml, SAXMap.Handler, [ignore_attribute: true])
  end
  defp parse_from_string(xml, false) do
    Saxy.parse_string(xml, SAXMap.Handler, [ignore_attribute: false])
  end
  defp parse_from_string(xml, {false, attribute_prefix}) do
    Saxy.parse_string(xml, SAXMap.Handler, [ignore_attribute: {false, attribute_prefix}])
  end

  @doc ~S'''
  Use `Saxy.parse_stream/4` with a custom SAX parse handler to extract a `Map` containing a collection of pairs where the key is the element name
  and the value is its content, there can optionally append the key-value pair from the attribute of element.

  ## Options

  Please see `from_string/2`
  '''
  def from_stream(stream, opts \\ []) do
    ignore_attribute = Keyword.get(opts, :ignore_attribute, true)
    parse_from_stream(stream, ignore_attribute)
  end

  defp parse_from_stream(stream, true) do
    Saxy.parse_stream(stream, SAXMap.Handler, [ignore_attribute: true])
  end
  defp parse_from_stream(stream, false) do
    Saxy.parse_stream(stream, SAXMap.Handler, [ignore_attribute: false])
  end
  defp parse_from_stream(stream, {false, attribute_prefix}) do
    Saxy.parse_stream(stream, SAXMap.Handler, [ignore_attribute: {false, attribute_prefix}])
  end
end
