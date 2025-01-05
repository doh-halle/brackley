defmodule BrackleyWeb.AdministratorConfirmationControllerTest do
  use BrackleyWeb.ConnCase, async: true

  alias Brackley.Administration
  alias Brackley.Repo
  import Brackley.AdministrationFixtures

  setup do
    %{administrator: administrator_fixture()}
  end

  describe "GET /administrators/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, ~p"/administrators/confirm")
      response = html_response(conn, 200)
      assert response =~ "Resend confirmation instructions"
    end
  end

  describe "POST /administrators/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, administrator: administrator} do
      conn =
        post(conn, ~p"/administrators/confirm", %{
          "administrator" => %{"email" => administrator.email}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Administration.AdministratorToken, administrator_id: administrator.id).context == "confirm"
    end

    test "does not send confirmation token if Administrator is confirmed", %{conn: conn, administrator: administrator} do
      Repo.update!(Administration.Administrator.confirm_changeset(administrator))

      conn =
        post(conn, ~p"/administrators/confirm", %{
          "administrator" => %{"email" => administrator.email}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Administration.AdministratorToken, administrator_id: administrator.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/administrators/confirm", %{
          "administrator" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Administration.AdministratorToken) == []
    end
  end

  describe "GET /administrators/confirm/:token" do
    test "renders the confirmation page", %{conn: conn} do
      token_path = ~p"/administrators/confirm/some-token"
      conn = get(conn, token_path)
      response = html_response(conn, 200)
      assert response =~ "Confirm account"

      assert response =~ "action=\"#{token_path}\""
    end
  end

  describe "POST /administrators/confirm/:token" do
    test "confirms the given token once", %{conn: conn, administrator: administrator} do
      token =
        extract_administrator_token(fn url ->
          Administration.deliver_administrator_confirmation_instructions(administrator, url)
        end)

      conn = post(conn, ~p"/administrators/confirm/#{token}")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Administrator confirmed successfully"

      assert Administration.get_administrator!(administrator.id).confirmed_at
      refute get_session(conn, :administrator_token)
      assert Repo.all(Administration.AdministratorToken) == []

      # When not logged in
      conn = post(conn, ~p"/administrators/confirm/#{token}")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Administrator confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_administrator(administrator)
        |> post(~p"/administrators/confirm/#{token}")

      assert redirected_to(conn) == ~p"/"
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, administrator: administrator} do
      conn = post(conn, ~p"/administrators/confirm/oops")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Administrator confirmation link is invalid or it has expired"

      refute Administration.get_administrator!(administrator.id).confirmed_at
    end
  end
end
