defmodule Brackley.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :comment, :text
      add :user_id, references(:users, on_delete: :nothing)
      add :review_id, references(:reviews, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:user_id])
    create index(:comments, [:review_id])
  end
end
