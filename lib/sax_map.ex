defmodule SAXMap do
  @moduledoc """
  XML to Map conversion.

  SAXMap uses a SAX parser (built on top of [Saxy](https://hex.pm/packages/saxy)) to transfer an XML string into a `Map` containing a collection of pairs where the key is the node name and the value is its content.
  """

  @doc ~S'''
  Use `Saxy.parse_string/4` with a custom SAX parse handler to extract a `Map` containing a collection of pairs where the key is the node name
  and the value is its content.

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
    key-value pair into the peer child elements, and also there can set this option as `{false, "@"}` or `{false, "-"}`,
    any proper naming prefix you perfer should be fine to process.

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

  Please notice that the comments of XML are ignored.
  '''
  @spec from_string(xml :: String.t()) ::
          {:ok, map :: map()} | {:error, exception :: Saxy.ParseError.t()}
  def from_string(xml, _opts \\ []) do
    #ignore_attribute = Keyword.get(opts, :ignore_attribute, true)
    #parse_from_string(xml, ignore_attribute)
    Saxy.parse_string(xml, SAXMap.Handler, [])
  end

  #defp parse_from_string(xml, true) do
  #  Saxy.parse_string(xml, SAXMap.Handler, [])
  #end

  def from_stream(stream, opts \\ []) do
    Saxy.parse_stream(stream, SAXMap.Handler, [])
  end
end
