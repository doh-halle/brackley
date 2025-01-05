defmodule Brackley.Administration.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :description, :string
    field :title, :string
    field :category_slug, :string
    field :image_url, :string
    field :administrator_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:title, :description, :category_slug, :image_url, :administrator_id])
    |> validate_required([:title, :description, :category_slug, :image_url, :administrator_id])
  end
end
