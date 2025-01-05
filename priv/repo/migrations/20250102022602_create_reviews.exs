defmodule Brackley.Repo.Migrations.CreateReviews do
  use Ecto.Migration

  def change do
    create table(:reviews) do
      add :review, :text
      add :rating, :integer, min: 0, max: 5, default: 0
      add :status, :string, enum: ["Pending", "Approved", "Rejected"], default: "Pending"
      add :comments, :integer, default: 0
      add :meal_id, references(:meals, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:reviews, [:meal_id])
    create index(:reviews, [:user_id])
  end
end
