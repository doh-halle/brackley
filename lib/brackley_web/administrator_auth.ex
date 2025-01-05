defmodule BrackleyWeb.AdministratorAuth do
  use BrackleyWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Brackley.Administration

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in AdministratorToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_brackley_web_administrator_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the administrator in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_administrator(conn, administrator, params \\ %{}) do
    token = Administration.generate_administrator_session_token(administrator)
    administrator_return_to = get_session(conn, :administrator_return_to)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: administrator_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the administrator out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_administrator(conn) do
    administrator_token = get_session(conn, :administrator_token)
    administrator_token && Administration.delete_administrator_session_token(administrator_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      BrackleyWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the administrator by looking into the session
  and remember me token.
  """
  def fetch_current_administrator(conn, _opts) do
    {administrator_token, conn} = ensure_administrator_token(conn)
    administrator = administrator_token && Administration.get_administrator_by_session_token(administrator_token)
    assign(conn, :current_administrator, administrator)
  end

  defp ensure_administrator_token(conn) do
    if token = get_session(conn, :administrator_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Handles mounting and authenticating the current_administrator in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_administrator` - Assigns current_administrator
      to socket assigns based on administrator_token, or nil if
      there's no administrator_token or no matching administrator.

    * `:ensure_authenticated` - Authenticates the administrator from the session,
      and assigns the current_administrator to socket assigns based
      on administrator_token.
      Redirects to login page if there's no logged administrator.

    * `:redirect_if_administrator_is_authenticated` - Authenticates the administrator from the session.
      Redirects to signed_in_path if there's a logged administrator.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_administrator:

      defmodule BrackleyWeb.PageLive do
        use BrackleyWeb, :live_view

        on_mount {BrackleyWeb.AdministratorAuth, :mount_current_administrator}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{BrackleyWeb.AdministratorAuth, :ensure_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  def on_mount(:mount_current_administrator, _params, session, socket) do
    {:cont, mount_current_administrator(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_administrator(socket, session)

    if socket.assigns.current_administrator do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/administrators/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_administrator_is_authenticated, _params, session, socket) do
    socket = mount_current_administrator(socket, session)

    if socket.assigns.current_administrator do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_administrator(socket, session) do
    Phoenix.Component.assign_new(socket, :current_administrator, fn ->
      if administrator_token = session["administrator_token"] do
        Administration.get_administrator_by_session_token(administrator_token)
      end
    end)
  end

  @doc """
  Used for routes that require the administrator to not be authenticated.
  """
  def redirect_if_administrator_is_authenticated(conn, _opts) do
    if conn.assigns[:current_administrator] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the administrator to be authenticated.

  If you want to enforce the administrator email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_administrator(conn, _opts) do
    if conn.assigns[:current_administrator] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/administrators/log_in")
      |> halt()
    end
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:administrator_token, token)
    |> put_session(:live_socket_id, "administrators_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :administrator_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/"
end
