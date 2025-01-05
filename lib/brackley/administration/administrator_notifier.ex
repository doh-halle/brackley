defmodule Brackley.Administration.AdministratorNotifier do
  import Swoosh.Email

  alias Brackley.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Brackley", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(administrator, url) do
    deliver(administrator.email, "Confirmation instructions", """

    ==============================

    Hi #{administrator.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a administrator password.
  """
  def deliver_reset_password_instructions(administrator, url) do
    deliver(administrator.email, "Reset password instructions", """

    ==============================

    Hi #{administrator.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a administrator email.
  """
  def deliver_update_email_instructions(administrator, url) do
    deliver(administrator.email, "Update email instructions", """

    ==============================

    Hi #{administrator.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
