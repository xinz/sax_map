defmodule SAXMapTest do
  use ExUnit.Case

  @path Path.expand("./fixtures", __DIR__)

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

  test "xml with CDATA starting with enter" do
    xml = """
    <?xml version="1.0" encoding="UTF-8" ?>
    <Request>
      <Header>Hi</Header>
      <Body><![CDATA[
    hello]]></Body>
    </Request>
    """

    {:ok, map} = SAXMap.from_string(xml)

    assert map == %{
             "Request" => %{
               "Header" => "Hi",
               "Body" => "\nhello"
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

  test "from_stream" do
    stream = File.stream!("#{@path}/test.xml")
    {:ok, map} = SAXMap.from_stream(stream)

    assert map == %{
             "data" => %{
               "groups" => %{"group" => ["gc1", "gc2", "gc3", "gc4"]},
               "item1" => "item_value",
               "item2" => "true",
               "item3" => "in_child"
             }
           }
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
            <item attr="d">4</item>
          </items>
        </a>
        <b>test</b>
        <name flag="false">testname</name>
      </root>
    """

    {:ok, map} = SAXMap.from_string(xml)

    assert map == %{
             "root" => %{
               "a" => %{
                 "b" => "b2",
                 "c" => "1",
                 "d" => "test",
                 "items" => %{"item" => ["1", "2", "3", "4"]}
               },
               "b" => "test",
               "name" => "testname"
             }
           }

    {:ok, map} = SAXMap.from_string(xml, ignore_attribute: false)

    assert map == %{
             "root" => %{
               "content" => %{
                 "a" => %{
                   "content" => %{
                     "b" => %{"attr" => "1", "content" => "b2"},
                     "c" => %{"content" => "1"},
                     "d" => %{"content" => "test"},
                     "items" => %{
                       "content" => %{
                         "item" => [
                           %{"attr" => "a", "content" => "1"},
                           %{"attr" => "b", "content" => "2"},
                           %{"attr" => "c", "content" => "3"},
                           %{"attr" => "d", "content" => "4"}
                         ]
                       }
                     }
                   }
                 },
                 "b" => %{"content" => "test"},
                 "name" => %{"content" => "testname", "flag" => "false"}
               }
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
               "item3" => "in_attr",
               "content" => %{
                 "groups" => %{
                   "content" => %{
                     "group" => [
                       %{"attr" => "1", "content" => "gc1"},
                       %{"attr" => "2", "content" => "gc2"},
                       %{"attr" => "3", "content" => "gc3"},
                       %{"attr" => "4", "content" => "gc4"}
                     ]
                   },
                   "group_name" => "test"
                 },
                 "item1" => %{"content" => "item_value"},
                 "item2" => %{"content" => "true"},
                 "item3" => %{"content" => "in_child"}
               }
             }
           }

    xml = """
      <xml attr="1">Test</xml>
    """

    {:ok, map} = SAXMap.from_string(xml, ignore_attribute: false)
    assert map == %{"xml" => %{"content" => "Test", "attr" => "1"}}
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
               "content" => %{
                 "groups" => %{
                   "@group_name" => "test",
                   "content" => %{
                     "group" => [
                       %{"@attr" => "1", "content" => "gc1"},
                       %{"@attr" => "2", "content" => "gc2"},
                       %{"@attr" => "3", "content" => "gc3"},
                       %{"@attr" => "4", "content" => "gc4"}
                     ]
                   }
                 },
                 "item1" => %{"content" => "item_value"},
                 "item2" => %{"content" => "true"},
                 "item3" => %{"content" => "in_child"}
               }
             }
           }

    {:ok, map} = SAXMap.from_string(xml, ignore_attribute: {false, ""})

    assert map == %{
             "data" => %{
               "attr1" => "1",
               "attr2" => "false",
               "item3" => "in_attr",
               "content" => %{
                 "groups" => %{
                   "group_name" => "test",
                   "content" => %{
                     "group" => [
                       %{"attr" => "1", "content" => "gc1"},
                       %{"attr" => "2", "content" => "gc2"},
                       %{"attr" => "3", "content" => "gc3"},
                       %{"attr" => "4", "content" => "gc4"}
                     ]
                   }
                 },
                 "item1" => %{"content" => "item_value"},
                 "item2" => %{"content" => "true"},
                 "item3" => %{"content" => "in_child"}
               }
             }
           }

    xml = """
      <xml attr="1">Test</xml>
    """

    {:ok, map} = SAXMap.from_string(xml, ignore_attribute: {false, "-"})

    assert map == %{"xml" => %{"content" => "Test", "-attr" => "1"}}
  end


  test "ignore xml content with CRLF-terminated" do
    xml = """
      <data><title>test</title>\r\n</data>
    """
    {:ok, map} = SAXMap.from_string(xml)
    assert map == %{"data" => %{"title" => "test"}}

    xml = ~s"<mediawiki xml:lang=\"en\">\r\n  <page>\r\n    <title>Page title</title>\r\n    <revision>\r\n      <text>A bunch of [[text]] here.</text>\r\n    </revision>\r\n    <revision>\r\n      <text>An earlier [[revision]].</text>\r\n    </revision>\r\n  </page>\r\n</mediawiki>\r\n"
    {:ok, map} = SAXMap.from_string(xml)
    assert map["mediawiki"]["page"]["title"] == "Page title"
  end

  test "parse CDATA starts with \n or \r" do
    xml = """
      <xml><ToUserName><![CDATA[foo]]></ToUserName>
      <FromUserName><![CDATA[username]]></FromUserName>
      <CreateTime>1686729826</CreateTime>
      <MsgType><![CDATA[\r
      text

      !]]></MsgType>
      <Content><![CDATA[
       
      .]]></Content>
      <MsgId>24148163414427972</MsgId>
      </xml>
    """

    {:ok, map} = SAXMap.from_string(xml)
    assert map["xml"]["Content"] == "\n   \n  ."
    assert map["xml"]["MsgType"] == "\r\n  text\n\n  !"

    xml = """
      <xml><ToUserName><![CDATA[foo]]></ToUserName>
      <FromUserName><![CDATA[username]]></FromUserName>
      <CreateTime>1686729826</CreateTime>
      <MsgType><![CDATA[text]]></MsgType>
      <Content><![CDATA[
      .]]></Content>
      <MsgId>24148163414427972</MsgId>
      </xml>
    """

    {:ok, map} = SAXMap.from_string(xml)
    assert map["xml"]["Content"] == "\n  ."
  end

end
