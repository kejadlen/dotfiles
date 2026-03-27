(local {: ok} (require :frork))

(require :types)

;; # TODO restart Dock, Finder, and SystemUIServer on changes

(local domain-defaults
       {:-globalDomain [; don't quit idle applications
                        [:NSDisableAutomaticTermination :bool true]
                        ; disable font smoothing
                        [:AppleFontSmoothing :int 0]
                        ; full keyboard access
                        [:AppleKeyboardUIMode :int 3]
                        ; show all extensions by default
                        [:AppleShowAllExtensions :bool true]
                        ; keyboard repeat rate
                        [:KeyRepeat :int 2]
                        ; delay before keyboard repeat
                        [:InitialKeyRepeat :int 25]
                        ; set sidebar item size to small
                        [:NSTableViewDefaultSizeMode :int 1]
                        ; disable resume
                        [:NSQuitAlwaysKeepsWindows :bool false]
                        ; add debug menu in web views
                        [:WebKitDeveloperExtras :bool true]
                        ; tap to click
                        [:com.apple.mouse.tapBehavior :bool true]
                        ; only show scrollbars when scrolling
                        [:AppleShowScrollBars :string :WhenScrolling]
                        ; move windows by holding ctrl+cmd and dragging any part of the window
                        [:NSWindowShouldDragOnGesture :bool true]
                        ; disable action images in menus (Liquid Glass)
                        [:NSMenuEnableActionImages :bool false]]
        :com.apple.dock [; automatically hide and show the dock
                         [:autohide :bool true]
                         ; minimize windows using the scale effect
                         [:mineffect :string :scale]
                         ; don't rearrange spaces
                         [:mru-spaces :bool false]
                         [:orientation :string :left]
                         ; the bottom left hot corner to sleep the display
                         [:wvous-bl-corner :int 10]
                         ; set the icon size to 36 pixels
                         [:tilesize :int 36]
                         ; no dock delay
                         [:autohide-delay :float 0]
                         ; show hidden apps
                         [:showhidden :bool true]]
        ; https://nikitabobko.github.io/AeroSpace/guide#a-note-on-displays-have-separate-spaces
        :com.apple.spaces [[:spans-displays :bool true]]
        :com.apple.driver.AppleBluetoothMultitouch.trackpad [[:Clicking :int 1]
                                                             [:TrackpadFourFingerVertSwipeGesture
                                                              :int
                                                              0]
                                                             [:TrackpadThreeFingerDrag
                                                              :bool
                                                              true]
                                                             [:TrackpadThreeFingerHorizSwipeGesture
                                                              :int
                                                              0]
                                                             [:TrackpadThreeFingerVertSwipeGesture
                                                              :int
                                                              0]]
        ; don't write .DS_Store to network volumes
        :com.apple.desktopservices [[:DSDontWriteNetworkStores :bool true]]
        :com.apple.finder [; don't ask when changing file extension
                           [:FXEnableExtensionChangeWarning :bool false]
                           ; default to list view
                           [:FXPreferredViewStyle :string :Nlsv]
                           ; enable text selection in QuickLook
                           [:QLEnableTextSelection :bool true]
                           ; show full path in Finder
                           [:_FXShowPosixPathInTitle :bool true]
                           ; remove the proxy icon hover delay
                           [:NSToolbarTitleViewRolloverDelay :float 0]
                           ; https://twitter.com/chucker/status/1395843084383043584
                           ; show the proxy icon and older titlebar
                           [:NSWindowSupportsAutomaticInlineTitle :bool false]]
        ; show the proxy icon always
        :com.apple.universalaccess [[:showWindowTitlebarIcons :bool true]]
        ; enable Debug menu in Safari
        :com.apple.Safari [[:IncludeInternalDebugMenu :bool true]]
        :com.apple.screensaver [[:askForPassword :int 1]]
        :com.freron.MailMate [[:MmSendMessageDelayEnabled :bool true]
                              [:MmSendMessageDelay :int 60]]})

(each [domain defaults (pairs domain-defaults)]
  (each [_ [key typ val] (ipairs defaults)]
    (ok :defaults domain key typ val)))

(let [allowed-image-urls ["(i|images|d)\\.gr-assets\\.com"
                          "www\\.goodreads\\.com"
                          ".*\\.cloudfront\\.net"
                          "s3\\.amazonaws\\.com"
                          "files\\.convertkitcdn\\.com/assets/pictures"
                          "wizardzines\\.com"
                          "www\\.redfin\\.com/stingray/do/api-get-listing-hero-shot"
                          "www\\.404media\\.co/content/images"
                          "the-ergo-archive\\.zsa\\.io/assets/images"
                          ".*\\.soundestlink\\.com/image/newsletter"
                          "c\\d+\\.patreon(usercontent)?\\.com"
                          :mcusercontent.com
                          "cdn\\.shopify\\.com/s/files"]]
  (ok :defaults :com.freron.MailMate :MmAllowedImageURLRegexp :string
      (.. "https://(" (table.concat allowed-image-urls "|") ")/.*")))
