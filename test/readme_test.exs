defmodule TypedStruct.ReadmeTest do
  use ExUnit.Case

  defmodule Person do
    @moduledoc "A struct representing a person."
    @moduledoc since: "0.1.0"

    use TypedStruct

    typedstruct do
      plugin TypedStructNimbleOptions

      field :name, String.t(), enforce: true, doc: "The name."
      field :age, non_neg_integer(), doc: "The age."
      field :happy?, boolean(), default: true
      field :attrs, %{optional(atom()) => String.t()}
    end
  end

  defmodule Profile do
    use TypedStruct

    typedstruct enforce: true do
      plugin TypedStructNimbleOptions
      field :name, String.t()
    end
  end

  defmodule User do
    use TypedStruct

    typedstruct enforce: true do
      plugin TypedStructNimbleOptions
      field :id, pos_integer()
      field :profile, Profile.t(), validation_type: {:nested_struct, Profile, :new}
    end
  end

  doctest_file("README.md")
end
