defmodule MessagePackTest do
  use ExUnit.Case

  import MessagePack, only: [unpack: 1]

  test "unpacks nil",   do: assert unpack(<<0xc0>>) == nil
  test "unpacks false", do: assert unpack(<<0xc2>>) == false
  test "unpacks true",  do: assert unpack(<<0xc3>>) == true

  test "unpacks zero",             do: assert unpack(<<0x00>>) == 0
  test "unpacks 127",              do: assert unpack(<<0x7f>>) == 0x7f
  test "unpacks 128",              do: assert unpack(<<0xcc, 0x80>>) == 0x80
  test "unpacks 256",              do: assert unpack(<<0xcd, 0x01, 0x00>>) == 0x100
  test "unpacks 23435345",         do: assert unpack(<<0xce, 0x01, 0x65, 0x98, 0x51>>) == 0x1659851
  test "unpacks 2342347938475324", do: assert unpack(<<0xcf, 0x00, 0x08, 0x52, 0x5a, 0x60, 0xd0, 0x2d, 0x3c>>) == 0x0008525a60d02d3c

  test "unpacks -1",                 do: assert unpack(<<0xff>>) == -1
  test "unpacks -33",                do: assert unpack(<<0xd0, 0xdf>>) == -33
  test "unpacks -129",               do: assert unpack(<<0xd1, 0xff, 0x7f>>) == -129
  test "unpacks -8444910",           do: assert unpack(<<0xd2, 0xff, 0x7f, 0x24, 0x12>>) == -8444910
  test "unpacks -41957882392009710", do: assert unpack(<<0xd3, 0xff, 0x6a, 0xef, 0x87, 0x3c, 0x7f, 0x24, 0x12>>) == -41957882392009710

  test "unpacks 1.0f",     do: assert_in_delta(unpack(<<0xca, 0x3f, 0x80, 0x00, 0x00>>), 1.0, 0.0001)
  test "unpacks 1.0d",     do: assert_in_delta(unpack(<<0xcb, 0x3f, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>), 1.0, 0.0000001)
  test "unpacks 3.14f",    do: assert_in_delta(unpack(<<0xca, 0x40, 0x48, 0xf5, 0xc3>>), 3.14, 0.0001)
  test "unpacks 3.14...d", do: assert_in_delta(unpack(<<0xcb, 0x43, 0xc5, 0xcc, 0x96, 0xef, 0xd1, 0x19, 0x25>>), :math.pi * 1_000_000_000_000_000_000, 0.0000001)
  test "unpacks -2.1f",    do: assert_in_delta(unpack(<<0xca, 0xc0, 0x6, 0x66, 0x66>>), -2.1, 0.0001)
  test "unpacks -2.1d",    do: assert_in_delta(unpack(<<0xcb, 0xc0, 0x00, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcd>>), -2.1, 0.0000001)

  test "unpacks empty strings",  do: assert unpack(<<0xa0>>) == ""
  test "unpacks strings",        do: assert unpack(<<0xab, "hello world">>) == "hello world"
  test "unpacks medium strings", do: assert unpack(<<0xd9, 0x0b>> <> String.duplicate("x", 0x0b)) == "xxxxxxxxxxx"
  test "unpacks big strings",    do: assert unpack(<<0xda, 0x01, 0x0b>> <> String.duplicate("x", 0x010b)) == String.duplicate("x", 0x010b)
  test "unpacks huge strings",   do: assert unpack(<<0xdb, 0x00, 0x01, 0x00, 0x0b>> <> String.duplicate("x", 0x01000b)) == String.duplicate("x", 0x01000b)

  test "unpacks medium binaries", do: assert unpack(<<0xc4, 0x05, 0x01, 0x02, 0x03, 0x04, 0x05>>) == <<0x01, 0x02, 0x03, 0x04, 0x05>>
  test "unpacks big binaries",    do: assert unpack(<<0xc5, 0x00, 0x05, 0x01, 0x02, 0x03, 0x04, 0x05>>) == <<0x01, 0x02, 0x03, 0x04, 0x05>>
  test "unpacks huge binaries",   do: assert unpack(<<0xc6, 0x00, 0x00, 0x00, 0x05, 0x01, 0x02, 0x03, 0x04, 0x05>>) == <<0x01, 0x02, 0x03, 0x04, 0x05>>

  test "unpacks empty arrays",             do: assert unpack(<<0x90>>) == []
  test "unpacks small arrays",             do: assert unpack(<<0x92, 0x01, 0x02>>) == [1, 2]
  test "unpacks medium arrays",            do: assert unpack(<<0xdc, 0x01, 0x11>> <> String.duplicate(<<0xc2>>, 0x0111)) == List.duplicate(false, 0x0111)
  test "unpacks big arrays",               do: assert unpack(<<0xdd, 0x00, 0x00, 0x01, 0x11>> <> String.duplicate(<<0xc2>>, 0x0111)) == List.duplicate(false, 0x0111)
  test "unpacks arrays with strings",      do: assert unpack(<<0x92, 0xa5, "hello", 0xa5, "world">>) == ["hello", "world"]
  test "unpacks arrays with mixed values", do: assert unpack(<<0x93, 0xa5, "hello", 0xa5, "world", 42>>) == ["hello", "world", 42]
  test "unpacks arrays of arrays",         do: assert unpack(<<0x91, 0x92, 0x92, 0x92, 0x01, 0x02, 0x03, 0x04>>) == [[[[1, 2], 3], 4]]

  test "unpacks empty dicts",              do: assert unpack(<<0x80>>) == HashDict.new
  test "unpacks small dicts",              do: assert unpack(<<0x81, 0xa3, "foo", 0xa3, "bar">>) == HashDict.new([{"foo", "bar"}])
  test "unpacks medium dicts",             do: assert unpack(<<0xde, 0x00, 0x01, 0xa3, "foo", 0xa3, "bar">>) == HashDict.new([{"foo", "bar"}])
  test "unpacks big dicts",                do: assert unpack(<<0xdf, 0x00, 0x00, 0x00, 0x01, 0xa3, "foo", 0xa3, "bar">>) == HashDict.new([{"foo", "bar"}])
  test "unpacks dicts with mixed content", do: assert unpack(<<0x85, 0xa3, "foo", 0xa3, "bar", 0x03, 0xa5, "three", 0xa4, "four", 0x04, 0xa1, "x", 0x91, 0xa1, "y", 0xa1, "a", 0xa1, "b">>) == HashDict.new([{"foo", "bar"}, {3, "three"}, {"four", 4}, {"x", ["y"]}, {"a", "b"}])
  test "unpacks dicts of dicts",           do: assert unpack(<<0x81, 0x81, 0xa1, "x", 0x81, 0xa1, "y", 0xa1, "z", 0xa1, "s">>) == HashDict.new([{HashDict.new([{"x", HashDict.new([{"y", "z"}])}]), "s"}])
  test "unpacks dicts with nils",          do: assert unpack(<<0x81, 0xa3, "foo", 0xc0>>) == HashDict.new([{"foo", nil}])
end
