defmodule ElixirEthereum do
  alias __MODULE__.{Block, Transaction}

  defmodule Transaction do
    defstruct [:from, :to, :amount, :timestamp, :signature]

    def new(from, to, amount) do
      %Transaction{
        from: from,
        to: to,
        amount: amount,
        timestamp: DateTime.utc_now(),
        signature: generate_signature(from, to, amount)
      }
    end

    defp generate_signature(from, to, amount) do
      :crypto.hash(:sha256, "#{from}#{to}#{amount}") |> Base.encode16()
    end
  end

  defmodule Block do
    defstruct [:index, :previous_hash, :timestamp, :transactions, :nonce, :hash]

    def new(index, previous_hash, transactions) do
      block = %Block{
        index: index,
        previous_hash: previous_hash,
        timestamp: DateTime.utc_now(),
        transactions: transactions,
        nonce: 0
      }

      mine_block(block)
    end

    def calculate_hash(%Block{
          index: index,
          previous_hash: previous_hash,
          timestamp: timestamp,
          transactions: transactions,
          nonce: nonce
        }) do
      data = "#{index}#{previous_hash}#{timestamp}#{inspect(transactions)}#{nonce}"
      :crypto.hash(:sha256, data) |> Base.encode16()
    end

    defp mine_block(block, difficulty \\ 4) do
      target = String.duplicate("0", difficulty)

      {nonce, hash} =
        Stream.iterate(0, &(&1 + 1))
        |> Enum.reduce_while(nil, fn nonce, _ ->
          candidate = %{block | nonce: nonce}
          hash = calculate_hash(candidate)

          if String.starts_with?(hash, target) do
            {:halt, {nonce, hash}}
          else
            {:cont, nil}
          end
        end)

      %{block | nonce: nonce, hash: hash}
    end
  end

  defmodule Blockchain do
    defstruct [:chain, :pending_transactions]

    def new do
      genesis_block = Block.new(0, "0", [])

      %Blockchain{
        chain: [genesis_block],
        pending_transactions: []
      }
    end

    def add_transaction(blockchain, transaction) do
      %{blockchain | pending_transactions: [transaction | blockchain.pending_transactions]}
    end

    def mine_pending_transactions(blockchain) do
      last_block = List.first(blockchain.chain)

      new_block =
        Block.new(
          last_block.index + 1,
          last_block.hash,
          blockchain.pending_transactions
        )

      %{
        blockchain
        | chain: [new_block | blockchain.chain],
          pending_transactions: []
      }
    end

    def valid?(blockchain) do
      blockchain.chain
      |> Enum.reverse()
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.all?(fn [current, previous] ->
        current.previous_hash == previous.hash &&
          current.hash == Block.calculate_hash(current)
      end)
    end
  end
end
