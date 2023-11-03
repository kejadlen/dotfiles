(local {: application : eventtap : execute : logger : pasteboard : uielement}
       hs)

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
  (let [app (application.frontmostApplication)
        prev-pasteboard (pasteboard.getContents)
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
  (accumulate [last nil _ cmd (ipairs [...])]
    (execute cmd)))

{: chomp : paste : replace-selection : run}

