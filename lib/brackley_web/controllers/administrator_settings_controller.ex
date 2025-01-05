defmodule BrackleyWeb.AdministratorSettingsController do
  use BrackleyWeb, :controller

  alias Brackley.Administration
  alias BrackleyWeb.AdministratorAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, :edit)
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "administrator" => administrator_params} = params
    administrator = conn.assigns.current_administrator

    case Administration.apply_administrator_email(administrator, password, administrator_params) do
      {:ok, applied_administrator} ->
        Administration.deliver_administrator_update_email_instructions(
          applied_administrator,
          administrator.email,
          &url(~p"/administrators/settings/confirm_email/#{&1}")
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: ~p"/administrators/settings")

      {:error, changeset} ->
        render(conn, :edit, email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "administrator" => administrator_params} = params
    administrator = conn.assigns.current_administrator

    case Administration.update_administrator_password(administrator, password, administrator_params) do
      {:ok, administrator} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:administrator_return_to, ~p"/administrators/settings")
        |> AdministratorAuth.log_in_administrator(administrator)

      {:error, changeset} ->
        render(conn, :edit, password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Administration.update_administrator_email(conn.assigns.current_administrator, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: ~p"/administrators/settings")

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: ~p"/administrators/settings")
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    administrator = conn.assigns.current_administrator

    conn
    |> assign(:email_changeset, Administration.change_administrator_email(administrator))
    |> assign(:password_changeset, Administration.change_administrator_password(administrator))
  end
end
