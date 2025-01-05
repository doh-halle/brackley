defmodule BrackleyWeb.UserRegistrationController do
  use BrackleyWeb, :controller

  alias Brackley.Account
  alias Brackley.Account.User
  alias BrackleyWeb.UserAuth

  def new(conn, _params) do
    changeset = Account.change_user_registration(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Account.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Account.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
