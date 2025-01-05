defmodule Brackley.Repo.Migrations.DropReviewTable do
  use Ecto.Migration

  def change do
    drop_if_exists table(:reviews)
  end
end
