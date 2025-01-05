defmodule BrackleyWeb.AdministratorSessionController do
  use BrackleyWeb, :controller

  alias Brackley.Administration
  alias BrackleyWeb.AdministratorAuth

  def new(conn, _params) do
    render(conn, :new, error_message: nil)
  end

  def create(conn, %{"administrator" => administrator_params}) do
    %{"email" => email, "password" => password} = administrator_params

    if administrator = Administration.get_administrator_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> AdministratorAuth.log_in_administrator(administrator, administrator_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, :new, error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> AdministratorAuth.log_out_administrator()
  end
end
