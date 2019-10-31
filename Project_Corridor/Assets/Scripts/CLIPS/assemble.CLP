;; Name:	Tom Birdsong
;; Course:	ECE 4420 F19
;; Project:	Takehome 1
;; Summary:	CLIPS procedural generation map assembler

;; Templates
(deftemplate tile 
	(slot id )
	(slot type (default room))
	(slot ht (type NUMBER) (default 1))
	(slot wid (type NUMBER) (default 1))
	(slot N-tile (default nil))
	(slot S-tile (default nil))
	(slot E-tile (default nil))
	(slot W-tile (default nil))
	(slot N-wall (default CLOSED))
	(slot S-wall (default CLOSED))
	(slot E-wall (default CLOSED))
	(slot W-wall (default CLOSED))
	(slot room-id (default nil))
	(slot x (type NUMBER) (default 999))
	(slot z (type NUMBER) (default 999))
	(slot dist (type NUMBER))
	(slot num_rots (type NUMBER) (default 0))
	(slot assembled (default FALSE)))

(deftemplate multitile
	(slot id)
	(slot type (default room))
	(slot ht (type NUMBER) (default 0))
	(slot wid (type NUMBER) (default 0))
	(slot x_min (type NUMBER) (default 999))
	(slot x_max (type NUMBER) (default 999))
	(slot z_min (type NUMBER) (default 999))
	(slot z_max (type NUMBER) (default 999))
	(slot assembled (default FALSE)))

(deftemplate params (slot min_dist (type NUMBER) (default 1)))

(deftemplate input-file (slot src (type STRING) (default "C:/")))
(deftemplate output-file (slot dst (type STRING) (default "C:/")))

(deftemplate db-status (slot valid))
(deftemplate assembly-result (slot successful))
(deftemplate cut-tile (slot id))
(deftemplate f-ptr (slot name) (slot mode) (slot active (default TRUE)))
(deftemplate last-read (slot data))

;; READ DB: Read in tile database from common file


(defrule init-src
(declare (salience 99))
(not (input-file))
=>
(assert (input-file))
)

(defrule init-dst
(declare (salience 99))
(not (output-file))
=>
(assert (output-file))
)

(defrule init-f-reader
(declare (salience 99))
(input-file (src ?src))
(not (f-ptr))
=>
(open ?src readFile "r")
(assert (f-ptr (name readFile) (mode r)))
)

(defrule read-params
(declare (salience 95))
(f-ptr (name ?f) (mode r))
(not (params))
?l <- (last-read (data params))
=>
(printout t "Load params" crlf)
(assert (params (min_dist (read ?f))))
(retract ?l)
)

(defrule read-tiles
(declare (salience 95))
(f-ptr (name ?f) (mode r))
?l <- (last-read (data ?d&tile))
=>
(printout t "Load " ?d crlf)
(assert (tile (id (read ?f)) (type (read ?f)) (ht (read ?f)) (wid (read ?f)) (N-wall (read ?f)) (S-wall (read ?f)) (E-wall (read ?f)) (W-wall (read ?f))))
(retract ?l)
)

(defrule read-eof
(declare (salience 95))
?file <- (f-ptr (name ?f) (mode r))
?l <- (last-read (data EOF))
=>
(printout t "Close " ?f crlf)
(close ?f)
(modify ?file (active FALSE))
(retract ?l)
)


(defrule read-one
(declare (salience 94))
(f-ptr (name ?f) (mode r) (active TRUE))
(or (not (last-read)) (last-read (data ~params&~tile&~EOF)))
=>
(assert (last-read (data (read ?f))))
)

(defrule close-file
(declare (salience 93))
(f-ptr (name ?f) (mode r) (active TRUE))
=>
(close ?f)
(modify ?f (active FALSE))
)

;; VALIDATE DB: Initial check for whether tile database
;; could yield a valid map

(defrule validate-init-db
(declare (salience 90))
(and (tile (id START)) (tile (id GOAL)))
(not (assembly-result))
=>
(assert (db-status (valid TRUE)))
)

