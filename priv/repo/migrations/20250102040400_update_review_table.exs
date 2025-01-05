defmodule Brackley.Repo.Migrations.UpdateReviewTable do
  use Ecto.Migration

  def change do
    alter table(:reviews) do
      modify :status, :string, enum: ["Pending", "Approved", "Rejected"], default: "Pending"
    end

  end
end
