# Issues 

## In sketchybar:

- Artwork is now showing in spotify popup, however image is successfully retrieved. It seems that scripts can see the image however sketchybar does not render it. Maybe it has to do with layout.

## In yabai
- Scripting addition is not properly loaded upon installation, sometimes I have to manually call `sudo yabai --load-sa`. It seems that calling it within extraConfig of yabai service configuration is unreliable.