(defrule invalidate-init-db
(not (and (tile (id START)) (tile (id GOAL))))
=>
(printout t "Invalid starting database! Need a START, a GOAL, and at least n tiles." crlf)
(assert (db-status (valid FALSE)))
)



;; PREPROCESS: Break large tiles into manageable pieces

(defrule break-two-by-one
(declare (salience 80))
?tall-tile <- (tile (id ?t-id) (type ?type) (ht 2) (wid 1) (N-wall ?n) (S-wall ?s) (E-wall ?e) (W-wall ?w))
=>
(bind ?n-name (str-cat ?t-id "_NORTH"))
(bind ?s-name (str-cat ?t-id "_SOUTH"))
(assert (tile (id ?n-name) (type ?type) (ht 1) (wid 1) (room-id ?t-id) (N-wall ?n) (S-wall OPEN) (S-tile ?s-name) (E-wall ?e) (W-wall CLOSED)))
(assert (tile (id ?s-name) (type ?type) (ht 1) (wid 1) (room-id ?t-id) (N-wall OPEN) (N-tile ?n-name) (S-wall ?s) (E-wall CLOSED) (W-wall ?w)))
(assert (multitile (id ?t-id) (type ?type) (ht 2) (wid 1)))
(retract ?tall-tile)
)

(defrule break-one-by-two
(declare (salience 80))
?long-tile <- (tile (id ?t-id) (type ?type) (ht 1) (wid 2) (N-wall ?n) (S-wall ?s) (E-wall ?e) (W-wall ?w))
=>
(bind ?e-name (str-cat ?t-id "_EAST"))
(bind ?w-name (str-cat ?t-id "_WEST"))
(assert (tile (id ?w-name) (type ?type) (ht 1) (wid 1) (room-id ?t-id) (N-wall ?n) (S-wall CLOSED) (E-wall OPEN) (E-tile ?e-name) (W-wall ?w)))
(assert (tile (id ?e-name) (type ?type) (ht 1) (wid 1) (room-id ?t-id) (N-wall CLOSED) (S-wall ?s) (E-wall ?e) (W-wall OPEN) (W-tile ?w-name)))
(assert (multitile (id ?t-id) (type ?type) (ht 1) (wid 2)))
(retract ?long-tile)
)

(defrule break-two-by-two
(declare (salience 80))
?square-tile <- (tile (id ?t-id) (type ?type) (ht 2) (wid 2) (N-wall ?n) (S-wall ?s) (E-wall ?e) (W-wall ?w))
=>
(bind ?nw-name (str-cat ?t-id "_NW"))
(bind ?ne-name (str-cat ?t-id "_NE"))
(bind ?se-name (str-cat ?t-id "_SE"))
(bind ?sw-name (str-cat ?t-id "_SW"))
(assert (tile (id ?nw-name) (type ?type) (ht 1) (wid 1) (room-id ?t-id) (N-wall ?n) (S-wall OPEN) (S-tile ?sw-name) (E-wall OPEN) (E-tile ?ne-name) (W-wall CLOSED)))
(assert (tile (id ?ne-name) (type ?type) (ht 1) (wid 1) (room-id ?t-id) (N-wall CLOSED) (E-wall ?e) (S-wall OPEN) (S-tile ?se-name) (W-wall OPEN) (W-tile ?nw-name)))
(assert (tile (id ?se-name) (type ?type) (ht 1) (wid 1) (room-id ?t-id) (N-wall OPEN) (N-tile ?ne-name) (E-wall CLOSED) (S-wall ?s) (W-wall OPEN) (W-tile ?sw-name)))
(assert (tile (id ?sw-name) (type ?type) (ht 1) (wid 1) (room-id ?t-id) (N-wall OPEN) (N-tile ?nw-name) (E-wall OPEN) (E-tile ?se-name) (S-wall CLOSED) (W-wall ?w)))
(assert (multitile (id ?t-id) (type ?type) (ht 2) (wid 2)))
(retract ?square-tile)
)


