defmodule BrackleyWeb.AdministratorRegistrationControllerTest do
  use BrackleyWeb.ConnCase, async: true

  import Brackley.AdministrationFixtures

  describe "GET /administrators/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, ~p"/administrators/register")
      response = html_response(conn, 200)
      assert response =~ "Register"
      assert response =~ ~p"/administrators/log_in"
      assert response =~ ~p"/administrators/register"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_administrator(administrator_fixture()) |> get(~p"/administrators/register")

      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "POST /administrators/register" do
    @tag :capture_log
    test "creates account and logs the administrator in", %{conn: conn} do
      email = unique_administrator_email()

      conn =
        post(conn, ~p"/administrators/register", %{
          "administrator" => valid_administrator_attributes(email: email)
        })

      assert get_session(conn, :administrator_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ email
      assert response =~ ~p"/administrators/settings"
      assert response =~ ~p"/administrators/log_out"
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, ~p"/administrators/register", %{
          "administrator" => %{"email" => "with spaces", "password" => "too short"}
        })

      response = html_response(conn, 200)
      assert response =~ "Register"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 12 character"
    end
  end
end
