defmodule BrackleyWeb.AdministratorRegistrationController do
  use BrackleyWeb, :controller

  alias Brackley.Administration
  alias Brackley.Administration.Administrator
  alias BrackleyWeb.AdministratorAuth

  def new(conn, _params) do
    changeset = Administration.change_administrator_registration(%Administrator{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"administrator" => administrator_params}) do
    case Administration.register_administrator(administrator_params) do
      {:ok, administrator} ->
        {:ok, _} =
          Administration.deliver_administrator_confirmation_instructions(
            administrator,
            &url(~p"/administrators/confirm/#{&1}")
          )

        conn
        |> put_flash(:info, "Administrator created successfully.")
        |> AdministratorAuth.log_in_administrator(administrator)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
