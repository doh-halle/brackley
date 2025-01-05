defmodule Brackley.Repo.Migrations.CreateAdministratorsAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:administrators) do
      add :full_name, :string, null: false
      add :username, :citext, null: false
      add :role, :string, enum: ["Viewer", "Contributor", "Owner"], default: "Viewer"
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:administrators, [:email])

    create table(:administrators_tokens) do
      add :administrator_id, references(:administrators, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:administrators_tokens, [:administrator_id])
    create unique_index(:administrators_tokens, [:context, :token])
  end
end
