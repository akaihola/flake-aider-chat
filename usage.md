In your regular shell, you can type:

    nix develop '/path/to/flake-aider-chat#install'  # to install Aider and dependencies
    nix develop '/path/to/flake-aider-chat#shell'    # drop to a shell in the Aider environment
    nix develop '/path/to/flake-aider-chat'          # to run Aider with the default configuration

Once dropped into a shell in the Aider environment, you can type:

    aider-install               # to install Aider and dependencies
    aider --config=$AIDER_CONF  # to run Aider with the default configuration