;; BACKTRACK: Greedy placement tries to place all tiles and then checks validity of resulting map.
;; If map is invalid, remove and reorganize the fewest tiles possible to yield a valid map.

;; Reset all rotations from the previous state to be retried
(defrule reset-rotations
(declare (salience 31))
(cut-tile (id ?t-id))
?r-tile <- (tile (id ~?t-id) (num_rots 4))
=>
(modify ?r-tile (num_rots 0))
)

(defrule remove-N-ref
(declare (salience 30))
(cut-tile (id ?t-id))
?s-tile <- (tile (N-tile ?t-id))
=>
(modify ?s-tile (N-tile nil))
)

(defrule remove-S-ref
(declare (salience 30))
(cut-tile (id ?t-id))
?n-tile <- (tile (S-tile ?t-id))
=>
(modify ?n-tile (S-tile nil))
)

(defrule remove-E-ref
(declare (salience 30))
(cut-tile (id ?t-id))
?w-tile <- (tile (E-tile ?t-id))
=>
(modify ?w-tile (E-tile nil))
)

(defrule remove-W-ref
(declare (salience 30))
(cut-tile (id ?t-id))
?e-tile <- (tile (W-tile ?t-id))
=>
(modify ?e-tile (W-tile nil))
)

(defrule remove-cut-tile
(declare (salience 29))
?c <- (cut-tile (id ?t-id))
=>
(retract ?c)
)

;; STEPWISE VALIDATION: Retroactively verify that no two tiles occupy the same grid space.
;; Also update the distance to start if necessary.


;; Arbitrarily remove tiles occupying same space
(defrule print-overlap
(declare (salience 20))
(not (assembly-result (successful TRUE)))
?t_new <- (tile (id ?t1) (x ?x&~999) (z ?z&~999))
(tile (id ?t2&~?t1) (x ?x) (z ?z))
=>
(printout t "Retracting " ?t1 " from space occupied by " ?t2 crlf)
(retract ?t_new)
)

;; Update distance to shortest path
(defrule dist-N
(declare (salience 20))
?target <- (tile (id ?t1) (assembled TRUE) (x ?x) (z ?z) (dist ?d))
?adj-tile <- (tile (id ~?t1) (assembled TRUE) (x ?x) (z =(+ ?z 1)) (dist ?d2))
(test (< ?d2 (- ?d 1)))
=>
(modify ?target (dist (+ ?d2 1)))
)

(defrule dist-S
(declare (salience 20))
?target <- (tile (id ?t1) (assembled TRUE) (x ?x) (z ?z) (dist ?d))
?adj-tile <- (tile (id ~?t1) (assembled TRUE) (x ?x) (z =(- ?z 1)) (dist ?d2))
(test (< ?d2 (- ?d 1)))
=>
(modify ?target (dist (- ?d2 1)))
)

(defrule dist-E
(declare (salience 20))
?target <- (tile (id ?t1) (assembled TRUE) (x ?x) (z ?z) (dist ?d))
?adj-tile <- (tile (id ~?t1) (assembled TRUE) (x =(+ ?x 1)) (z ?z) (dist ?d2))
(test (< ?d2 (- ?d 1)))
=>
(modify ?target (dist (+ ?d2 1)))
)

(defrule dist-W
(declare (salience 20))
?target <- (tile (id ?t1) (assembled TRUE) (x ?x) (z ?z) (dist ?d))
?adj-tile <- (tile (id ~?t1) (assembled TRUE) (x =(- ?x 1)) (z ?z) (dist ?d2))
(test (< ?d2 (- ?d 1)))
=>
(modify ?target (dist (+ ?d2 1)))
)


;; COATTAILS ASSEMBLE: If tiles were attached before being assembled (such as a large room)
;; make sure the adjacent tiles are marked appropriately

