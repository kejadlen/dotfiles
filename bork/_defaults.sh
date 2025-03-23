### defaults

# TODO restart Dock, Finder, and SystemUIServer on changes

### global defaults

ok defaults -globalDomain NSDisableAutomaticTermination bool true # don't quit idle applications
ok defaults -globalDomain AppleFontSmoothing int 0 # disable font smoothing
ok defaults -globalDomain AppleKeyboardUIMode int 3 # full keyboard access
ok defaults -globalDomain AppleShowAllExtensions bool true # show all extensions by default
ok defaults -globalDomain KeyRepeat int 2 # keyboard repeat rate
ok defaults -globalDomain InitialKeyRepeat int 25 # delay before keyboard repeat
ok defaults -globalDomain NSTableViewDefaultSizeMode int 1 # set sidebar item size to small
ok defaults -globalDomain NSQuitAlwaysKeepsWindows bool false # disable resume
ok defaults -globalDomain WebKitDeveloperExtras bool true # add debug menu in web views
ok defaults -globalDomain com.apple.mouse.tapBehavior bool true # tap to click
ok defaults -globalDomain AppleShowScrollBars string WhenScrolling # only show scrollbars when scrolling
ok defaults -globalDomain NSWindowShouldDragOnGesture bool true # move windows by holding ctrl+cmd and dragging any part of the window

ok defaults com.apple.dashboard mcx-disabled bool true # disable dashboard
ok defaults com.apple.desktopservices DSDontWriteNetworkStores bool true # don't write .DS_Store to network volumes

ok defaults com.apple.dock autohide bool true # automatically hide and show the dock
ok defaults com.apple.dock mineffect string scale # minimize windows using the scale effect
ok defaults com.apple.dock mru-spaces bool false # don't rearrange spaces
ok defaults com.apple.dock orientation string left
ok defaults com.apple.dock wvous-bl-corner int 10 # the bottom left hot corner to sleep the display
ok defaults com.apple.dock tilesize int 36 # set the icon size to 36 pixels
ok defaults com.apple.dock autohide-delay float 0 # no dock delay
ok defaults com.apple.dock showhidden bool true # show hidden apps

# https://nikitabobko.github.io/AeroSpace/guide#a-note-on-displays-have-separate-spaces
ok defaults com.apple.spaces spans-displays bool true disable

ok defaults com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking int 1
ok defaults com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture int 0
ok defaults com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag bool true
ok defaults com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture int 0
ok defaults com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerVertSwipeGesture int 0

# # Finder defaults
ok defaults com.apple.finder FXEnableExtensionChangeWarning bool false # don't ask when changing file extension
ok defaults com.apple.finder FXPreferredViewStyle string Nlsv # default to list view
ok defaults com.apple.finder QLEnableTextSelection bool true # enable text selection in QuickLook
ok defaults com.apple.finder _FXShowPosixPathInTitle bool true # show full path in Finder
ok defaults com.apple.Finder NSToolbarTitleViewRolloverDelay float 0 # remove the proxy icon hover delay
# https://twitter.com/chucker/status/1395843084383043584
ok defaults com.apple.Finder NSWindowSupportsAutomaticInlineTitle bool false # show the proxy icon and older titlebar

ok defaults com.apple.universalaccess showWindowTitlebarIcons bool true # show the proxy icon always

ok defaults com.apple.Safari IncludeInternalDebugMenu bool true # enable Debug menu in Safari

ok defaults com.apple.screencapture disable-shadow bool true # no window shadows when capturing windows
ok defaults com.apple.screencapture location string "$HOME/Downloads"

ok defaults com.apple.screensaver askForPassword int 1

ok defaults com.apple.Terminal ShowLineMarks bool false

ok defaults com.google.Chrome AppleEnableSwipeNavigateWithScrolls bool false

# TODO com.freron.MailMate MmAllowedImageURLRegexp
# ok defaults com.freron.MailMate MmAllowedImageURLRegexp string "https://({{ mailmate.allowed_image_regexps | join('|') }})"
          # - (i|images|d)\.gr-assets\.com
          # - www\.goodreads\.com
          # - massdrop-s3\.imgix\.net
          # - .*\.cloudfront\.net
          # - s3\.amazonaws\.com
          # - files\.convertkitcdn\.com/assets/pictures
          # - wizardzines\.com

ok defaults com.freron.MailMate MmSendMessageDelayEnabled bool true
ok defaults com.freron.MailMate MmSendMessageDelay int 60

