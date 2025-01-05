defmodule BrackleyWeb.CategoryController do
  use BrackleyWeb, :controller

  alias Brackley.Administration
  alias Brackley.Administration.Category

  def index(conn, _params) do
    categories = Administration.list_categories()
    render(conn, :index, categories: categories)
  end

  def new(conn, _params) do
    id = conn.assigns.current_administrator.id
    changeset = Administration.change_category(%Category{administrator_id: id})

    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"category" => category_params}) do
    case Administration.create_category(category_params) do
      {:ok, category} ->
        conn
        |> put_flash(:info, "Category created successfully.")
        |> redirect(to: ~p"/categories/#{category}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    category = Administration.get_category!(id)
    render(conn, :show, category: category)
  end

  def edit(conn, %{"id" => id}) do
    category = Administration.get_category!(id)
    changeset = Administration.change_category(category)
    render(conn, :edit, category: category, changeset: changeset)
  end

  def update(conn, %{"id" => id, "category" => category_params}) do
    category = Administration.get_category!(id)

    case Administration.update_category(category, category_params) do
      {:ok, category} ->
        conn
        |> put_flash(:info, "Category updated successfully.")
        |> redirect(to: ~p"/categories/#{category}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, category: category, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    category = Administration.get_category!(id)
    {:ok, _category} = Administration.delete_category(category)

    conn
    |> put_flash(:info, "Category deleted successfully.")
    |> redirect(to: ~p"/categories")
  end
end
