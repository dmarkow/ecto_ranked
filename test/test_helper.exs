ExUnit.start()

defmodule EctoRanked.TestCase do
  use ExUnit.CaseTemplate

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EctoRanked.Test.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(EctoRanked.Test.Repo, {:shared, self()})
  end
end

{:ok, _pid} = EctoRanked.Test.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(EctoRanked.Test.Repo, {:shared, self()})
