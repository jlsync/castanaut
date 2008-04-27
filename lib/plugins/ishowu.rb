module Castanaut; module Plugin
  
  # This module provides primitive support for iShowU, a screencast capturing
  # tool for Mac OS X from Shiny White Box.
  #
  # iShowU is widely considered a good, simple application for its purpose,
  # but you're by no means required to use it for Castanaut. Simply write
  # your own module for Snapz Pro, or ScreenFlow, or whatever you like.
  #
  # Shiny White Box is promising much better Applescript support in an 
  # imminent version, which could tidy up this module quite a bit.
  #
  # More info: http://www.shinywhitebox.com/home/home.html
  module Ishowu

    # Set the screencast to capture a particular region of the screen.
    # Generate appropriately-formatted co-ordinates using Castanaut::Movie#to.
    def ishowu_set_region(*options)
      ishowu_applescriptify

      options = combine_options(*options)

      ishowu_menu_item("Capture", "Capture full screen")
      sleep(0.2)
      ishowu_menu_item("Capture", "Capture custom area", false)
      sleep(0.2)
      automatically "mousewarp 4 4"

      drag to(options[:to][:left], options[:to][:top])

      sleep(0.2)
      bounds = screen_size
      automatically "mousewarp #{bounds[:to][:width] - 4} #{bounds[:to][:height] - 4}"
      drag to(
        options[:to][:left] + options[:to][:width],
        options[:to][:top] + options[:to][:height]
      )
      hit Enter
      ishowu_hide
    end

    # Tell iShowU to start recording. Will automatically stop recording when
    # the movie is ended, unless you set :auto_stop => false in options.
    def ishowu_start_recording(options = {})
      ishowu_hide
      ishowu_menu_item("Capture", "Start capture")
      unless options[:auto_stop] == false
        at_end_of_movie { ishowu_stop_recording }
      end
    end

    # Tell iShowU to stop recording.
    def ishowu_stop_recording
      ishowu_menu_item("Capture", "Stop capture")
    end

    # Execute an iShowU menu option.
    def ishowu_menu_item(menu, item, quiet = true)
      ascript = %Q`
        tell application "iShowU"
          activate
          tell application "System Events"
            click menu item "#{item}" of menu "#{menu}" of menu bar item "#{menu}" of menu bar 1 of process "iShowU"
          #{'set visible of process "iShowU" to false' if quiet}
          end tell
        end
      `
      execute_applescript(ascript)
    end

    # Hide the iShowU window. This is a bit random, and suggestions are 
    # welcomed.
    def ishowu_hide
      ishowu_menu_item("iShowU", "Hide iShowU")
    end

    private
    # iShowU is not Applescript-enabled out of the box. This fix, arguably
    # a hack, lets us do some limited work with it in Applescript.
    def ishowu_applescriptify
      execute_applescript(%Q`
        try
        tell application "Finder"
          set the a_app to (application file id "com.tcdc.Digitizer") as alias
        end tell
        set the plist_filepath to the quoted form of ¬
        ((POSIX path of the a_app) & "Contents/Info")
        do shell script "defaults write " & the plist_filepath & space ¬
        & "NSAppleScriptEnabled -bool YES"
        end try
      `)
    end
  end
end; end