;; If tiles were previously attached to each other before being assembled into the map make sure the adjacent tiles are marked appropriately
(defrule mark-N
(declare (salience 10))
(tile (assembled TRUE) (N-tile ?t-id&~nil) (x ?x) (z ?z) (dist ?d))
?adj-tile <- (tile (id ?t-id) (assembled FALSE))
=>
(modify ?adj-tile (assembled TRUE) (x ?x) (z (+ ?z 1)) (dist (+ ?d 1)))
)

(defrule mark-S
(declare (salience 10))
(tile (assembled TRUE) (S-tile ?t-id&~nil) (x ?x) (z ?z) (dist ?d))
?adj-tile <- (tile (id ?t-id) (assembled FALSE))
=>
(modify ?adj-tile (assembled TRUE) (x ?x) (z (- ?z 1)) (dist (+ ?d 1)))
)

(defrule mark-E
(declare (salience 10))
(tile (assembled TRUE) (E-tile ?t-id&~nil) (x ?x) (z ?z) (dist ?d))
?adj-tile <- (tile (id ?t-id) (assembled FALSE))
=>
(modify ?adj-tile (assembled TRUE) (x (+ ?x 1)) (z ?z) (dist (+ ?d 1)))
)

(defrule mark-W
(declare (salience 10))
(tile (assembled TRUE) (W-tile ?t-id&~nil) (x ?x) (z ?z) (dist ?d))
?adj-tile <- (tile (id ?t-id) (assembled FALSE))
=>
(modify ?adj-tile (assembled TRUE) (x (- ?x 1)) (z ?z) (dist (+ ?d 1)))
)



;; ADJACENCY ASSEMBLE: Stepwise add tiles to the map based on adjacency rules.

;; Mark start as first assembled tiles
(defrule start-assemble
(declare (salience 0))
(exists (db-status (valid TRUE)))
?start-tile <- (tile (id START) (assembled FALSE))
=>
(modify ?start-tile (assembled TRUE) (dist 0) (x 0) (z 0))
)

;; Attach tile with S opening to assembly with N opening
(defrule attach-S-to-N
(declare (salience 0))
(exists (db-status (valid TRUE)))
(not (assembly-result (successful TRUE)))
(params (min_dist ?m_dist))
?south-tile <- (tile (id ?s-id) (N-wall OPEN) (assembled FALSE))
?north-tile <- (tile (id ?n-id) (S-wall OPEN) (S-tile nil) (assembled TRUE) (dist ?d) (x ?x) (z ?z))
(or (tile (id ?s-id&~GOAL)) (test (>= ?d ?m_dist)))
(not (tile (id ~?s-id) (x ?x) (z =(- ?z 1))))
=>
(modify ?north-tile (S-tile ?s-id))
(modify ?south-tile (N-tile ?n-id) (assembled TRUE) (dist (+ ?d 1)) (x ?x) (z (- ?z 1)))
) 

;; Attach tile with N opening to assembly with S opening
(defrule attach-N-to-S
(declare (salience 0))
(exists (db-status (valid TRUE)))
(not (assembly-result (successful TRUE)))
(params (min_dist ?m_dist))
?south-tile <- (tile (id ?s-id) (N-wall OPEN) (N-tile nil) (assembled TRUE) (dist ?d) (x ?x) (z ?z))
?north-tile <- (tile (id ?n-id) (S-wall OPEN) (S-tile nil) (assembled FALSE))
(or (tile (id ?n-id&~GOAL&~"GOAL_NW"&~"GOAL_NE"&~"GOAL_SE"&~"GOAL_SW")) (test (> ?d ?m_dist)))
(not (tile (id ~?n-id) (x ?x) (z =(+ ?z 1))))
=>
(modify ?north-tile (S-tile ?s-id) (assembled TRUE) (dist (+ ?d 1)) (x ?x) (z (+ ?z 1)))
(modify ?south-tile (N-tile ?n-id))
)

