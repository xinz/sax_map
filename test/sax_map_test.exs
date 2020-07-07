defmodule SAXMapTest do
  use ExUnit.Case

  test "empty xml" do
    xml = """
      <root></root>
    """

    {:ok, map} = SAXMap.from_string(xml)
    assert map == %{"root" => %{}}
  end

  test "simple xml" do
    xml = """
      <xml>Test</xml>
    """

    {:ok, map} = SAXMap.from_string(xml)
    assert map == %{"xml" => "Test"}
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

  test "duplicate key" do
    xml = """
    <Request>
      <Header>Hi</Header>
      <a>1</a>
      <Body><![CDATA[test content!]]></Body>
      <a>
        <test>
          <test1>1</test1>
          <test1>2</test1>
        </test>
        <test>2</test>
      </a>
      <b>100</b>
    </Request>
    """

    {:ok, map} = SAXMap.from_string(xml)

    assert map == %{
      "Request" => %{
        "Body" => "test content!",
        "Header" => "Hi",
        "a" => ["1", %{"test" => [%{"test1" => ["1", "2"]}, "2"]}],
        "b" => "100"
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

  test "process parent's attributes as the peer child nodes" do
    xml = """
      <root>
        <a>
          <b attr="1">b2</b>
          <c>1</c>
          <d>test</d>
          <items>
            <item attr="a">1</item>
            <item attr="b">2</item>
            <item attr="c">3</item>
          </items>
        </a>
        <b>test</b>
        <name flag="false">testname</name>
      </root>
    """
    {:ok, map} = SAXMap.from_string(xml, ignore_attribute: false)
    assert map == %{
      "root" => %{
        "a" => %{
          "attr" => "1",
          "b" => "b2",
          "c" => "1",
          "d" => "test",
          "items" => %{"attr" => ["a", "b", "c"], "item" => ["1", "2", "3"]}
        },
        "b" => "test",
        "flag" => "false",
        "name" => "testname"
      }
    }

    xml = """
      <data attr1="1" attr2="false" item3="in_attr">
        <item1>item_value</item1>
        <item2>true</item2>
        <item3>in_child</item3>
        <groups group_name="test">
          <group attr="1">gc1</group>
          <group attr="2">gc2</group>
          <group attr="3">gc3</group>
          <group attr="4">gc4</group>
        </groups>
      </data>
    """

    {:ok, map} = SAXMap.from_string(xml, ignore_attribute: false)

    assert map == %{
      "data" => %{
        "attr1" => "1",
        "attr2" => "false",
        "groups" => %{
          "attr" => ["1", "2", "3", "4"],
          "group" => ["gc1", "gc2", "gc3", "gc4"],
          "group_name" => "test"
        },
        "item1" => "item_value",
        "item2" => "true",
        "item3" => "in_child"
      }
    }

    xml = """
      <xml attr="1">Test</xml>
    """
    {:ok, map} = SAXMap.from_string(xml, ignore_attribute: false)

    assert map == %{"xml" => "Test", "attr" => "1"}
  end

  test "process parent's attributes as the peer child nodes, and naming attributes with input prefix" do
    xml = """
      <data attr1="1" attr2="false" item3="in_attr">
        <item1>item_value</item1>
        <item2>true</item2>
        <item3>in_child</item3>
        <groups group_name="test">
          <group attr="1">gc1</group>
          <group attr="2">gc2</group>
          <group attr="3">gc3</group>
          <group attr="4">gc4</group>
        </groups>
      </data>
    """

    {:ok, map} = SAXMap.from_string(xml, ignore_attribute: {false, "@"})

    assert map == %{
      "data" => %{
        "@attr1" => "1",
        "@attr2" => "false",
        "@item3" => "in_attr",
        "groups" => %{
          "@attr" => ["1", "2", "3", "4"],
          "@group_name" => "test",
          "group" => ["gc1", "gc2", "gc3", "gc4"]
        },
        "item1" => "item_value",
        "item2" => "true",
        "item3" => "in_child"
      }
    }

    {:ok, map} = SAXMap.from_string(xml, ignore_attribute: {false, ""})

    assert map == %{
      "data" => %{
        "attr1" => "1",
        "attr2" => "false",
        "groups" => %{
          "attr" => ["1", "2", "3", "4"],
          "group" => ["gc1", "gc2", "gc3", "gc4"],
          "group_name" => "test"
        },
        "item1" => "item_value",
        "item2" => "true",
        "item3" => "in_child"
      }
    }

    xml = """
      <xml attr="1">Test</xml>
    """
    {:ok, map} = SAXMap.from_string(xml, ignore_attribute: {false, "-"})

    assert map == %{"xml" => "Test", "-attr" => "1"}
  end

end
