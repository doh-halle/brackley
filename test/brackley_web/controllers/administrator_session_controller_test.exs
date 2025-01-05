defmodule BrackleyWeb.AdministratorSessionControllerTest do
  use BrackleyWeb.ConnCase, async: true

  import Brackley.AdministrationFixtures

  setup do
    %{administrator: administrator_fixture()}
  end

  describe "GET /administrators/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, ~p"/administrators/log_in")
      response = html_response(conn, 200)
      assert response =~ "Log in"
      assert response =~ ~p"/administrators/register"
      assert response =~ "Forgot your password?"
    end

    test "redirects if already logged in", %{conn: conn, administrator: administrator} do
      conn = conn |> log_in_administrator(administrator) |> get(~p"/administrators/log_in")
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "POST /administrators/log_in" do
    test "logs the administrator in", %{conn: conn, administrator: administrator} do
      conn =
        post(conn, ~p"/administrators/log_in", %{
          "administrator" => %{"email" => administrator.email, "password" => valid_administrator_password()}
        })

      assert get_session(conn, :administrator_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ administrator.email
      assert response =~ ~p"/administrators/settings"
      assert response =~ ~p"/administrators/log_out"
    end

    test "logs the administrator in with remember me", %{conn: conn, administrator: administrator} do
      conn =
        post(conn, ~p"/administrators/log_in", %{
          "administrator" => %{
            "email" => administrator.email,
            "password" => valid_administrator_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_brackley_web_administrator_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the administrator in with return to", %{conn: conn, administrator: administrator} do
      conn =
        conn
        |> init_test_session(administrator_return_to: "/foo/bar")
        |> post(~p"/administrators/log_in", %{
          "administrator" => %{
            "email" => administrator.email,
            "password" => valid_administrator_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "emits error message with invalid credentials", %{conn: conn, administrator: administrator} do
      conn =
        post(conn, ~p"/administrators/log_in", %{
          "administrator" => %{"email" => administrator.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "Log in"
      assert response =~ "Invalid email or password"
    end
  end

  describe "DELETE /administrators/log_out" do
    test "logs the administrator out", %{conn: conn, administrator: administrator} do
      conn = conn |> log_in_administrator(administrator) |> delete(~p"/administrators/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :administrator_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the administrator is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/administrators/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :administrator_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
