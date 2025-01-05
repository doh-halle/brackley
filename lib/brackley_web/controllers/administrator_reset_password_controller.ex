defmodule BrackleyWeb.AdministratorResetPasswordController do
  use BrackleyWeb, :controller

  alias Brackley.Administration

  plug :get_administrator_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"administrator" => %{"email" => email}}) do
    if administrator = Administration.get_administrator_by_email(email) do
      Administration.deliver_administrator_reset_password_instructions(
        administrator,
        &url(~p"/administrators/reset_password/#{&1}")
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions to reset your password shortly."
    )
    |> redirect(to: ~p"/")
  end

  def edit(conn, _params) do
    render(conn, :edit, changeset: Administration.change_administrator_password(conn.assigns.administrator))
  end

  # Do not log in the administrator after reset password to avoid a
  # leaked token giving the administrator access to the account.
  def update(conn, %{"administrator" => administrator_params}) do
    case Administration.reset_administrator_password(conn.assigns.administrator, administrator_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password reset successfully.")
        |> redirect(to: ~p"/administrators/log_in")

      {:error, changeset} ->
        render(conn, :edit, changeset: changeset)
    end
  end

  defp get_administrator_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if administrator = Administration.get_administrator_by_reset_password_token(token) do
      conn |> assign(:administrator, administrator) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end
end
