defmodule BrackleyWeb.MealControllerTest do
  use BrackleyWeb.ConnCase

  import Brackley.AdministrationFixtures

  @create_attrs %{name: "some name", description: "some description", image_url: "some image_url", price: 42}
  @update_attrs %{name: "some updated name", description: "some updated description", image_url: "some updated image_url", price: 43}
  @invalid_attrs %{name: nil, description: nil, image_url: nil, price: nil}

  describe "index" do
    test "lists all meals", %{conn: conn} do
      conn = get(conn, ~p"/meals")
      assert html_response(conn, 200) =~ "Listing Meals"
    end
  end

  describe "new meal" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/meals/new")
      assert html_response(conn, 200) =~ "New Meal"
    end
  end

  describe "create meal" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/meals", meal: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/meals/#{id}"

      conn = get(conn, ~p"/meals/#{id}")
      assert html_response(conn, 200) =~ "Meal #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/meals", meal: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Meal"
    end
  end

  describe "edit meal" do
    setup [:create_meal]

    test "renders form for editing chosen meal", %{conn: conn, meal: meal} do
      conn = get(conn, ~p"/meals/#{meal}/edit")
      assert html_response(conn, 200) =~ "Edit Meal"
    end
  end

  describe "update meal" do
    setup [:create_meal]

    test "redirects when data is valid", %{conn: conn, meal: meal} do
      conn = put(conn, ~p"/meals/#{meal}", meal: @update_attrs)
      assert redirected_to(conn) == ~p"/meals/#{meal}"

      conn = get(conn, ~p"/meals/#{meal}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, meal: meal} do
      conn = put(conn, ~p"/meals/#{meal}", meal: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Meal"
    end
  end

  describe "delete meal" do
    setup [:create_meal]

    test "deletes chosen meal", %{conn: conn, meal: meal} do
      conn = delete(conn, ~p"/meals/#{meal}")
      assert redirected_to(conn) == ~p"/meals"

      assert_error_sent 404, fn ->
        get(conn, ~p"/meals/#{meal}")
      end
    end
  end

  defp create_meal(_) do
    meal = meal_fixture()
    %{meal: meal}
  end
end
