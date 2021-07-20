defmodule Getatrex.Message do
  @moduledoc """

  Represents .PO file rows like this:

    #: web/templates/private_page/dashboard.html.eex:53
    #: web/templates/shop/edit.html.eex:7 web/templates/shop/show.html.eex:32
    msgid "Edit"
    msgstr ""

  where comments (lines starts with `#:`) will go to `mentions`,
  msgid and msgstr - to corresponding keys
  """
  defstruct mentions: [], 
            msgid: nil, 
            msgid_plural: nil, 
            msgstr: nil, 
            msgstr0: nil, 
            msgstr1: nil, 
            msgstr2: nil, 
            msgstr3: nil, 
            msgstr4: nil, 
            msgstr5: nil, 
            to_lang: nil, 
            request_mode: nil, 
            api_key: nil
  @type t :: %__MODULE__{
            mentions: Enum.t, 
            msgid: String.t, 
            msgid_plural: String.t, 
            msgstr: String.t, 
            msgstr0: String.t, 
            msgstr1: String.t, 
            msgstr2: String.t, 
            msgstr3: String.t, 
            msgstr4: String.t, 
            msgstr5: String.t, 
            to_lang: String.t, 
            request_mode: Atom.t, 
            api_key: String.t
          }
end
