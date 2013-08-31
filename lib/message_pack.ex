defmodule MessagePack do
  def unpack(bytes) when is_binary(bytes) do
    {thing, _} = _unpack(bytes)
    thing
  end

  defp _unpack(<<0xc0, rest :: binary>>), do: {nil, rest}
  defp _unpack(<<0xc2, rest :: binary>>), do: {false, rest}
  defp _unpack(<<0xc3, rest :: binary>>), do: {true, rest}
  
  defp _unpack(<<0 :: size(1), n :: [unsigned, integer, size(7)], rest :: binary>>), do: {n, rest}
  defp _unpack(<<0xcc, n :: [unsigned, integer, size( 8)], rest :: binary>>), do: {n, rest}
  defp _unpack(<<0xcd, n :: [unsigned, integer, size(16)], rest :: binary>>), do: {n, rest}
  defp _unpack(<<0xce, n :: [unsigned, integer, size(32)], rest :: binary>>), do: {n, rest}
  defp _unpack(<<0xcf, n :: [unsigned, integer, size(64)], rest :: binary>>), do: {n, rest}

  defp _unpack(<<0b111 :: size(3), n :: [signed, integer, size(5)], rest :: binary>>), do: {n, rest}
  defp _unpack(<<0xd0, n :: [signed, integer, size( 8)], rest :: binary>>), do: {n, rest}
  defp _unpack(<<0xd1, n :: [signed, integer, size(16)], rest :: binary>>), do: {n, rest}
  defp _unpack(<<0xd2, n :: [signed, integer, size(32)], rest :: binary>>), do: {n, rest}
  defp _unpack(<<0xd3, n :: [signed, integer, size(64)], rest :: binary>>), do: {n, rest}
  
  defp _unpack(<<0xca, n :: [float, size(32)], rest :: binary>>), do: {n, rest}
  defp _unpack(<<0xcb, n :: [float, size(64)], rest :: binary>>), do: {n, rest}

  defp _unpack(<<0xa0, rest :: binary>>), do: {"" , rest}
  defp _unpack(<<0b101 :: size(3), n :: size(5), s :: [binary, size(n)], rest :: binary>>), do: {s, rest}
  defp _unpack(<<0xd9, n :: [unsigned, integer, size( 8)], s :: [binary, size(n)], rest :: binary>>), do: {s, rest}
  defp _unpack(<<0xda, n :: [unsigned, integer, size(16)], s :: [binary, size(n)], rest :: binary>>), do: {s, rest}
  defp _unpack(<<0xdb, n :: [unsigned, integer, size(32)], s :: [binary, size(n)], rest :: binary>>), do: {s, rest}

  defp _unpack(<<0xc4, n :: [unsigned, integer, size( 8)], s :: [binary, size(n)], rest :: binary>>), do: {s, rest}
  defp _unpack(<<0xc5, n :: [unsigned, integer, size(16)], s :: [binary, size(n)], rest :: binary>>), do: {s, rest}
  defp _unpack(<<0xc6, n :: [unsigned, integer, size(32)], s :: [binary, size(n)], rest :: binary>>), do: {s, rest}

  defp _unpack(<<0b1001 :: size(4), n :: size(4), rest :: binary>>), do: _unpack_list(rest, n)
  defp _unpack(<<0xdc, n :: [unsigned, integer, size(16)], rest :: binary>>), do: _unpack_list(rest, n)
  defp _unpack(<<0xdd, n :: [unsigned, integer, size(32)], rest :: binary>>), do: _unpack_list(rest, n)

  defp _unpack(<<0b1000 :: size(4), n :: size(4), rest :: binary>>), do: _unpack_dict(rest, n)
  defp _unpack(<<0xde, n :: [unsigned, integer, size(16)], rest :: binary>>), do: _unpack_dict(rest, n)
  defp _unpack(<<0xdf, n :: [unsigned, integer, size(32)], rest :: binary>>), do: _unpack_dict(rest, n)

  defp _unpack_list(bytes, n), do: _unpack_list(bytes, n, [])
  defp _unpack_list(bytes, 0, list), do: {Enum.reverse(list), bytes}
  defp _unpack_list(bytes, n, list) do
    {thing, rest} = _unpack(bytes)
    _unpack_list(rest, n - 1, [thing | list])
  end

  defp _unpack_dict(bytes, n), do: _unpack_dict(bytes, n, HashDict.new)
  defp _unpack_dict(bytes, 0, dict), do: {dict, bytes}
  defp _unpack_dict(bytes, n, dict) do
    {key, rest1} = _unpack(bytes)
    {value, rest2} = _unpack(rest1)
    _unpack_dict(rest2, n - 1, Dict.put(dict, key, value))
  end
end
