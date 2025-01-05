defmodule BrackleyWeb.AdministratorConfirmationController do
  use BrackleyWeb, :controller

  alias Brackley.Administration

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"administrator" => %{"email" => email}}) do
    if administrator = Administration.get_administrator_by_email(email) do
      Administration.deliver_administrator_confirmation_instructions(
        administrator,
        &url(~p"/administrators/confirm/#{&1}")
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system and it has not been confirmed yet, " <>
        "you will receive an email with instructions shortly."
    )
    |> redirect(to: ~p"/")
  end

  def edit(conn, %{"token" => token}) do
    render(conn, :edit, token: token)
  end

  # Do not log in the administrator after confirmation to avoid a
  # leaked token giving the administrator access to the account.
  def update(conn, %{"token" => token}) do
    case Administration.confirm_administrator(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Administrator confirmed successfully.")
        |> redirect(to: ~p"/")

      :error ->
        # If there is a current administrator and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the administrator themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_administrator: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: ~p"/")

          %{} ->
            conn
            |> put_flash(:error, "Administrator confirmation link is invalid or it has expired.")
            |> redirect(to: ~p"/")
        end
    end
  end
end
