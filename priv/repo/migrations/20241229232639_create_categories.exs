defmodule Brackley.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :title, :string
      add :description, :text
      add :category_slug, :string
      add :image_url, :string
      add :administrator_id, references(:administrators, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:categories, [:administrator_id])
  end
end
