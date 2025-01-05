defmodule BrackleyWeb.RestaurantController do
  use BrackleyWeb, :controller

  alias Brackley.Administration
  alias Brackley.Administration.Restaurant

  def index(conn, _params) do
    restaurants = Administration.list_restaurants()
    categories = Administration.list_categories()
    category_list = Enum.map(categories, &{&1.title, &1.id})
    # category_id_list = Enum.map(category_list, fn {_, id} -> id end)
    # category_title_list = Enum.map(category_list, fn {title, _} -> title end)
    # IO.inspect(category_list, label: "These is the category list -- ")
    # IO.inspect(category_id_list, label: "These  the category id list -- ")
    # IO.inspect(category_title_list, label: "These are the category title list -- ")
    render(conn,
    :index,
    restaurants: restaurants,
    categories: categories,
    category_list: category_list
    # category_id_list: category_id_list,
    # category_title_list: category_title_list
    )

  end

  def new(conn, _params) do
    category_list = Enum.map(Administration.list_categories(), &{&1.title, &1.id})
    administrator_id = conn.assigns.current_administrator.id
    category_id = %{key: "value"}
    # IO.inspect(category_list, label: "This is the category list -- ")
    changeset =
      Administration.change_restaurant(%Restaurant{
        administrator_id: administrator_id,
        category_id: category_id
      })
    render(conn, :new, changeset: changeset, category_list: category_list)


  end

  def create(conn, %{"restaurant" => restaurant_params}) do
    case Administration.create_restaurant(restaurant_params) do
      {:ok, restaurant} ->
        conn
        |> put_flash(:info, "Restaurant created successfully.")
        |> redirect(to: ~p"/restaurants/#{restaurant}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    restaurant = Administration.get_restaurant!(id)
    category = Administration.get_category!(restaurant.category_id)
    render(conn, :show, restaurant: restaurant, category: category)
  end

  def edit(conn, %{"id" => id}) do
    restaurant = Administration.get_restaurant!(id)
    changeset = Administration.change_restaurant(restaurant)
    render(conn, :edit, restaurant: restaurant, changeset: changeset)
  end

  def update(conn, %{"id" => id, "restaurant" => restaurant_params}) do
    restaurant = Administration.get_restaurant!(id)

    case Administration.update_restaurant(restaurant, restaurant_params) do
      {:ok, restaurant} ->
        conn
        |> put_flash(:info, "Restaurant updated successfully.")
        |> redirect(to: ~p"/restaurants/#{restaurant}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, restaurant: restaurant, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    restaurant = Administration.get_restaurant!(id)
    {:ok, _restaurant} = Administration.delete_restaurant(restaurant)

    conn
    |> put_flash(:info, "Restaurant deleted successfully.")
    |> redirect(to: ~p"/restaurants")
  end
end
