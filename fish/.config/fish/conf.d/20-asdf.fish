# ASDF configuration
if command -v asdf >/dev/null 2>&1
    # ASDF shims path
    if test -z $ASDF_DATA_DIR
        set _asdf_shims "$HOME/.asdf/shims"
    else
        set _asdf_shims "$ASDF_DATA_DIR/shims"
    end

    # Add asdf shims to PATH
    if not contains $_asdf_shims $PATH
        set -gx --prepend PATH $_asdf_shims
    end
    set --erase _asdf_shims

    # Generate asdf completions
    asdf completion fish > ~/.config/fish/completions/asdf.fish
end