;; Attach tile with W opening to assembly with E opening
(defrule attach-W-to-E
(declare (salience 0))
(exists (db-status (valid TRUE)))
(not (assembly-result (successful TRUE)))
(params (min_dist ?m_dist))
?east-tile <- (tile (id ?e-id) (W-wall OPEN) (W-tile nil) (assembled TRUE) (dist ?d) (x ?x) (z ?z))
?west-tile <- (tile (id ?w-id) (E-wall OPEN) (E-tile nil) (assembled FALSE))
(or (tile (id ?w-id&~GOAL)) (test (> ?d ?m_dist)))
(not (tile (id ~?w-id) (x =(- ?x 1)) (z ?z)))
=>
(modify ?east-tile (W-tile ?w-id))
(modify ?west-tile (E-tile ?e-id) (assembled TRUE) (dist (+ ?d 1)) (x (- ?x 1)) (z ?z))
)

;; Attach tile with W opening to assembly with E opening
(defrule attach-E-to-W
(declare (salience 0))
(exists (db-status (valid TRUE)))
(not (assembly-result (successful TRUE)))
(params (min_dist ?m_dist))
?east-tile <- (tile (id ?e-id) (W-wall OPEN) (W-tile nil) (assembled FALSE))
?west-tile <- (tile (id ?w-id) (E-wall OPEN) (E-tile nil) (assembled TRUE) (x ?x) (z ?z) (dist ?d))
(or (tile (id ?e-id&~GOAL)) (test (> ?d ?m_dist)))
(not (tile (id ~?e-id) (x =(+ ?x 1)) (z ?z)))
=>
(modify ?west-tile (E-tile ?e-id))
(modify ?east-tile (W-tile ?w-id) (assembled TRUE) (dist (+ ?d 1)) (x (+ ?x 1)) (z ?z))
)



;; LEFTOVERS ROTATE: Try rotating and attaching tiles that are not currently attached
;; so that the number of tiles left over and not used in the map is minimized

(defrule rotate-tile
(declare (salience -10))
?target <- (tile (assembled FALSE) (N-wall ?n) (E-wall ?e) (S-wall ?s) (W-wall ?w) (N-tile nil) (E-tile nil) (S-tile nil) (W-tile nil) (num_rots ?r))
(test (< ?r 4))
=>
(modify ?target (N-wall ?w) (E-wall ?n) (S-wall ?e) (W-wall ?s) (num_rots (+ ?r 1)))
)


;; DETACH AND ROTATE: If the map could not be successfully assembled, detach and rotate a single tile
;; to initiate backtracking and also reset the rotations of unused tiles

(defrule detach-and-rotate-tile
(declare (salience -20))
(assembly-result (successful FALSE))
?target <- (tile (id ?t-id&~START&~GOAL) (assembled TRUE) (N-wall ?n) (E-wall ?e) (S-wall ?s) (W-wall ?w) (dist ?d) (num_rots ?r))
?other_rot <- (tile (id ~START&~GOAL) (assembled FALSE) (num_rots ?r_1))
(not (exists (tile (dist =(+ ?d 1)))))
(test (< ?r 4))
=>
(modify ?target (assembled FALSE) (dist 999) (N-wall ?w) (E-wall ?n) (S-wall ?e) (W-wall ?s) (num_rots (+ ?r 1)))
(modify ?other_rot (num_rots 0))
(assert (cut-tile (id ?t-id)))
)


;; VALIDATE ASSEMBLY: Assert whether the map could be successfully assembled as a
;; graph connecting start and goal tiles at a minimum distance.
(defrule validate-assembly
(declare (salience -30))
(tile (id GOAL) (assembled TRUE))
(tile (id ?id1) (x ?x) (z ?z))
(not (tile (id ?id2&~?id1) (x ?x) (z ?z)))
=>
(assert (assembly-result (successful TRUE)))
)

(defrule invalidate-assembly
(declare (salience -30))
(tile (id ?id1) (x ?x) (z ?z))
(or (tile (id GOAL) (assembled FALSE)) (not (tile (id ?id2&~id1) (x ?x) (z ?z))))
=>
(assert (assembly-result (successful FALSE)))
)

