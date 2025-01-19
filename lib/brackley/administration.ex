defmodule Brackley.Administration do
  @moduledoc """
  The Administration context.
  """

  import Ecto.Query, warn: false
  alias Brackley.Repo

  alias Brackley.Administration.{Administrator, AdministratorToken, AdministratorNotifier}

  ## Database getters

  @doc """
  Gets a administrator by email.

  ## Examples

      iex> get_administrator_by_email("foo@example.com")
      %Administrator{}

      iex> get_administrator_by_email("unknown@example.com")
      nil

  """
  def get_administrator_by_email(email) when is_binary(email) do
    Repo.get_by(Administrator, email: email)
  end

  @doc """
  Gets a administrator by email and password.

  ## Examples

      iex> get_administrator_by_email_and_password("foo@example.com", "correct_password")
      %Administrator{}

      iex> get_administrator_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_administrator_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    administrator = Repo.get_by(Administrator, email: email)
    if Administrator.valid_password?(administrator, password), do: administrator
  end

  @doc """
  Gets a single administrator.

  Raises `Ecto.NoResultsError` if the Administrator does not exist.

  ## Examples

      iex> get_administrator!(123)
      %Administrator{}

      iex> get_administrator!(456)
      ** (Ecto.NoResultsError)

  """
  def get_administrator!(id), do: Repo.get!(Administrator, id)

  ## Administrator registration

  @doc """
  Registers a administrator.

  ## Examples

      iex> register_administrator(%{field: value})
      {:ok, %Administrator{}}

      iex> register_administrator(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_administrator(attrs) do
    %Administrator{}
    |> Administrator.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking administrator changes.

  ## Examples

      iex> change_administrator_registration(administrator)
      %Ecto.Changeset{data: %Administrator{}}

  """
  def change_administrator_registration(%Administrator{} = administrator, attrs \\ %{}) do
    Administrator.registration_changeset(administrator, attrs,
      hash_password: false,
      validate_email: false
    )
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the administrator email.

  ## Examples

      iex> change_administrator_email(administrator)
      %Ecto.Changeset{data: %Administrator{}}

  """
  def change_administrator_email(administrator, attrs \\ %{}) do
    Administrator.email_changeset(administrator, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_administrator_email(administrator, "valid password", %{email: ...})
      {:ok, %Administrator{}}

      iex> apply_administrator_email(administrator, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_administrator_email(administrator, password, attrs) do
    administrator
    |> Administrator.email_changeset(attrs)
    |> Administrator.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the administrator email using the given token.

  If the token matches, the administrator email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_administrator_email(administrator, token) do
    context = "change:#{administrator.email}"

    with {:ok, query} <- AdministratorToken.verify_change_email_token_query(token, context),
         %AdministratorToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(administrator_email_multi(administrator, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp administrator_email_multi(administrator, email, context) do
    changeset =
      administrator
      |> Administrator.email_changeset(%{email: email})
      |> Administrator.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:administrator, changeset)
    |> Ecto.Multi.delete_all(
      :tokens,
      AdministratorToken.by_administrator_and_contexts_query(administrator, [context])
    )
  end

  @doc ~S"""
  Delivers the update email instructions to the given administrator.

  ## Examples

      iex> deliver_administrator_update_email_instructions(administrator, current_email, &url(~p"/administrators/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_administrator_update_email_instructions(
        %Administrator{} = administrator,
        current_email,
        update_email_url_fun
      )
      when is_function(update_email_url_fun, 1) do
    {encoded_token, administrator_token} =
      AdministratorToken.build_email_token(administrator, "change:#{current_email}")

    Repo.insert!(administrator_token)

    AdministratorNotifier.deliver_update_email_instructions(
      administrator,
      update_email_url_fun.(encoded_token)
    )
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the administrator password.

  ## Examples

      iex> change_administrator_password(administrator)
      %Ecto.Changeset{data: %Administrator{}}

  """
  def change_administrator_password(administrator, attrs \\ %{}) do
    Administrator.password_changeset(administrator, attrs, hash_password: false)
  end

  @doc """
  Updates the administrator password.

  ## Examples

      iex> update_administrator_password(administrator, "valid password", %{password: ...})
      {:ok, %Administrator{}}

      iex> update_administrator_password(administrator, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_administrator_password(administrator, password, attrs) do
    changeset =
      administrator
      |> Administrator.password_changeset(attrs)
      |> Administrator.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:administrator, changeset)
    |> Ecto.Multi.delete_all(
      :tokens,
      AdministratorToken.by_administrator_and_contexts_query(administrator, :all)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{administrator: administrator}} -> {:ok, administrator}
      {:error, :administrator, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_administrator_session_token(administrator) do
    {token, administrator_token} = AdministratorToken.build_session_token(administrator)
    Repo.insert!(administrator_token)
    token
  end

  @doc """
  Gets the administrator with the given signed token.
  """
  def get_administrator_by_session_token(token) do
    {:ok, query} = AdministratorToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_administrator_session_token(token) do
    Repo.delete_all(AdministratorToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given administrator.

  ## Examples

      iex> deliver_administrator_confirmation_instructions(administrator, &url(~p"/administrators/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_administrator_confirmation_instructions(confirmed_administrator, &url(~p"/administrators/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_administrator_confirmation_instructions(
        %Administrator{} = administrator,
        confirmation_url_fun
      )
      when is_function(confirmation_url_fun, 1) do
    if administrator.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, administrator_token} =
        AdministratorToken.build_email_token(administrator, "confirm")

      Repo.insert!(administrator_token)

      AdministratorNotifier.deliver_confirmation_instructions(
        administrator,
        confirmation_url_fun.(encoded_token)
      )
    end
  end

  @doc """
  Confirms a administrator by the given token.

  If the token matches, the administrator account is marked as confirmed
  and the token is deleted.
  """
  def confirm_administrator(token) do
    with {:ok, query} <- AdministratorToken.verify_email_token_query(token, "confirm"),
         %Administrator{} = administrator <- Repo.one(query),
         {:ok, %{administrator: administrator}} <-
           Repo.transaction(confirm_administrator_multi(administrator)) do
      {:ok, administrator}
    else
      _ -> :error
    end
  end

  defp confirm_administrator_multi(administrator) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:administrator, Administrator.confirm_changeset(administrator))
    |> Ecto.Multi.delete_all(
      :tokens,
      AdministratorToken.by_administrator_and_contexts_query(administrator, ["confirm"])
    )
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given administrator.

  ## Examples

      iex> deliver_administrator_reset_password_instructions(administrator, &url(~p"/administrators/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_administrator_reset_password_instructions(
        %Administrator{} = administrator,
        reset_password_url_fun
      )
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, administrator_token} =
      AdministratorToken.build_email_token(administrator, "reset_password")

    Repo.insert!(administrator_token)

    AdministratorNotifier.deliver_reset_password_instructions(
      administrator,
      reset_password_url_fun.(encoded_token)
    )
  end

  @doc """
  Gets the administrator by reset password token.

  ## Examples

      iex> get_administrator_by_reset_password_token("validtoken")
      %Administrator{}

      iex> get_administrator_by_reset_password_token("invalidtoken")
      nil

  """
  def get_administrator_by_reset_password_token(token) do
    with {:ok, query} <- AdministratorToken.verify_email_token_query(token, "reset_password"),
         %Administrator{} = administrator <- Repo.one(query) do
      administrator
    else
      _ -> nil
    end
  end

  @doc """
  Resets the administrator password.

  ## Examples

      iex> reset_administrator_password(administrator, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Administrator{}}

      iex> reset_administrator_password(administrator, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_administrator_password(administrator, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:administrator, Administrator.password_changeset(administrator, attrs))
    |> Ecto.Multi.delete_all(
      :tokens,
      AdministratorToken.by_administrator_and_contexts_query(administrator, :all)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{administrator: administrator}} -> {:ok, administrator}
      {:error, :administrator, changeset, _} -> {:error, changeset}
    end
  end

  alias Brackley.Administration.Category

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Repo.all(Category)
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}

      iex> delete_category(category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  alias Brackley.Administration.Restaurant

  @doc """
  Returns the list of restaurants.

  ## Examples

      iex> list_restaurants()
      [%Restaurant{}, ...]

  """
  def list_restaurants do
    Repo.all(Restaurant)
  end

  @doc """
  Returns a list of restaurants for a given category
  """
  def list_restaurants_by_category(category_id) do
    Repo.all(from r in Restaurant, where: r.category_id == ^category_id)
  end

  @doc """
  Gets a single restaurant.

  Raises `Ecto.NoResultsError` if the Restaurant does not exist.

  ## Examples

      iex> get_restaurant!(123)
      %Restaurant{}

      iex> get_restaurant!(456)
      ** (Ecto.NoResultsError)

  """
  def get_restaurant!(id), do: Repo.get!(Restaurant, id)

  @doc """
  Gets a single restaurant by name.

  Raises `Ecto.NoResultsError` if the Restaurant does not exist.

  ## Examples

      iex> get_restaurant_by_name!("name")
      %Restaurant{}

      iex> get_restaurant_by_name!("name")
      ** (Ecto.NoResultsError)

  """

  def search_restaurants(name) do
    Repo.all(from r in Restaurant, where: ilike(r.name, ^"%#{name}%"))
  end

  @doc """
  Creates a restaurant.

  ## Examples

      iex> create_restaurant(%{field: value})
      {:ok, %Restaurant{}}

      iex> create_restaurant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_restaurant(attrs \\ %{}) do
    %Restaurant{}
    |> Restaurant.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a restaurant.

  ## Examples

      iex> update_restaurant(restaurant, %{field: new_value})
      {:ok, %Restaurant{}}

      iex> update_restaurant(restaurant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_restaurant(%Restaurant{} = restaurant, attrs) do
    restaurant
    |> Restaurant.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a restaurant.

  ## Examples

      iex> delete_restaurant(restaurant)
      {:ok, %Restaurant{}}

      iex> delete_restaurant(restaurant)
      {:error, %Ecto.Changeset{}}

  """
  def delete_restaurant(%Restaurant{} = restaurant) do
    Repo.delete(restaurant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking restaurant changes.

  ## Examples

      iex> change_restaurant(restaurant)
      %Ecto.Changeset{data: %Restaurant{}}

  """
  def change_restaurant(%Restaurant{} = restaurant, attrs \\ %{}) do
    Restaurant.changeset(restaurant, attrs)
  end

  alias Brackley.Administration.Meal

  @doc """
  Returns the list of meals.

  ## Examples

      iex> list_meals()
      [%Meal{}, ...]

  """
  def list_meals do
    Repo.all(Meal)
  end

  @doc """
  Gets a single meal.

  Raises `Ecto.NoResultsError` if the Meal does not exist.

  ## Examples

      iex> get_meal!(123)
      %Meal{}

      iex> get_meal!(456)
      ** (Ecto.NoResultsError)

  """
  def get_meal!(id), do: Repo.get!(Meal, id)

  @doc """
  Creates a meal.

  ## Examples

      iex> create_meal(%{field: value})
      {:ok, %Meal{}}

      iex> create_meal(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_meal(attrs \\ %{}) do
    %Meal{}
    |> Meal.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a meal.

  ## Examples

      iex> update_meal(meal, %{field: new_value})
      {:ok, %Meal{}}

      iex> update_meal(meal, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_meal(%Meal{} = meal, attrs) do
    meal
    |> Meal.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a meal.

  ## Examples

      iex> delete_meal(meal)
      {:ok, %Meal{}}

      iex> delete_meal(meal)
      {:error, %Ecto.Changeset{}}

  """
  def delete_meal(%Meal{} = meal) do
    Repo.delete(meal)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking meal changes.

  ## Examples

      iex> change_meal(meal)
      %Ecto.Changeset{data: %Meal{}}

  """
  def change_meal(%Meal{} = meal, attrs \\ %{}) do
    Meal.changeset(meal, attrs)
  end
end
