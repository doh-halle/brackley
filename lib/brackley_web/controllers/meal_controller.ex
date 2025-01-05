defmodule BrackleyWeb.MealController do
  use BrackleyWeb, :controller

  alias Brackley.Administration
  alias Brackley.Administration.Meal

  def index(conn, _params) do
    meals = Administration.list_meals()
    render(conn, :index, meals: meals)
  end

  def new(conn, _params) do
    restaurant_list = Enum.map(Administration.list_restaurants(), &{&1.name, &1.id})
    #IO.inspect(restaurant_list, label: "This is the restaurant list -- ")
    administrator_id = conn.assigns.current_administrator.id
    restaurant_id = %{key: "value"}
    changeset = Administration.change_meal(%Meal{
      administrator_id: administrator_id,
      restaurant_id: restaurant_id
    })
    render(conn, :new, changeset: changeset, restaurant_list: restaurant_list)
  end

  def create(conn, %{"meal" => meal_params}) do
    case Administration.create_meal(meal_params) do
      {:ok, meal} ->
        conn
        |> put_flash(:info, "Meal created successfully.")
        |> redirect(to: ~p"/meals/#{meal}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    meal = Administration.get_meal!(id)
    render(conn, :show, meal: meal)
  end

  def edit(conn, %{"id" => id}) do
    restaurant_list = Enum.map(Administration.list_restaurants(), &{&1.name, &1.id})
    meal = Administration.get_meal!(id)
    changeset = Administration.change_meal(meal)
    render(conn, :edit, meal: meal, changeset: changeset, restaurant_list: restaurant_list)
  end

  def update(conn, %{"id" => id, "meal" => meal_params}) do
    meal = Administration.get_meal!(id)

    case Administration.update_meal(meal, meal_params) do
      {:ok, meal} ->
        conn
        |> put_flash(:info, "Meal updated successfully.")
        |> redirect(to: ~p"/meals/#{meal}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, meal: meal, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    meal = Administration.get_meal!(id)
    {:ok, _meal} = Administration.delete_meal(meal)

    conn
    |> put_flash(:info, "Meal deleted successfully.")
    |> redirect(to: ~p"/meals")
  end
end