(defrule modify-assembly
(declare (salience -30))
(assembly-result (successful TRUE))
?f <- (assembly-result (successful FALSE))
=>
(retract ?f)
)




;; BACKFILL: Create and join dead-end tiles to remaining openings on the map

(defrule backfill-N
(declare (salience -40))
(assembly-result (successful TRUE))
?n <- (tile (id ?t-id) (assembled TRUE) (x ?x) (z ?z) (N-wall OPEN) (N-tile nil))
(not (tile (id ~?t-id) (x ?x) (z =(+ ?z 1))))
=>
(bind ?back-id (str-cat "backfill-N-" (gensym)))
(assert (tile (id ?back-id) (S-wall OPEN) (S-tile ?t-id)))
(modify ?n (N-tile ?back-id))
)

(defrule backfill-S
(declare (salience -40))
(assembly-result (successful TRUE))
?s <- (tile (id ?t-id) (assembled TRUE) (x ?x) (z ?z) (S-wall OPEN) (S-tile nil))
(not (tile (id ~?t-id) (x ?x) (z =(- ?z 1))))
=>
(bind ?back-id (str-cat "backfill-S-" (gensym)))
(assert (tile (id ?back-id) (N-wall OPEN) (N-tile ?t-id)))
(modify ?s (S-tile ?back-id))
)

(defrule backfill-E
(declare (salience -40))
(assembly-result (successful TRUE))
?e <- (tile (id ?t-id) (assembled TRUE) (x ?x) (z ?z) (E-wall OPEN) (E-tile nil))
(not (tile (id ~?t-id) (x =(+ ?x 1)) (z ?z)))
=>
(bind ?back-id (str-cat "backfill-E-" (gensym)))
(assert (tile (id ?back-id) (W-wall OPEN) (W-tile ?t-id)))
(modify ?e (E-tile ?back-id))
)

(defrule backfill-W
(declare (salience -40))
(assembly-result (successful TRUE))
?w <- (tile (id ?t-id) (assembled TRUE) (x ?x) (z ?z) (W-wall OPEN) (W-tile nil))
(not (tile (id ~?t-id) (x =(- ?x 1)) (z ?z)))
=>
(bind ?back-id (str-cat "backfill-W-" (gensym)))
(assert (tile (id ?back-id) (E-wall OPEN) (E-tile ?t-id)))
(modify ?w (W-tile ?back-id))
)


;; PRINT CONNECTIONS: Print out the graph to the command line as a set of binary relations

(defrule print-NS-assembly
(declare (salience -50))
(assembly-result (successful TRUE))
(tile (id ?t-id) (assembled TRUE) (x ?x1) (z ?z1))
(tile (id ?t-id-2) (N-tile ?t-id) (assembled TRUE) (x ?x2) (z ?z2))
=>
(printout t ?t-id " (" ?x1 "," ?z1 ") to " ?t-id-2 " (" ?x2 "," ?z2 ")" crlf)
)

(defrule print-EW-assembly
(declare (salience -50))
(assembly-result (successful TRUE))
(tile (id ?t-id) (assembled TRUE) (x ?x1) (z ?z1))
(tile (id ?t-id-2) (E-tile ?t-id) (assembled TRUE) (x ?x2) (z ?z2))
=>
(printout t ?t-id " (" ?x1 "," ?z1 ") to " ?t-id-2 " (" ?x2 "," ?z2 ")" crlf)
)

(defrule print-N-open
(declare (salience -50))
(assembly-result (successful TRUE))
(tile (id ?t-id) (assembled TRUE) (N-wall OPEN) (N-tile nil))
=>
(printout t ?t-id " has an opening to the north" crlf)
)

(defrule print-E-open
(declare (salience -50))
(assembly-result (successful TRUE))
(tile (id ?t-id) (assembled TRUE) (E-wall OPEN) (E-tile nil))
=>
(printout t ?t-id " has an opening to the east" crlf)
)

