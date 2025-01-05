defmodule Brackley.AdministrationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Brackley.Administration` context.
  """

  def unique_administrator_email, do: "administrator#{System.unique_integer()}@example.com"
  def valid_administrator_password, do: "hello world!"

  def valid_administrator_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_administrator_email(),
      password: valid_administrator_password()
    })
  end

  def administrator_fixture(attrs \\ %{}) do
    {:ok, administrator} =
      attrs
      |> valid_administrator_attributes()
      |> Brackley.Administration.register_administrator()

    administrator
  end

  def extract_administrator_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @doc """
  Generate a category.
  """
  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        category_slug: "some category_slug",
        description: "some description",
        image_url: "some image_url",
        title: "some title"
      })
      |> Brackley.Administration.create_category()

    category
  end

  @doc """
  Generate a restaurant.
  """
  def restaurant_fixture(attrs \\ %{}) do
    {:ok, restaurant} =
      attrs
      |> Enum.into(%{
        address: "some address",
        description: "some description",
        image_url: "some image_url",
        name: "some name",
        phone_number: "some phone_number"
      })
      |> Brackley.Administration.create_restaurant()

    restaurant
  end

  @doc """
  Generate a meal.
  """
  def meal_fixture(attrs \\ %{}) do
    {:ok, meal} =
      attrs
      |> Enum.into(%{
        description: "some description",
        image_url: "some image_url",
        name: "some name",
        price: 42
      })
      |> Brackley.Administration.create_meal()

    meal
  end
end
