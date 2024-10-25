defmodule DefTestStruct do
  defmacro __using__(opts) do
    quote do
      defmodule unquote(opts[:name]) do
        use TypedStruct

        typedstruct unquote(if opts[:enforce?], do: [enforce: true], else: []) do
          plugin TypedStructNimbleOptions, unquote(opts[:plugin_opts] || [])
          field :name, String.t(), doc: "The name of the user."
          field :age, integer(), enforce: false
          field :type, atom(), default: :user
          field :complex, %{optional(atom) => String.t()}, default: %{}
        end
      end
    end
  end
end

defmodule TypedStructNimbleOptionsTest do
  use ExUnit.Case
  doctest TypedStructNimbleOptions

  use DefTestStruct, name: NoEmptyNew, enforce?: true

  test "no empty new when any keys are enforced" do
    refute Kernel.function_exported?(NoEmptyNew, :new, 0)
    refute Kernel.function_exported?(NoEmptyNew, :new!, 0)
  end

  use DefTestStruct, name: EmptyNew, enforce?: false

  test "empty new when no keys are enforced" do
    assert {:ok, %EmptyNew{}} == EmptyNew.new()
    assert %EmptyNew{} == EmptyNew.new!()
  end

  describe "default struct" do
    use DefTestStruct, name: DefaultStruct, enforce?: true

    test "new" do
      refute Kernel.function_exported?(DefaultStruct, :new, 0)

      assert {:error,
              %NimbleOptions.ValidationError{
                key: :name,
                value: nil,
                keys_path: []
              }} = DefaultStruct.new([])

      assert {:error,
              %NimbleOptions.ValidationError{
                key: :name,
                value: :atom_name,
                keys_path: []
              }} = DefaultStruct.new(name: :atom_name)

      assert {:ok, %DefaultStruct{name: "string name", age: nil, type: :user}} =
               DefaultStruct.new(name: "string name")

      assert {:error,
              %NimbleOptions.ValidationError{
                key: :age,
                value: :an_atom,
                keys_path: []
              }} = DefaultStruct.new(name: "string name", age: :an_atom)

      assert {:error,
              %NimbleOptions.ValidationError{
                key: :complex,
                value: :an_atom,
                keys_path: []
              }} = DefaultStruct.new(name: "string name", complex: :an_atom)

      assert {:error,
              %NimbleOptions.ValidationError{
                key: :complex,
                keys_path: [],
                value: %{k: 1},
                message:
                  "invalid map in :complex option: invalid value for map key :k: expected string, got: 1"
              }} = DefaultStruct.new(name: "string name", complex: %{k: 1})

      assert {:ok, %DefaultStruct{complex: %{k: "value"}}} =
               DefaultStruct.new(name: "string name", complex: %{k: "value"})
    end

    test "new!" do
      refute Kernel.function_exported?(DefaultStruct, :new!, 0)

      assert_raise NimbleOptions.ValidationError, fn -> DefaultStruct.new!([]) end

      assert_raise NimbleOptions.ValidationError, fn -> DefaultStruct.new!(name: :atom_name) end

      assert %DefaultStruct{name: "string name", age: nil, type: :user} =
               DefaultStruct.new!(name: "string name")

      assert_raise NimbleOptions.ValidationError, fn ->
        DefaultStruct.new!(name: "string name", age: :an_atom)
      end
    end

    test "docs" do
      assert DefaultStruct.field_docs() =~
               ~r|^\* `:name` \(`t:String.t/0`\) - Required\. The name of the user\.$|m

      assert DefaultStruct.field_docs(nest_level: 2) =~
               ~r|^    \* `:name` \(`t:String.t/0`\) - Required\. The name of the user\.$|m
    end
  end

  describe "renamed functions" do
    use DefTestStruct,
      name: RenamedFuns,
      enforce?: false,
      plugin_opts: [ctor: :create, ctor!: :create!, docs: :documentation]

    test "ctor" do
      refute Kernel.function_exported?(RenamedFuns, :new, 0)
      assert Kernel.function_exported?(RenamedFuns, :create, 0)
      assert {:ok, %RenamedFuns{name: "string name"}} = RenamedFuns.create(name: "string name")
    end

    test "ctor!" do
      refute Kernel.function_exported?(RenamedFuns, :new!, 0)
      assert Kernel.function_exported?(RenamedFuns, :create!, 1)
      assert %RenamedFuns{name: "string name"} = RenamedFuns.create!(name: "string name")
    end

    test "docs" do
      refute Kernel.function_exported?(RenamedFuns, :field_docs, 0)
      assert Kernel.function_exported?(RenamedFuns, :documentation, 0)
    end
  end

  describe "disabled functions" do
    use DefTestStruct,
      name: DisabledFuns,
      enforce?: false,
      plugin_opts: [ctor: nil, ctor!: nil, docs: nil]

    test "ctor" do
      refute Kernel.function_exported?(DisabledFuns, :new, 0)
    end

    test "ctor!" do
      refute Kernel.function_exported?(DisabledFuns, :new!, 0)
    end

    test "docs" do
      refute Kernel.function_exported?(DisabledFuns, :field_docs, 0)
    end
  end

  describe "global options" do
    Application.put_env(:my_otp_app, TypedStructNimbleOptions, ctor: :a, ctor!: :b!, docs: :c)

    use DefTestStruct,
      name: GlobalOptionsStruct,
      enforce?: false,
      plugin_opts: [otp_app: :my_otp_app]

    test "ctor" do
      refute function_exported?(GlobalOptionsStruct, :new, 0)
      refute function_exported?(GlobalOptionsStruct, :new, 1)
      assert function_exported?(GlobalOptionsStruct, :a, 0)
      assert function_exported?(GlobalOptionsStruct, :a, 1)
    end

    test "ctor!" do
      refute function_exported?(GlobalOptionsStruct, :new!, 0)
      refute function_exported?(GlobalOptionsStruct, :new!, 1)
      assert function_exported?(GlobalOptionsStruct, :b!, 0)
      assert function_exported?(GlobalOptionsStruct, :b!, 1)
    end

    test "docs" do
      refute function_exported?(GlobalOptionsStruct, :field_docs, 1)
      assert function_exported?(GlobalOptionsStruct, :c, 1)
    end
  end
end
