defmodule Brackley.Repo.Migrations.Update02ReviewTable do
  use Ecto.Migration

  def change do
    alter table(:reviews) do
      modify :status, :string, enum: ["Pending", "Approved", "Rejected"], default: "Pending"
    end
  end
end
