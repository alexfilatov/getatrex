defmodule Getatrex.Message do
  @moduledoc """

  Represents .PO file rows like this:

    #: web/templates/private_page/dashboard.html.eex:53
    #: web/templates/shop/edit.html.eex:7 web/templates/shop/show.html.eex:32
    msgid "Edit"
    msgstr ""

  where comments (lines starts with `#:`) will go to `mentions`,
  msgid and msgstr - to corresponding keys

  Message can translate itself with Getatrex.Translator.Google.translate_to_locale

  """
  defstruct mentions: [], msgid: "", msgstr: ""
  @type t :: %__MODULE__{mentions: Enum.t, msgid: String.t, msgstr: String.t}

  @spec translate(Getatrex.Message.t) :: Getatrex.Message.t
  def translate(message) do
    %Getatrex.Message{}
  end
end
