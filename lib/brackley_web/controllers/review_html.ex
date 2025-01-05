defmodule BrackleyWeb.ReviewHTML do
  use BrackleyWeb, :html

  embed_templates "review_html/*"

  @doc """
  Renders a review form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :meal_list, :any, required: true

  def review_form(assigns)
end
