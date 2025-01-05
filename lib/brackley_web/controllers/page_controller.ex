defmodule BrackleyWeb.PageController do
  use BrackleyWeb, :controller

  alias Brackley.Administration

  def index(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    restaurants = Administration.list_restaurants()
    categories = Administration.list_categories()
    render(conn, :index, layout: false, categories: categories, restaurants: restaurants)
  end
end
