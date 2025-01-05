defmodule BrackleyWeb.RestaurantHTML do
  use BrackleyWeb, :html

  embed_templates "restaurant_html/*"

  @doc """
  Renders a restaurant form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :category_list, :any, required: true

  def restaurant_form(assigns)
end
