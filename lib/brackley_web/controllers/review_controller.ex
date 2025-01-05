defmodule BrackleyWeb.ReviewController do
  use BrackleyWeb, :controller

  alias Brackley.Administration
  alias Brackley.Account
  alias Brackley.Account.Review

  def index(conn, _params) do
    reviews = Account.list_reviews()
    render(conn, :index, reviews: reviews)
  end

  def new(conn, _params) do
    meal_list = Enum.map(Administration.list_meals(), &{&1.name, &1.id})
    user_id = conn.assigns.current_user.id
    meal_id = %{key: "value"}
    changeset = Account.change_review(%Review{user_id: user_id, meal_id: meal_id})
    render(conn, :new, changeset: changeset, meal_list: meal_list)
  end

  def create(conn, %{"review" => review_params}) do
    case Account.create_review(review_params) do
      {:ok, review} ->
        conn
        |> put_flash(:info, "Review created successfully.")
        |> redirect(to: ~p"/reviews/#{review}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    review = Account.get_review!(id)
    render(conn, :show, review: review)
  end

  def edit(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user
    meal_list = Enum.map(Administration.list_meals(), &{&1.name, &1.id})
    review = Account.get_review!(id)

    if review.user_id == current_user.id do
      changeset = Account.change_review(review)
      render(conn, :edit, review: review, changeset: changeset, meal_list: meal_list)
    else
      conn
      |> put_flash(:error, "You are not authorized to edit this review.")
      |> redirect(to: ~p"/reviews")
    end
  end

  def update(conn, %{"id" => id, "review" => review_params}) do
    review = Account.get_review!(id)

    case Account.update_review(review, review_params) do
      {:ok, review} ->
        conn
        |> put_flash(:info, "Review updated successfully.")
        |> redirect(to: ~p"/reviews/#{review}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, review: review, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user
    review = Account.get_review!(id)

    if review.user_id == current_user.id do
      {:ok, _review} = Account.delete_review(review)

      conn
      |> put_flash(:info, "Review deleted successfully.")
      |> redirect(to: ~p"/reviews")
    else
      conn
      |> put_flash(:error, "You are not authorized to delete this review.")
      |> redirect(to: ~p"/reviews")
    end
  end
end
