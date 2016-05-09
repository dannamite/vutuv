defmodule Vutuv.EmailController do
  use Vutuv.Web, :controller
  plug :assign_user

  alias Vutuv.Email

  plug :scrub_params, "email" when action in [:create, :update]

  def index(conn, _params) do
    emails = Repo.all(assoc(conn.assigns[:user], :emails))
    render(conn, "index.html", emails: emails)
  end

  def new(conn, _params) do
    changeset =
      conn.assigns[:user]
      |> build_assoc(:emails)
      |> Email.changeset()
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"email" => email_params}) do
    changeset =
      conn.assigns[:user]
      |> build_assoc(:emails)
      |> Email.changeset(email_params)

    case Repo.insert(changeset) do
      {:ok, _email} ->
        conn
        |> put_flash(:info, "Email created successfully.")
        |> redirect(to: user_email_path(conn, :index, conn.assigns[:user]))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    email = Repo.get!(assoc(conn.assigns[:user], :emails), id)
    render(conn, "show.html", email: email)
  end

  def edit(conn, %{"id" => id}) do
    email = Repo.get!(assoc(conn.assigns[:user], :emails), id)
    changeset = Email.changeset(email)
    render(conn, "edit.html", email: email, changeset: changeset)
  end

  def update(conn, %{"id" => id, "email" => email_params}) do
    email = Repo.get!(assoc(conn.assigns[:user], :emails), id)
    changeset = Email.changeset(email, email_params)
    case Repo.update(changeset) do
      {:ok, email} ->
        conn
        |> put_flash(:info, "Email updated successfully.")
        |> redirect(to: user_email_path(conn, :show, conn.assigns[:user], email))
      {:error, changeset} ->
        render(conn, "edit.html", email: email, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    email = Repo.get!(assoc(conn.assigns[:user], :emails), id)
    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(email)
    conn
    |> put_flash(:info, "Email deleted successfully.")
    |> redirect(to: user_email_path(conn, :index, conn.assigns[:user]))
  end

  defp assign_user(conn, _opts) do
    case conn.params do
      %{"user_id" => user_id} ->
        case Repo.get(Vutuv.User, user_id) do
          nil  -> invalid_user(conn)
          user -> assign(conn, :user, user)
        end
      _ -> invalid_user(conn)
    end
  end

  defp invalid_user(conn) do
    conn
    |> put_flash(:error, "Invalid user!")
    |> redirect(to: page_path(conn, :index))
    |> halt
  end
end