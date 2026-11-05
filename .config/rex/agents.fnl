(local terminal :com.superlogical.terminal)

;; Agent picker in the command palette, ranked so whoever is waiting on a human
;; comes first, then oldest first within a state. Claude Code and pi report
;; their state with OSC 7501, and Rex keeps the latest report per block.
(local state-rank {:blocked 0 :error 1 :done 2 :idle 3 :working 4})
(local state-icon {:blocked :person :error :person :done :star
                   :idle :terminal :working :clock})

(fn days-from-civil [y m d]
  (let [y (if (<= m 2) (- y 1) y)
        era (math.floor (/ y 400))
        yoe (- y (* era 400))
        doy (+ (math.floor (/ (+ (* 153 (+ m (if (> m 2) -3 9))) 2) 5)) (- d 1))
        doe (+ (* yoe 365) (math.floor (/ yoe 4)) (- (math.floor (/ yoe 100))) doy)]
    (+ (* era 146097) doe -719468)))

;; os.time would read the fields as local time, ignoring the stamp's offset.
(fn rfc3339->epoch [stamp]
  (let [(y mo d h mi s zone) (string.match (or stamp "")
                                           "^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)[.%d]*(.*)$")
        (sign oh om) (string.match (or zone "") "^([+-])(%d+):(%d+)$")
        offset (if sign
                   (* (if (= sign "-") -1 1) (+ (* oh 3600) (* om 60)))
                   0)]
    (when y
      (- (+ (* 86400 (days-from-civil (tonumber y) (tonumber mo) (tonumber d)))
            (* h 3600) (* mi 60) s)
         offset))))

(fn age [secs]
  (if (< secs 60) (.. secs "s")
      (< secs 3600) (.. (math.floor (/ secs 60)) "m")
      (.. (math.floor (/ secs 3600)) "h" (math.floor (/ (% secs 3600) 60)) "m")))

(fn same-process? [a b]
  (and a b (= a.pid b.pid) (= a.name b.name)))

;; A record outlives the program that wrote it, so it only counts while its
;; owner is the foreground process or one of its ancestors.
(fn owner-alive? [owner process]
  (var alive (same-process? owner process.foreground))
  (each [_ ancestor (ipairs (or process.ancestors [])) :until alive]
    (set alive (same-process? owner ancestor)))
  alive)

(fn agent-row [session index window block]
  (let [target {:session_id session.session_id :block_id block.block_id}
        record (?. (rex.block.call terminal :program_status target) :records 1)
        process (and record (= nil record.id)
                     (rex.block.call terminal :process target))]
    (when (and process (owner-alive? record.owner process))
      ;; The spec says to treat an unknown state as idle.
      (let [state (if (. state-rank record.state) record.state :idle)
            dir (: (or (?. process :foreground :cwd) "") :match "[^/]*$")]
        {: state
         : dir
         :session session.session_id
         :window window.window_id
         :block block.block_id
         :where (.. session.label ":" index " · " dir)
         :message (if (not= (or record.msg "") "") record.msg
                      (= state :blocked) (or record.kind "")
                      "")
         :app (or record.effective_app "")
         :updated (or (rfc3339->epoch record.updated_at) 0)}))))

;; When a human last jumped to each block, which Rex has no way to know. A
;; visit counts until the agent next reports, so a blocked agent already seen
;; sinks below the unseen ones, and a seen done or error shows as idle. Lost on
;; config reload, which only resurfaces agents already looked at.
(local visits {})

(fn mark-seen [rows]
  (let [live {}]
    (each [_ row (ipairs rows)]
      (let [visited (. visits row.block)]
        (tset live row.block true)
        (set row.seen (= true (and visited (>= visited row.updated))))
        (set row.rank-time (if row.seen visited row.updated))
        (when (and row.seen (or (= row.state :done) (= row.state :error)))
          (set row.state :idle))))
    (each [block (pairs visits)]
      (when (not (. live block))
        (tset visits block nil)))))

(fn before? [a b]
  (let [a-sunk (and a.seen (= a.state :blocked))
        b-sunk (and b.seen (= b.state :blocked))]
    (if (not= a.state b.state) (< (. state-rank a.state) (. state-rank b.state))
        (not= a-sunk b-sunk) b-sunk
        (< a.rank-time b.rank-time))))

(fn agent-rows []
  (let [rows []]
    (each [_ session (ipairs (or (?. (rex.call :session.list) :sessions) []))]
      ;; Block methods on another session fail until it's attached.
      (let [view (?. (rex.call :session.attach {:session_id session.session_id}) :view)]
        (each [index window (ipairs (or (?. view :windows) []))]
          (each [_ layer (ipairs (or window.layers []))]
            (each [_ block (ipairs (or layer.blocks []))]
              (let [row (and (= block.creator_name terminal)
                             (agent-row session index window block))]
                (when row
                  (table.insert rows row))))))))
    (mark-seen rows)
    (table.sort rows before?)
    rows))

(fn jump [{: session : block : window}]
  (tset visits block (os.time))
  (rex.session.focus_block {:session_id session :block_id block})
  (rex.client.queue :session.select {:session_id session :window_id window}))

(fn agents []
  (let [rows (agent-rows)
        now (os.time)
        by-block {}
        items (icollect [_ row (ipairs rows)]
                (do
                  (tset by-block row.block row)
                  {:id row.block
                   :title row.where
                   :subtitle (.. row.app (if (= row.message "") "" (.. " — " row.message)))
                   :icon (. state-icon row.state)
                   :detail (if (= row.updated 0) row.state
                               (.. row.state " " (age (- now row.updated))))}))
        choice (rex.ui.pick {:title (if (= 0 (length rows)) "No agent sessions running" "Agents")
                             :placeholder "Filter agents"
                             :confirm "Jump to agent"
                             : items})
        row (and choice (. by-block choice))]
    (when row
      (jump row))))

{: agent-rows : agents : jump}
