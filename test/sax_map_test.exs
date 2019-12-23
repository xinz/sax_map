defmodule SAXMapTest do
  use ExUnit.Case

  test "empty xml" do
    xml = """
      <root></root>
    """

    {:ok, map} = SAXMap.from_string(xml)
    assert map == %{"root" => %{}}
  end

  test "simple xml with CDATA" do
    xml = """
    <?xml version="1.0" encoding="UTF-8" ?>
    <Request>
      <Header>Hi</Header>
      <Body><![CDATA[test content!]]></Body>
    </Request>
    """

    {:ok, map} = SAXMap.from_string(xml)

    assert map == %{
             "Request" => %{
               "Header" => "Hi",
               "Body" => "test content!"
             }
           }
  end

  test "keep order of peer nodes" do
    xml = """
      <data>
        <attribute>A0</attribute>
        <items>
          <item>1</item>
          <item>2</item>
          <item>3</item>
          <item>4</item>
        </items>
        <attribute>A1</attribute>
        <attribute>C1</attribute>
        <meta1>
          <key>key1</key>
          <key>key2</key>
          <feature>f1</feature>
        </meta1>
        <key>rootkey1</key>
        <meta2>
          <key>
            <item>1</item>
            <item>2</item>
          </key>
          <feature>
            <func>func1</func>
          </feature>
        </meta2>
      </data>
    """

    {:ok, map} = SAXMap.from_string(xml)

    assert map == %{
             "data" => %{
               "attribute" => ["A0", "A1", "C1"],
               "items" => %{"item" => ["1", "2", "3", "4"]},
               "meta1" => %{"key" => ["key1", "key2"], "feature" => "f1"},
               "key" => "rootkey1",
               "meta2" => %{"key" => %{"item" => ["1", "2"]}, "feature" => %{"func" => "func1"}}
             }
           }
  end

  test "invalid xml" do
    xml = """
      <data>
        <item></item2>
      </data>
    """

    {:error, %Saxy.ParseError{reason: reason}} = SAXMap.from_string(xml)
    assert reason == {:wrong_closing_tag, "item", "item2"}
  end
end
