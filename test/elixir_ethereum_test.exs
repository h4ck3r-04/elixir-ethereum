defmodule ElixirEthereumTest do
  use ExUnit.Case
  doctest ElixirEthereum

  alias ElixirEthereum.{Blockchain, Transaction, Block}

  test "creates a valid transaction" do
    tx = Transaction.new("alice", "bob", 100)
    assert tx.from == "alice"
    assert tx.to == "bob"
    assert tx.amount == 100
    assert is_binary(tx.signature)
    assert tx.timestamp |> DateTime.to_unix() |> is_integer()
  end

  test "creates a genesis block" do
    blockchain = Blockchain.new()
    assert length(blockchain.chain) == 1
    genesis = List.first(blockchain.chain)
    assert genesis.index == 0
    assert genesis.previous_hash == "0"
    assert genesis.transactions == []
    assert is_binary(genesis.hash)
    assert String.starts_with?(genesis.hash, "0000")
    assert genesis.hash == Block.calculate_hash(genesis)
  end

  test "mines a block with transactions" do
    tx = Transaction.new("alice", "bob", 100)
    block = Block.new(1, "0", [tx])
    assert block.index == 1
    assert block.previous_hash == "0"
    assert block.transactions == [tx]
    assert is_integer(block.nonce)
    assert String.starts_with?(block.hash, "0000")
    assert block.hash == Block.calculate_hash(block)
  end

  test "adds transactions and mines a new block" do
    blockchain = Blockchain.new()
    tx1 = Transaction.new("alice", "bob", 100)
    tx2 = Transaction.new("bob", "charlie", 50)

    blockchain =
      blockchain
      |> Blockchain.add_transaction(tx1)
      |> Blockchain.add_transaction(tx2)
      |> Blockchain.mine_pending_transactions()

    assert length(blockchain.chain) == 2
    assert blockchain.pending_transactions == []
    new_block = List.first(blockchain.chain)
    assert length(new_block.transactions) == 2
    assert new_block.index == 1
    assert new_block.previous_hash == List.last(blockchain.chain).hash
    assert Blockchain.valid?(blockchain)
  end

  test "validates a correct blockchain" do
    blockchain = Blockchain.new()
    tx = Transaction.new("alice", "bob", 100)

    blockchain =
      blockchain
      |> Blockchain.add_transaction(tx)
      |> Blockchain.mine_pending_transactions()

    assert Blockchain.valid?(blockchain)
  end

  test "detects an invalid blockchain" do
    blockchain = Blockchain.new()
    tx = Transaction.new("alice", "bob", 100)

    blockchain =
      blockchain
      |> Blockchain.add_transaction(tx)
      |> Blockchain.mine_pending_transactions()

    tampered_block = List.first(blockchain.chain)
    tampered_block = %{tampered_block | hash: "INVALID_HASH"}
    tampered_chain = [tampered_block | tl(blockchain.chain)]
    invalid_blockchain = %{blockchain | chain: tampered_chain}
    refute Blockchain.valid?(invalid_blockchain)
  end
end
