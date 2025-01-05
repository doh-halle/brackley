defmodule Brackley.Account.Review do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reviews" do
    field :status, :string, default: "Pending"
    field :comments, :integer
    field :review, :string
    field :rating, :integer
    field :meal_id, :id
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(review, attrs) do
    review
    |> cast(attrs, [:review, :rating, :meal_id, :user_id])
    |> validate_required([:review, :rating, :meal_id, :user_id])
  end
end
