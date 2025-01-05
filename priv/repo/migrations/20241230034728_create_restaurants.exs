defmodule Brackley.Repo.Migrations.CreateRestaurants do
  use Ecto.Migration

  def change do
    create table(:restaurants) do
      add :name, :string
      add :description, :text
      add :image_url, :string
      add :address, :string
      add :phone_number, :string
      add :category_id, references(:categories, on_delete: :delete_all)
      add :administrator_id, references(:administrators, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:restaurants, [:category_id])
    create index(:restaurants, [:administrator_id])
  end
end
