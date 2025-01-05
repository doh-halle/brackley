defmodule BrackleyWeb.MealHTML do
  use BrackleyWeb, :html

  embed_templates "meal_html/*"

  @doc """
  Renders a meal form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :restaurant_list, :any, required: true

  def meal_form(assigns)
end
