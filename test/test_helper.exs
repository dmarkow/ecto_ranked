ExUnit.start()

defmodule EctoRanked.TestCase do
  use ExUnit.CaseTemplate

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EctoRankedTest.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(EctoRankedTest.Repo, {:shared, self()})
  end
end

{:ok, _pid} = EctoRankedTest.Repo.start_link
Ecto.Adapters.SQL.Sandbox.mode(EctoRankedTest.Repo, {:shared, self()})
