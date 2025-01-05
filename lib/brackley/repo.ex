defmodule Brackley.Repo do
  use Ecto.Repo,
    otp_app: :brackley,
    adapter: Ecto.Adapters.Postgres
end
