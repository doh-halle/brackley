defmodule Brackley.Administration.Meal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "meals" do
    field :name, :string
    field :description, :string
    field :image_url, :string
    field :price, :integer
    field :restaurant_id, :id
    field :administrator_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meal, attrs) do
    meal
    |> cast(attrs, [:name, :description, :image_url, :price, :restaurant_id, :administrator_id])
    |> validate_required([:name, :description, :image_url, :price, :restaurant_id, :administrator_id])
  end
end
