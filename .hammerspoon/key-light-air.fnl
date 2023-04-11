;;; Elgato Key Light Air

(local {: bonjour : caffeinate : http : json : logger : usb} hs)
(local log (logger.new :key-light-air :info))

(fn find-hostname []
  (let [browser (bonjour.new)
        cb (fn [browser _ _ service _]
             (service:resolve #(log.i (: ($1:hostname) :sub 1 -2)))
             (browser:stop))]
    (browser:findServices :_elg._tcp. cb)))

(fn update [on?]
  (let [url "http://elgato-key-light-air-5c9e.local:9123/elgato/lights"
        on (if on? 1 0)
        data (json.encode {:lights [{: on}]})]
    (http.doRequest url :PUT data)))

(fn docked? []
  (accumulate [docked? false _ v (pairs (usb.attachedDevices)) &until docked?]
    (or docked? (= v.productName "TS4 USB3.2 Gen2 HUB"))))

(local watcher (let [{: watcher} caffeinate
                     w (watcher.new #(when (docked?)
                                       (match $1
                                         watcher.screensDidLock (update false)
                                         watcher.screensDidSleep (update false)
                                         watcher.screensDidUnlock (update true)
                                         watcher.screensDidWake (update true))))]
                 (w:start)))

; (local usb-watcher (: (hs.usb.watcher.new #(let [{: eventType : productName} $1]
;                                              (when (= productName
;                                                       "CalDigit Thunderbolt 3 Audio")
;                                                (match eventType
;                                                  :added (do
;                                                           (update-key-light-air true)
;                                                           (key-light-air-watcher:start))
;                                                  :removed (do
;                                                             (update-key-light-air false)
;                                                             (key-light-air-watcher:stop))))))
;                       :start))

{: find-hostname : log : update : watcher}

