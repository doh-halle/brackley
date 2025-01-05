defmodule BrackleyWeb.AdministratorResetPasswordControllerTest do
  use BrackleyWeb.ConnCase, async: true

  alias Brackley.Administration
  alias Brackley.Repo
  import Brackley.AdministrationFixtures

  setup do
    %{administrator: administrator_fixture()}
  end

  describe "GET /administrators/reset_password" do
    test "renders the reset password page", %{conn: conn} do
      conn = get(conn, ~p"/administrators/reset_password")
      response = html_response(conn, 200)
      assert response =~ "Forgot your password?"
    end
  end

  describe "POST /administrators/reset_password" do
    @tag :capture_log
    test "sends a new reset password token", %{conn: conn, administrator: administrator} do
      conn =
        post(conn, ~p"/administrators/reset_password", %{
          "administrator" => %{"email" => administrator.email}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Administration.AdministratorToken, administrator_id: administrator.id).context == "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/administrators/reset_password", %{
          "administrator" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Administration.AdministratorToken) == []
    end
  end

  describe "GET /administrators/reset_password/:token" do
    setup %{administrator: administrator} do
      token =
        extract_administrator_token(fn url ->
          Administration.deliver_administrator_reset_password_instructions(administrator, url)
        end)

      %{token: token}
    end

    test "renders reset password", %{conn: conn, token: token} do
      conn = get(conn, ~p"/administrators/reset_password/#{token}")
      assert html_response(conn, 200) =~ "Reset password"
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      conn = get(conn, ~p"/administrators/reset_password/oops")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Reset password link is invalid or it has expired"
    end
  end

  describe "PUT /administrators/reset_password/:token" do
    setup %{administrator: administrator} do
      token =
        extract_administrator_token(fn url ->
          Administration.deliver_administrator_reset_password_instructions(administrator, url)
        end)

      %{token: token}
    end

    test "resets password once", %{conn: conn, administrator: administrator, token: token} do
      conn =
        put(conn, ~p"/administrators/reset_password/#{token}", %{
          "administrator" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(conn) == ~p"/administrators/log_in"
      refute get_session(conn, :administrator_token)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Password reset successfully"

      assert Administration.get_administrator_by_email_and_password(administrator.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      conn =
        put(conn, ~p"/administrators/reset_password/#{token}", %{
          "administrator" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert html_response(conn, 200) =~ "something went wrong"
    end

    test "does not reset password with invalid token", %{conn: conn} do
      conn = put(conn, ~p"/administrators/reset_password/oops")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Reset password link is invalid or it has expired"
    end
  end
end
