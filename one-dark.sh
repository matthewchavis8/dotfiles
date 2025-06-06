
#!/usr/bin/env bash

# MY ONE DARK 

[[ -z "$PROFILE_NAME" ]] && PROFILE_NAME="One Dark"
[[ -z "$PROFILE_SLUG" ]] && PROFILE_SLUG="one-dark"
[[ -z "$DCONF" ]] && DCONF=dconf
[[ -z "$UUIDGEN" ]] && UUIDGEN=uuidgen

dset() {
    local key="$1"; shift
    local val="$1"; shift
    if [[ "$type" == "string" ]]; then
        val="'$val'"
    fi
    "$DCONF" write "$PROFILE_KEY/$key" "$val"
}

dlist_append() {
    local key="$1"; shift
    local val="$1"; shift
    local entries="$(
        {
            "$DCONF" read "$key" | tr -d '[]' | tr , "\n" | fgrep -v "$val"
            echo "'$val'"
        } | head -c-1 | tr "\n" ,
    )"
    "$DCONF" write "$key" "[$entries]"
}

if which "$DCONF" > /dev/null 2>&1; then
    [[ -z "$BASE_KEY_NEW" ]] && BASE_KEY_NEW=/org/gnome/terminal/legacy/profiles:
    if [[ -n "`$DCONF list $BASE_KEY_NEW/`" ]]; then
        [[ -n "`which $UUIDGEN`" ]] && PROFILE_SLUG=`uuidgen`
        if [[ -n "`$DCONF read $BASE_KEY_NEW/default`" ]]; then
            DEFAULT_SLUG=`$DCONF read $BASE_KEY_NEW/default | tr -d \'`
        else
            DEFAULT_SLUG=`$DCONF list $BASE_KEY_NEW/ | grep '^:' | head -n1 | tr -d :/`
        fi

        DEFAULT_KEY="$BASE_KEY_NEW/:$DEFAULT_SLUG"
        PROFILE_KEY="$BASE_KEY_NEW/:$PROFILE_SLUG"

        $DCONF dump "$DEFAULT_KEY/" | $DCONF load "$PROFILE_KEY/"
        dlist_append $BASE_KEY_NEW/list "$PROFILE_SLUG"

        dset visible-name "'$PROFILE_NAME'"

        dset palette "['#000000', '#e06c75', '#98c379', '#d19a66', \
'#61afef', '#c678dd', '#56b6c2', '#ffffff', \
'#5c6370', '#e06c75', '#98c379', '#d19a66', \
'#61afef', '#c678dd', '#56b6c2', '#ffffff']"

        dset background-color "'#282c34'"
        dset foreground-color "'#ffffff'"
        dset bold-color "'#ffffff'"
        dset bold-color-same-as-fg "true"
        dset use-theme-colors "false"
        dset use-theme-background "false"

        unset PROFILE_NAME PROFILE_SLUG DCONF UUIDGEN
        exit 0
    fi
fi

# Older GNOME version
[[ -z "$GCONFTOOL" ]] && GCONFTOOL=gconftool
[[ -z "$BASE_KEY" ]] && BASE_KEY=/apps/gnome-terminal/profiles
PROFILE_KEY="$BASE_KEY/$PROFILE_SLUG"

gset() {
    local type="$1"; shift
    local key="$1"; shift
    local val="$1"; shift
    "$GCONFTOOL" --set --type "$type" "$PROFILE_KEY/$key" -- "$val"
}
glist_append() {
    local type="$1"; shift
    local key="$1"; shift
    local val="$1"; shift
    local entries="$(
        {
            "$GCONFTOOL" --get "$key" | tr -d '[]' | tr , "\n" | grep -f -v "$val"
            echo "$val"
        } | head -c-1 | tr "\n" ,
    )"
    "$GCONFTOOL" --set --type list --list-type $type "$key" "[$entries]"
}

glist_append string /apps/gnome-terminal/global/profile_list "$PROFILE_SLUG"
gset string visible_name "$PROFILE_NAME"

gset string palette "#000000:#e06c75:#98c379:#d19a66:#61afef:#c678dd:#56b6c2:#ffffff:\
#5c6370:#e06c75:#98c379:#d19a66:#61afef:#c678dd:#56b6c2:#ffffff"

gset string background_color "#282c34"
gset string foreground_color "#ffffff"
gset string bold_color "#ffffff"
gset bool   bold_color_same_as_fg "true"
gset bool   use_theme_colors "false"
gset bool   use_theme_background "false"

unset PROFILE_NAME PROFILE_SLUG GCONFTOOL DCONF UUIDGEN
