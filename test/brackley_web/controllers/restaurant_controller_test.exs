defmodule BrackleyWeb.RestaurantControllerTest do
  use BrackleyWeb.ConnCase

  import Brackley.AdministrationFixtures

  @create_attrs %{name: "some name", address: "some address", description: "some description", image_url: "some image_url", phone_number: "some phone_number"}
  @update_attrs %{name: "some updated name", address: "some updated address", description: "some updated description", image_url: "some updated image_url", phone_number: "some updated phone_number"}
  @invalid_attrs %{name: nil, address: nil, description: nil, image_url: nil, phone_number: nil}

  describe "index" do
    test "lists all restaurants", %{conn: conn} do
      conn = get(conn, ~p"/restaurants")
      assert html_response(conn, 200) =~ "Listing Restaurants"
    end
  end

  describe "new restaurant" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/restaurants/new")
      assert html_response(conn, 200) =~ "New Restaurant"
    end
  end

  describe "create restaurant" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/restaurants", restaurant: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/restaurants/#{id}"

      conn = get(conn, ~p"/restaurants/#{id}")
      assert html_response(conn, 200) =~ "Restaurant #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/restaurants", restaurant: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Restaurant"
    end
  end

  describe "edit restaurant" do
    setup [:create_restaurant]

    test "renders form for editing chosen restaurant", %{conn: conn, restaurant: restaurant} do
      conn = get(conn, ~p"/restaurants/#{restaurant}/edit")
      assert html_response(conn, 200) =~ "Edit Restaurant"
    end
  end

  describe "update restaurant" do
    setup [:create_restaurant]

    test "redirects when data is valid", %{conn: conn, restaurant: restaurant} do
      conn = put(conn, ~p"/restaurants/#{restaurant}", restaurant: @update_attrs)
      assert redirected_to(conn) == ~p"/restaurants/#{restaurant}"

      conn = get(conn, ~p"/restaurants/#{restaurant}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, restaurant: restaurant} do
      conn = put(conn, ~p"/restaurants/#{restaurant}", restaurant: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Restaurant"
    end
  end

  describe "delete restaurant" do
    setup [:create_restaurant]

    test "deletes chosen restaurant", %{conn: conn, restaurant: restaurant} do
      conn = delete(conn, ~p"/restaurants/#{restaurant}")
      assert redirected_to(conn) == ~p"/restaurants"

      assert_error_sent 404, fn ->
        get(conn, ~p"/restaurants/#{restaurant}")
      end
    end
  end

  defp create_restaurant(_) do
    restaurant = restaurant_fixture()
    %{restaurant: restaurant}
  end
end
