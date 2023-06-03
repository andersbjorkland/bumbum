defmodule Bumbum.Repo do
  use Ecto.Repo,
    otp_app: :bumbum,
    adapter: Ecto.Adapters.Postgres
end
