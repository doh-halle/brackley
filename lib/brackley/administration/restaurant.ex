defmodule Brackley.Administration.Restaurant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "restaurants" do
    field :name, :string
    field :address, :string
    field :description, :string
    field :image_url, :string
    field :phone_number, :string
    field :category_id, :id
    field :administrator_id, :id

    has_many :meals, Brackley.Administration.Meal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(restaurant, attrs) do
    restaurant
    |> cast(attrs, [
      :name,
      :description,
      :image_url,
      :address,
      :phone_number,
      :category_id,
      :administrator_id
    ])
    |> validate_required([
      :name,
      :description,
      :image_url,
      :address,
      :phone_number,
      :category_id,
      :administrator_id
    ])
  end
end
