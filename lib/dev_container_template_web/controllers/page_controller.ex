defmodule DevContainerTemplateWeb.PageController do
  use DevContainerTemplateWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
