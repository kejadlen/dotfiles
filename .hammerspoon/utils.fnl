(local {: eventtap : execute : logger : pasteboard : uielement} hs)

(local log (logger.new :utils :info))

(fn chomp [s]
  "Returns the input without a trailing newline"
  (if (= (s:sub -1) "\n")
      (s:sub 1 -2)
      s))

;; paste content, preserving the previous pasteboard
(fn paste [content]
  (let [prev-pasteboard (pasteboard.getContents)]
    (pasteboard.setContents content)
    (eventtap.keyStroke [:cmd] :v)
    (pasteboard.setContents prev-pasteboard)))

(fn replace-selection [cb]
  "Replaces the current selection with the return value of the callback"
  (let [prev-pasteboard (pasteboard.getContents)
        e (uielement.focusedElement)
        text (if e (e:selectedText)
                 (do
                   (eventtap.keyStroke [:cmd] :c)
                   (pasteboard.getContents)))
        content (cb text prev-pasteboard)]
    (paste content)
    (pasteboard.setContents prev-pasteboard)))

(fn run [...]
  "Executes a list of commands"
  (each [_ cmd (ipairs [...])]
    (execute cmd)))

; https://github.com/Hammerspoon/hammerspoon/issues/3224#issuecomment-1294359070
(λ with-ax-hotfix [win cb]
  (let [app (win:application)
        ax-app (hs.axuielement.applicationElement app)
        prev-val ax-app.AXEnhancedUserInterface]
    (set ax-app.AXEnhancedUserInterface false)
    (cb)
    (set ax-app.AXEnhancedUserInterface prev-val)))

{: chomp : paste : replace-selection : run : with-ax-hotfix}
