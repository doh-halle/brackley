defmodule Brackley.AdministrationTest do
  use Brackley.DataCase

  alias Brackley.Administration

  import Brackley.AdministrationFixtures
  alias Brackley.Administration.{Administrator, AdministratorToken}

  describe "get_administrator_by_email/1" do
    test "does not return the administrator if the email does not exist" do
      refute Administration.get_administrator_by_email("unknown@example.com")
    end

    test "returns the administrator if the email exists" do
      %{id: id} = administrator = administrator_fixture()
      assert %Administrator{id: ^id} = Administration.get_administrator_by_email(administrator.email)
    end
  end

  describe "get_administrator_by_email_and_password/2" do
    test "does not return the administrator if the email does not exist" do
      refute Administration.get_administrator_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the administrator if the password is not valid" do
      administrator = administrator_fixture()
      refute Administration.get_administrator_by_email_and_password(administrator.email, "invalid")
    end

    test "returns the administrator if the email and password are valid" do
      %{id: id} = administrator = administrator_fixture()

      assert %Administrator{id: ^id} =
               Administration.get_administrator_by_email_and_password(administrator.email, valid_administrator_password())
    end
  end

  describe "get_administrator!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Administration.get_administrator!(-1)
      end
    end

    test "returns the administrator with the given id" do
      %{id: id} = administrator = administrator_fixture()
      assert %Administrator{id: ^id} = Administration.get_administrator!(administrator.id)
    end
  end

  describe "register_administrator/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Administration.register_administrator(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Administration.register_administrator(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Administration.register_administrator(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = administrator_fixture()
      {:error, changeset} = Administration.register_administrator(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Administration.register_administrator(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers administrators with a hashed password" do
      email = unique_administrator_email()
      {:ok, administrator} = Administration.register_administrator(valid_administrator_attributes(email: email))
      assert administrator.email == email
      assert is_binary(administrator.hashed_password)
      assert is_nil(administrator.confirmed_at)
      assert is_nil(administrator.password)
    end
  end

  describe "change_administrator_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Administration.change_administrator_registration(%Administrator{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_administrator_email()
      password = valid_administrator_password()

      changeset =
        Administration.change_administrator_registration(
          %Administrator{},
          valid_administrator_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_administrator_email/2" do
    test "returns a administrator changeset" do
      assert %Ecto.Changeset{} = changeset = Administration.change_administrator_email(%Administrator{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_administrator_email/3" do
    setup do
      %{administrator: administrator_fixture()}
    end

    test "requires email to change", %{administrator: administrator} do
      {:error, changeset} = Administration.apply_administrator_email(administrator, valid_administrator_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{administrator: administrator} do
      {:error, changeset} =
        Administration.apply_administrator_email(administrator, valid_administrator_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{administrator: administrator} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Administration.apply_administrator_email(administrator, valid_administrator_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{administrator: administrator} do
      %{email: email} = administrator_fixture()
      password = valid_administrator_password()

      {:error, changeset} = Administration.apply_administrator_email(administrator, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{administrator: administrator} do
      {:error, changeset} =
        Administration.apply_administrator_email(administrator, "invalid", %{email: unique_administrator_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{administrator: administrator} do
      email = unique_administrator_email()
      {:ok, administrator} = Administration.apply_administrator_email(administrator, valid_administrator_password(), %{email: email})
      assert administrator.email == email
      assert Administration.get_administrator!(administrator.id).email != email
    end
  end

  describe "deliver_administrator_update_email_instructions/3" do
    setup do
      %{administrator: administrator_fixture()}
    end

    test "sends token through notification", %{administrator: administrator} do
      token =
        extract_administrator_token(fn url ->
          Administration.deliver_administrator_update_email_instructions(administrator, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert administrator_token = Repo.get_by(AdministratorToken, token: :crypto.hash(:sha256, token))
      assert administrator_token.administrator_id == administrator.id
      assert administrator_token.sent_to == administrator.email
      assert administrator_token.context == "change:current@example.com"
    end
  end

  describe "update_administrator_email/2" do
    setup do
      administrator = administrator_fixture()
      email = unique_administrator_email()

      token =
        extract_administrator_token(fn url ->
          Administration.deliver_administrator_update_email_instructions(%{administrator | email: email}, administrator.email, url)
        end)

      %{administrator: administrator, token: token, email: email}
    end

    test "updates the email with a valid token", %{administrator: administrator, token: token, email: email} do
      assert Administration.update_administrator_email(administrator, token) == :ok
      changed_administrator = Repo.get!(Administrator, administrator.id)
      assert changed_administrator.email != administrator.email
      assert changed_administrator.email == email
      assert changed_administrator.confirmed_at
      assert changed_administrator.confirmed_at != administrator.confirmed_at
      refute Repo.get_by(AdministratorToken, administrator_id: administrator.id)
    end

    test "does not update email with invalid token", %{administrator: administrator} do
      assert Administration.update_administrator_email(administrator, "oops") == :error
      assert Repo.get!(Administrator, administrator.id).email == administrator.email
      assert Repo.get_by(AdministratorToken, administrator_id: administrator.id)
    end

    test "does not update email if administrator email changed", %{administrator: administrator, token: token} do
      assert Administration.update_administrator_email(%{administrator | email: "current@example.com"}, token) == :error
      assert Repo.get!(Administrator, administrator.id).email == administrator.email
      assert Repo.get_by(AdministratorToken, administrator_id: administrator.id)
    end

    test "does not update email if token expired", %{administrator: administrator, token: token} do
      {1, nil} = Repo.update_all(AdministratorToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Administration.update_administrator_email(administrator, token) == :error
      assert Repo.get!(Administrator, administrator.id).email == administrator.email
      assert Repo.get_by(AdministratorToken, administrator_id: administrator.id)
    end
  end

  describe "change_administrator_password/2" do
    test "returns a administrator changeset" do
      assert %Ecto.Changeset{} = changeset = Administration.change_administrator_password(%Administrator{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Administration.change_administrator_password(%Administrator{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_administrator_password/3" do
    setup do
      %{administrator: administrator_fixture()}
    end

    test "validates password", %{administrator: administrator} do
      {:error, changeset} =
        Administration.update_administrator_password(administrator, valid_administrator_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{administrator: administrator} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Administration.update_administrator_password(administrator, valid_administrator_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{administrator: administrator} do
      {:error, changeset} =
        Administration.update_administrator_password(administrator, "invalid", %{password: valid_administrator_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{administrator: administrator} do
      {:ok, administrator} =
        Administration.update_administrator_password(administrator, valid_administrator_password(), %{
          password: "new valid password"
        })

      assert is_nil(administrator.password)
      assert Administration.get_administrator_by_email_and_password(administrator.email, "new valid password")
    end

    test "deletes all tokens for the given administrator", %{administrator: administrator} do
      _ = Administration.generate_administrator_session_token(administrator)

      {:ok, _} =
        Administration.update_administrator_password(administrator, valid_administrator_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(AdministratorToken, administrator_id: administrator.id)
    end
  end

  describe "generate_administrator_session_token/1" do
    setup do
      %{administrator: administrator_fixture()}
    end

    test "generates a token", %{administrator: administrator} do
      token = Administration.generate_administrator_session_token(administrator)
      assert administrator_token = Repo.get_by(AdministratorToken, token: token)
      assert administrator_token.context == "session"

      # Creating the same token for another administrator should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%AdministratorToken{
          token: administrator_token.token,
          administrator_id: administrator_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_administrator_by_session_token/1" do
    setup do
      administrator = administrator_fixture()
      token = Administration.generate_administrator_session_token(administrator)
      %{administrator: administrator, token: token}
    end

    test "returns administrator by token", %{administrator: administrator, token: token} do
      assert session_administrator = Administration.get_administrator_by_session_token(token)
      assert session_administrator.id == administrator.id
    end

    test "does not return administrator for invalid token" do
      refute Administration.get_administrator_by_session_token("oops")
    end

    test "does not return administrator for expired token", %{token: token} do
      {1, nil} = Repo.update_all(AdministratorToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Administration.get_administrator_by_session_token(token)
    end
  end

  describe "delete_administrator_session_token/1" do
    test "deletes the token" do
      administrator = administrator_fixture()
      token = Administration.generate_administrator_session_token(administrator)
      assert Administration.delete_administrator_session_token(token) == :ok
      refute Administration.get_administrator_by_session_token(token)
    end
  end

  describe "deliver_administrator_confirmation_instructions/2" do
    setup do
      %{administrator: administrator_fixture()}
    end

    test "sends token through notification", %{administrator: administrator} do
      token =
        extract_administrator_token(fn url ->
          Administration.deliver_administrator_confirmation_instructions(administrator, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert administrator_token = Repo.get_by(AdministratorToken, token: :crypto.hash(:sha256, token))
      assert administrator_token.administrator_id == administrator.id
      assert administrator_token.sent_to == administrator.email
      assert administrator_token.context == "confirm"
    end
  end

  describe "confirm_administrator/1" do
    setup do
      administrator = administrator_fixture()

      token =
        extract_administrator_token(fn url ->
          Administration.deliver_administrator_confirmation_instructions(administrator, url)
        end)

      %{administrator: administrator, token: token}
    end

    test "confirms the email with a valid token", %{administrator: administrator, token: token} do
      assert {:ok, confirmed_administrator} = Administration.confirm_administrator(token)
      assert confirmed_administrator.confirmed_at
      assert confirmed_administrator.confirmed_at != administrator.confirmed_at
      assert Repo.get!(Administrator, administrator.id).confirmed_at
      refute Repo.get_by(AdministratorToken, administrator_id: administrator.id)
    end

    test "does not confirm with invalid token", %{administrator: administrator} do
      assert Administration.confirm_administrator("oops") == :error
      refute Repo.get!(Administrator, administrator.id).confirmed_at
      assert Repo.get_by(AdministratorToken, administrator_id: administrator.id)
    end

    test "does not confirm email if token expired", %{administrator: administrator, token: token} do
      {1, nil} = Repo.update_all(AdministratorToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Administration.confirm_administrator(token) == :error
      refute Repo.get!(Administrator, administrator.id).confirmed_at
      assert Repo.get_by(AdministratorToken, administrator_id: administrator.id)
    end
  end

  describe "deliver_administrator_reset_password_instructions/2" do
    setup do
      %{administrator: administrator_fixture()}
    end

    test "sends token through notification", %{administrator: administrator} do
      token =
        extract_administrator_token(fn url ->
          Administration.deliver_administrator_reset_password_instructions(administrator, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert administrator_token = Repo.get_by(AdministratorToken, token: :crypto.hash(:sha256, token))
      assert administrator_token.administrator_id == administrator.id
      assert administrator_token.sent_to == administrator.email
      assert administrator_token.context == "reset_password"
    end
  end

  describe "get_administrator_by_reset_password_token/1" do
    setup do
      administrator = administrator_fixture()

      token =
        extract_administrator_token(fn url ->
          Administration.deliver_administrator_reset_password_instructions(administrator, url)
        end)

      %{administrator: administrator, token: token}
    end

    test "returns the administrator with valid token", %{administrator: %{id: id}, token: token} do
      assert %Administrator{id: ^id} = Administration.get_administrator_by_reset_password_token(token)
      assert Repo.get_by(AdministratorToken, administrator_id: id)
    end

    test "does not return the administrator with invalid token", %{administrator: administrator} do
      refute Administration.get_administrator_by_reset_password_token("oops")
      assert Repo.get_by(AdministratorToken, administrator_id: administrator.id)
    end

    test "does not return the administrator if token expired", %{administrator: administrator, token: token} do
      {1, nil} = Repo.update_all(AdministratorToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Administration.get_administrator_by_reset_password_token(token)
      assert Repo.get_by(AdministratorToken, administrator_id: administrator.id)
    end
  end

  describe "reset_administrator_password/2" do
    setup do
      %{administrator: administrator_fixture()}
    end

    test "validates password", %{administrator: administrator} do
      {:error, changeset} =
        Administration.reset_administrator_password(administrator, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{administrator: administrator} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Administration.reset_administrator_password(administrator, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{administrator: administrator} do
      {:ok, updated_administrator} = Administration.reset_administrator_password(administrator, %{password: "new valid password"})
      assert is_nil(updated_administrator.password)
      assert Administration.get_administrator_by_email_and_password(administrator.email, "new valid password")
    end

    test "deletes all tokens for the given administrator", %{administrator: administrator} do
      _ = Administration.generate_administrator_session_token(administrator)
      {:ok, _} = Administration.reset_administrator_password(administrator, %{password: "new valid password"})
      refute Repo.get_by(AdministratorToken, administrator_id: administrator.id)
    end
  end

  describe "inspect/2 for the Administrator module" do
    test "does not include password" do
      refute inspect(%Administrator{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "categories" do
    alias Brackley.Administration.Category

    import Brackley.AdministrationFixtures

    @invalid_attrs %{description: nil, title: nil, category_slug: nil, image_url: nil}

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert Administration.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert Administration.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      valid_attrs = %{description: "some description", title: "some title", category_slug: "some category_slug", image_url: "some image_url"}

      assert {:ok, %Category{} = category} = Administration.create_category(valid_attrs)
      assert category.description == "some description"
      assert category.title == "some title"
      assert category.category_slug == "some category_slug"
      assert category.image_url == "some image_url"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Administration.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title", category_slug: "some updated category_slug", image_url: "some updated image_url"}

      assert {:ok, %Category{} = category} = Administration.update_category(category, update_attrs)
      assert category.description == "some updated description"
      assert category.title == "some updated title"
      assert category.category_slug == "some updated category_slug"
      assert category.image_url == "some updated image_url"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Administration.update_category(category, @invalid_attrs)
      assert category == Administration.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Administration.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Administration.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Administration.change_category(category)
    end
  end

  describe "restaurants" do
    alias Brackley.Administration.Restaurant

    import Brackley.AdministrationFixtures

    @invalid_attrs %{name: nil, address: nil, description: nil, image_url: nil, phone_number: nil}

    test "list_restaurants/0 returns all restaurants" do
      restaurant = restaurant_fixture()
      assert Administration.list_restaurants() == [restaurant]
    end

    test "get_restaurant!/1 returns the restaurant with given id" do
      restaurant = restaurant_fixture()
      assert Administration.get_restaurant!(restaurant.id) == restaurant
    end

    test "create_restaurant/1 with valid data creates a restaurant" do
      valid_attrs = %{name: "some name", address: "some address", description: "some description", image_url: "some image_url", phone_number: "some phone_number"}

      assert {:ok, %Restaurant{} = restaurant} = Administration.create_restaurant(valid_attrs)
      assert restaurant.name == "some name"
      assert restaurant.address == "some address"
      assert restaurant.description == "some description"
      assert restaurant.image_url == "some image_url"
      assert restaurant.phone_number == "some phone_number"
    end

    test "create_restaurant/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Administration.create_restaurant(@invalid_attrs)
    end

    test "update_restaurant/2 with valid data updates the restaurant" do
      restaurant = restaurant_fixture()
      update_attrs = %{name: "some updated name", address: "some updated address", description: "some updated description", image_url: "some updated image_url", phone_number: "some updated phone_number"}

      assert {:ok, %Restaurant{} = restaurant} = Administration.update_restaurant(restaurant, update_attrs)
      assert restaurant.name == "some updated name"
      assert restaurant.address == "some updated address"
      assert restaurant.description == "some updated description"
      assert restaurant.image_url == "some updated image_url"
      assert restaurant.phone_number == "some updated phone_number"
    end

    test "update_restaurant/2 with invalid data returns error changeset" do
      restaurant = restaurant_fixture()
      assert {:error, %Ecto.Changeset{}} = Administration.update_restaurant(restaurant, @invalid_attrs)
      assert restaurant == Administration.get_restaurant!(restaurant.id)
    end

    test "delete_restaurant/1 deletes the restaurant" do
      restaurant = restaurant_fixture()
      assert {:ok, %Restaurant{}} = Administration.delete_restaurant(restaurant)
      assert_raise Ecto.NoResultsError, fn -> Administration.get_restaurant!(restaurant.id) end
    end

    test "change_restaurant/1 returns a restaurant changeset" do
      restaurant = restaurant_fixture()
      assert %Ecto.Changeset{} = Administration.change_restaurant(restaurant)
    end
  end

  describe "meals" do
    alias Brackley.Administration.Meal

    import Brackley.AdministrationFixtures

    @invalid_attrs %{name: nil, description: nil, image_url: nil, price: nil}

    test "list_meals/0 returns all meals" do
      meal = meal_fixture()
      assert Administration.list_meals() == [meal]
    end

    test "get_meal!/1 returns the meal with given id" do
      meal = meal_fixture()
      assert Administration.get_meal!(meal.id) == meal
    end

    test "create_meal/1 with valid data creates a meal" do
      valid_attrs = %{name: "some name", description: "some description", image_url: "some image_url", price: 42}

      assert {:ok, %Meal{} = meal} = Administration.create_meal(valid_attrs)
      assert meal.name == "some name"
      assert meal.description == "some description"
      assert meal.image_url == "some image_url"
      assert meal.price == 42
    end

    test "create_meal/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Administration.create_meal(@invalid_attrs)
    end

    test "update_meal/2 with valid data updates the meal" do
      meal = meal_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description", image_url: "some updated image_url", price: 43}

      assert {:ok, %Meal{} = meal} = Administration.update_meal(meal, update_attrs)
      assert meal.name == "some updated name"
      assert meal.description == "some updated description"
      assert meal.image_url == "some updated image_url"
      assert meal.price == 43
    end

    test "update_meal/2 with invalid data returns error changeset" do
      meal = meal_fixture()
      assert {:error, %Ecto.Changeset{}} = Administration.update_meal(meal, @invalid_attrs)
      assert meal == Administration.get_meal!(meal.id)
    end

    test "delete_meal/1 deletes the meal" do
      meal = meal_fixture()
      assert {:ok, %Meal{}} = Administration.delete_meal(meal)
      assert_raise Ecto.NoResultsError, fn -> Administration.get_meal!(meal.id) end
    end

    test "change_meal/1 returns a meal changeset" do
      meal = meal_fixture()
      assert %Ecto.Changeset{} = Administration.change_meal(meal)
    end
  end
end
