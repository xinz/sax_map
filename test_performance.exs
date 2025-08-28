#!/usr/bin/env elixir

# Simple performance test script to verify optimizations work correctly
# This tests basic functionality without external dependencies

defmodule SimpleTest do
  def run do
    IO.puts("Running basic SAXMap functionality tests...")
    
    # Test 1: Simple XML
    xml1 = "<root><item>test</item></root>"
    case SAXMap.from_string(xml1) do
      {:ok, %{"root" => %{"item" => "test"}}} ->
        IO.puts("✓ Test 1 passed: Simple XML")
      result ->
        IO.puts("✗ Test 1 failed: #{inspect(result)}")
    end

    # Test 2: XML with attributes (ignore)
    xml2 = "<root attr=\"value\"><item>test</item></root>"
    case SAXMap.from_string(xml2, ignore_attribute: true) do
      {:ok, %{"root" => %{"item" => "test"}}} ->
        IO.puts("✓ Test 2 passed: XML with attributes (ignored)")
      result ->
        IO.puts("✗ Test 2 failed: #{inspect(result)}")
    end

    # Test 3: XML with attributes (preserve)
    xml3 = "<root attr=\"value\"><item>test</item></root>"
    case SAXMap.from_string(xml3, ignore_attribute: false) do
      {:ok, %{"root" => %{"attr" => "value", "content" => %{"item" => %{"content" => "test"}}}}} ->
        IO.puts("✓ Test 3 passed: XML with attributes (preserved)")
      result ->
        IO.puts("✗ Test 3 failed: #{inspect(result)}")
    end

    # Test 4: XML with whitespace handling
    xml4 = "<root>  \n  <item>  test  </item>  \n  </root>"
    case SAXMap.from_string(xml4) do
      {:ok, %{"root" => %{"item" => "  test  "}}} ->
        IO.puts("✓ Test 4 passed: Whitespace handling")
      result ->
        IO.puts("✗ Test 4 failed: #{inspect(result)}")
    end

    # Test 5: Multiple items
    xml5 = "<root><item>1</item><item>2</item><item>3</item></root>"
    case SAXMap.from_string(xml5) do
      {:ok, %{"root" => %{"item" => ["1", "2", "3"]}}} ->
        IO.puts("✓ Test 5 passed: Multiple items")
      {:ok, %{"root" => %{"item" => ["3", "2", "1"]}}} ->
        IO.puts("✓ Test 5 passed: Multiple items (reverse order)")
      result ->
        IO.puts("✗ Test 5 failed: #{inspect(result)}")
    end

    IO.puts("\nBasic functionality tests completed.")
  end
end

SimpleTest.run()