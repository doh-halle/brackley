defmodule BrackleyWeb.Router do
  use BrackleyWeb, :router

  import BrackleyWeb.UserAuth

  import BrackleyWeb.AdministratorAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BrackleyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :fetch_current_administrator
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BrackleyWeb do
    pipe_through :browser

    get "/", PageController, :index

    # # Categories
    # resources "/categories", CategoryController, only: [:index, :show]
    # # get "/categories", CategoryController, :index
    # # get "/categories/:id", CategoryController, :show

    # # # Reviews
    # resources "/reviews", ReviewController, only: [:index, :show]
    # get "/reviews", ReviewController, :index
    # get "/reviews/:id", ReviewController, :show

    # # # Restaurants
    # resources "/restaurants", RestaurantController, only: [:index, :show]
    # # get "/restaurants", RestaurantController, :index
    # # get "/restaurants/:id", RestaurantController, :show

    # # # Meals
    # resources "/meals", MealController, only: [:index, :show]
    # # get "/meals", MealController, :index
    # # get "/meals/:id", MealController, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", BrackleyWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:brackley, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BrackleyWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", BrackleyWeb do
    pipe_through [:browser, :redirect_if_administrator_is_authenticated]

    get "/administrators/register", AdministratorRegistrationController, :new
    post "/administrators/register", AdministratorRegistrationController, :create
    get "/administrators/log_in", AdministratorSessionController, :new
    post "/administrators/log_in", AdministratorSessionController, :create
    get "/administrators/reset_password", AdministratorResetPasswordController, :new
    post "/administrators/reset_password", AdministratorResetPasswordController, :create
    get "/administrators/reset_password/:token", AdministratorResetPasswordController, :edit
    put "/administrators/reset_password/:token", AdministratorResetPasswordController, :update
  end

  scope "/", BrackleyWeb do
    pipe_through [:browser, :require_authenticated_administrator]

    get "/administrators/settings", AdministratorSettingsController, :edit
    put "/administrators/settings", AdministratorSettingsController, :update

    get "/administrators/settings/confirm_email/:token",
        AdministratorSettingsController,
        :confirm_email

    # Categories
    resources "/categories", CategoryController
    # resources "/categories", CategoryController, only: [:new, :create, :edit, :update, :delete]

    # get "/categories/new", CategoryController, :new
    # post "/categories", CategoryController, :create
    # get "/categories/:id", CategoryController, :show
    # get "/categories/:id/edit", CategoryController, :edit
    # put "/categories/:id", CategoryController, :update
    # patch "/categories/:id", CategoryController, :update
    # delete "/categories/:id", CategoryController, :delete

    # Restaurants
    resources "/restaurants", RestaurantController

    # resources "/restaurants", RestaurantController, only: [:new, :create, :edit, :update, :delete]

    # get "/restaurants/new", RestaurantController, :new
    # post "/restaurants", RestaurantController, :create
    # get "/restaurants/:id", RestaurantController, :show
    # get "/restaurants/:id/edit", RestaurantController, :edit
    # put "/restaurants/:id", RestaurantController, :update
    # patch "/restaurants/:id", RestaurantController, :update
    # delete "/restaurants/:id", RestaurantController, :delete

    # Meals
    resources "/meals", MealController

    # resources "/meals", MealController, only: [:new, :create, :edit, :update, :delete]

    # get "/meals/new", MealController, :new
    # post "/meals", MealController, :create
    # get "/meals/:id", MealController, :show
    # get "/meals/:id/edit", MealController, :edit
    # put "/meals/:id", MealController, :update
    # patch "/meals/:id", MealController, :update
    # delete "/meals/:id", MealController, :delete
  end

  scope "/", BrackleyWeb do
    pipe_through [:browser]

    delete "/administrators/log_out", AdministratorSessionController, :delete
    get "/administrators/confirm", AdministratorConfirmationController, :new
    post "/administrators/confirm", AdministratorConfirmationController, :create
    get "/administrators/confirm/:token", AdministratorConfirmationController, :edit
    post "/administrators/confirm/:token", AdministratorConfirmationController, :update
  end

  ## Authentication routes

  scope "/", BrackleyWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", BrackleyWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    # Reviews
    resources "/reviews", ReviewController
    # resources "/reviews", ReviewController, only: [:new, :create, :edit, :update, :delete]

    # get "/reviews/new", ReviewController, :new
    # post "/reviews", ReviewController, :create
    # get "/reviews/:id", ReviewController, :show
    # get "/reviews/:id/edit", ReviewController, :edit
    # put "/reviews/:id", ReviewController, :update
    # patch "/reviews/:id", ReviewController, :update
    # delete "/reviews/:id", ReviewController, :delete

    # Comments
    resources "/comments", CommentController
  end

  scope "/", BrackleyWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end
end