(defrule print-S-open
(declare (salience -50))
(assembly-result (successful TRUE))
(tile (id ?t-id) (assembled TRUE) (S-wall OPEN) (S-tile nil))
=>
(printout t ?t-id " has an opening to the south" crlf)
)

(defrule print-W-open
(declare (salience -50))
(assembly-result (successful TRUE))
(tile (id ?t-id) (assembled TRUE) (W-wall OPEN) (W-tile nil))
=>
(printout t ?t-id " has an opening to the west" crlf)
)

(defrule print-leftover
(declare (salience -50))
(assembly-result (successful TRUE))
(tile (id ?t-id) (assembled FALSE))
=>
(printout t ?t-id " was not assembled." crlf)
)

(defrule print-failed
(declare (salience -50))
(assembly-result (successful ~TRUE))
=>
(printout t "Failed to assemble map. Please try adding more tiles or re-ordering the input sequence." crlf)
)


;; POSTPROCESS: Regroup multitiles for inclusion in the database
(defrule find-two-by-one
(declare (salience -80))
(assembly-result (successful TRUE))
?multitile <- (multitile (id ?m-id) (ht 2) (wid 1) (x_min 999))
(tile (id ?t-id) (assembled TRUE) (x ?x) (z ?z))
(test (eq (str-compare (str-cat ?m-id "_NORTH") ?t-id) 0))
=>
(modify ?multitile (x_min ?x) (x_max ?x) (z_min (- ?z 1)) (z_max ?z))
)

(defrule find-one-by-two
(declare (salience -80))
(assembly-result (successful TRUE))
?multitile <- (multitile (id ?m-id) (ht 1) (wid 2) (x_min 999))
(tile (id ?t-id) (assembled TRUE) (x ?x) (z ?z))
(test (eq (str-compare (str-cat ?m-id "_EAST") ?t-id) 0))
=>
(modify ?multitile (x_min (- ?x 1)) (x_max ?x) (z_min ?z) (z_max ?z))
)

(defrule find-two-by-two
(declare (salience -80))
(assembly-result (successful TRUE))
?multitile <- (multitile (id ?m-id) (ht 2) (wid 2) (x_min 999))
(tile (id ?t-id) (assembled TRUE) (x ?x) (z ?z))
(test (eq (str-compare (str-cat ?m-id "_NE") ?t-id) 0))
=>
(modify ?multitile (x_min (- ?x 1)) (x_max ?x) (z_min (- ?z 1)) (z_max ?z))
)


;; WRITE DB: Send tiles and multitiles to a file to be read into Unity3D

(defrule init-f-writer
(declare (salience -90))
(assembly-result (successful TRUE))
(output-file (dst ?dst))
(not (f-writer))
=>
(open ?dst writeFile "w")
(assert (f-ptr (name writeFile) (mode w)))
)

(defrule write-tile
(declare (salience -90))
(f-ptr (name ?writer) (mode w) (active TRUE))
?t <- (tile (id ?id) (x ?x) (z ?z) (num_rots ?r) (N-tile ?n) (S-tile ?s) (E-tile ?e) (W-tile ?w) (assembled TRUE))
=>
(printout t "Writing tile " ?id crlf)
(printout ?writer "tile," ?id "," ?x "," ?z "," ?r "," ?n "," ?s "," ?e "," ?w crlf)
)

(defrule write-multitile
(declare (salience -90))
(f-ptr (name ?writer) (mode w) (active TRUE))
?t <- (multitile (id ?id) (x_min ?xmin) (x_max ?xmax) (z_min ?zmin) (z_max ?zmax))
=>
(printout t "Writing multitile " ?id crlf)
(printout ?writer "multitile," ?id "," ?xmin "," ?xmax "," ?zmin "," ?zmax crlf)
)

(defrule close-f-writer
(declare (salience -91))
?f <- (f-ptr (name ?writer) (mode w) (active TRUE))
=>
(close ?writer)
(modify ?f (active FALSE))
)