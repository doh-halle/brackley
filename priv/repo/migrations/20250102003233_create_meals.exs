defmodule Brackley.Repo.Migrations.CreateMeals do
  use Ecto.Migration

  def change do
    create table(:meals) do
      add :name, :string
      add :description, :string
      add :image_url, :string
      add :price, :integer
      add :restaurant_id, references(:restaurants, on_delete: :delete_all)
      add :administrator_id, references(:administrators, on_delete: :delete_all)


      timestamps(type: :utc_datetime)
    end

    create index(:meals, [:restaurant_id])
    create index(:meals, [:administrator_id])
  end
end
