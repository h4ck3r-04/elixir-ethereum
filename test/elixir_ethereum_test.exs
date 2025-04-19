defmodule ElixirEthereumTest do
  use ExUnit.Case
  doctest ElixirEthereum

  test "greets the world" do
    assert ElixirEthereum.hello() == :world
  end
end
