{pkgs ? import <nixpkgs> {}}: let
  # Helper function to create a tagged package group
  mkPackageGroup = name: packages: {
    inherit name packages;
  };

  # Define package groups
  packageGroups = [
    (mkPackageGroup "Core Elixir Tools" [
      pkgs.elixir
      pkgs.erlang
      pkgs.rebar3
    ])
    (mkPackageGroup "Build Tools" [
      pkgs.gnumake
      pkgs.gcc
      pkgs.readline
      pkgs.openssl
      pkgs.zlib
      pkgs.libxml2
      pkgs.curl
      pkgs.libiconv
    ])
    (mkPackageGroup "Development Tools" [
      pkgs.inotify-tools # For file system events (used by Phoenix live reload)
      pkgs.postgresql # For Phoenix applications
      pkgs.nodejs_20 # For Phoenix assets compilation
    ])
    (mkPackageGroup "Version Control" [
      pkgs.git
    ])
  ];

  # Flatten package groups into a single list
  allPackages = builtins.concatLists (map (group: group.packages) packageGroups);
in
  pkgs.mkShell {
    buildInputs = allPackages;

    shellHook = ''
      # Ensure local hex and rebar are available
      mix local.hex --force
      mix local.rebar --force

      # Set up environment variables
      export ERL_AFLAGS="-kernel shell_history enabled"
      export LANG=C.UTF-8
      export LC_ALL=C.UTF-8

      # Add local mix installation to PATH
      export PATH=$PATH:$HOME/.mix/escripts

      # Set up IEx configuration
      if [ ! -f ~/.iex.exs ]; then
        cat > ~/.iex.exs << 'IEXEOF'
IEx.configure(
  colors: [
    syntax_colors: [
      number: :yellow,
      atom: :cyan,
      string: :green,
      boolean: :red,
      nil: :red,
    ],
    ls_directory: :cyan,
    ls_device: :yellow,
    doc_code: :green,
    doc_inline_code: :magenta,
    doc_headings: [:cyan, :underline],
    doc_title: [:cyan, :bright, :underline],
  ],
  default_prompt: [
    "\e[G", # cursor ⇒ column 1
    :cyan,
    "%prefix",
    :yellow,
    "|#{Mix.env}|",
    :cyan,
    "%counter",
    " ",
    :yellow,
    "▶",  # triangle
    :reset
  ] |> IO.ANSI.format |> IO.chardata_to_string
)
IEXEOF
      fi

      # Function to create a new Phoenix project with defaults
      new_phoenix_project() {
        if [ -z "$1" ]; then
          echo "Please provide a project name"
          return 1
        fi

        mix phx.new "$1" --install
      }

      # Function to set up development tools
      setup_dev_tools() {
        echo "Installing development tools..."
        mix do \
          local.hex --force, \
          local.rebar --force, \
          archive.install hex phx_new --force

        # Install common development packages
        if [ -f "mix.exs" ]; then
          echo "Installing Credo and Dialyxir..."
          mix do \
            deps.get, \
            deps.clean --unused, \
            deps.compile

          # Add development tools to mix.exs if they don't exist
          if ! grep -q "\":credo\"" mix.exs; then
            echo "Adding Credo to mix.exs..."
            sed -i '/deps/a \ \ \ \ \ \ {:credo, "~> 1.7", only: [:dev, :test], runtime: false},' mix.exs
          fi

          if ! grep -q "\":dialyxir\"" mix.exs; then
            echo "Adding Dialyxir to mix.exs..."
            sed -i '/deps/a \ \ \ \ \ \ {:dialyxir, "~> 1.4", only: [:dev], runtime: false},' mix.exs
          fi

          mix do deps.get, deps.compile
        else
          echo "No mix.exs found. Skipping development tools installation."
        fi
      }

      # Create useful aliases
      alias mts="mix test"
      alias mtw="mix test.watch"
      alias mps="mix phx.server"
      alias mpr="mix phx.routes"
      alias mpg="mix phx.gen"
      alias mdg="mix deps.get"
      alias mdc="mix deps.compile"
      alias mam="mix app.match"
      alias mcr="mix credo"
      alias mdl="mix dialyzer"

      # Print environment information
      echo "🧪 Elixir development environment is ready!"
      echo "📦 Installed package groups:"
      ${builtins.concatStringsSep "\n" (map (group: "echo \"  - ${group.name}\"") packageGroups)}
      echo -e "\n🎯 Quick reference:"
      echo "  - Setup development tools: setup_dev_tools"
      echo "  - Create new Phoenix project: new_phoenix_project project_name"
      echo "  - Start Phoenix server: mps"
      echo "  - Run tests: mts"
      echo "  - Get dependencies: mdg"
      echo "  - Run Credo: mcr"
      echo "  - Run Dialyzer: mdl"
      echo -e "\n💡 Elixir version: $(elixir -v)"
    '';

    # Set environment variables for PostgreSQL
    PGDATA = "${pkgs.postgresql}/data";
    PGHOST = "localhost";
    PGPORT = "5432";

    # Add pkg-config to find system libraries
    nativeBuildInputs = [pkgs.pkg-config];
  }
