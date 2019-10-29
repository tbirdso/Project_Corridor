;; Name:	Tom Birdsong
;; Course:	ECE 4420 F19
;; Project:	Takehome 1
;; Summary:	CLIPS procedural generation map assembler

;; Templates
(deftemplate tile 
	(slot id)
	(slot type)
	(slot ht (type NUMBER) (default 1))
	(slot wid (type NUMBER) (default 1))
	(slot N-tile)
	(slot E-tile)
	(slot W-tile)
	(slot S-tile)
	(slot N-wall)
	(slot E-wall)
	(slot W-wall)
	(slot S-wall)
	(slot x (type NUMBER) (default 999))
	(slot z (type NUMBER) (default 999))
	(slot dist (type NUMBER))
	(slot num_rots (type NUMBER) (default 0))
	(slot assembled (default FALSE)))

(deftemplate multitile
	(slot id)
	(slot type)
	(slot ht (type NUMBER) (default 0))
	(slot wid (type NUMBER) (default 0))
	(slot x_min (type NUMBER) (default 999))
	(slot x_max (type NUMBER) (default 999))
	(slot z_min (type NUMBER) (default 999))
	(slot z_max (type NUMBER) (default 999))
	(slot assembled (default FALSE)))

(deftemplate verify-coords
	(slot x (type NUMBER) (default 999))
	(slot z (type NUMBER) (default 999))
)

(deftemplate params (slot min_dist (type NUMBER) (default 1)))

(deftemplate db-status (slot valid))
(deftemplate assembly-result (slot successful))
(deftemplate cut-tile (slot id))


;; Initial check for adequate tiles

(defrule validate-init-db
(declare (salience 99))
(and (tile (id START)) (tile (id GOAL)))
=>
(assert (db-status (valid TRUE)))
)

(defrule invalidate-init-db
(not (and (tile (id START)) (tile (id GOAL))))
=>
(printout t "Invalid starting database! Need a START, a GOAL, and at least n tiles." crlf)
(assert (db-status (valid FALSE)))
)




;; Break large tiles into manageable pieces

(defrule break-two-by-one
(declare (salience 20))
?tall-tile <- (tile (id ?t-id) (type ?type) (ht 2) (wid 1) (N-wall ?n) (S-wall ?s) (E-wall ?e) (W-wall ?w))
=>
(bind ?n-name (str-cat ?t-id "_NORTH"))
(bind ?s-name (str-cat ?t-id "_SOUTH"))
(assert (tile (id ?n-name) (type ?type) (ht 1) (wid 1) (N-wall ?n) (S-wall OPEN) (S-tile ?s-name) (E-wall ?e) (W-wall CLOSED)))
(assert (tile (id ?s-name) (type ?type) (ht 1) (wid 1) (N-wall OPEN) (N-tile ?n-name) (S-wall ?s) (E-wall CLOSED) (W-wall ?w)))
(assert (multitile (id ?t-id) (type ?type) (ht 2) (wid 1)))
(retract ?tall-tile)
)

(defrule break-one-by-two
(declare (salience 20))
?long-tile <- (tile (id ?t-id) (type ?type) (ht 1) (wid 2) (N-wall ?n) (S-wall ?s) (E-wall ?e) (W-wall ?w))
=>
(bind ?e-name (str-cat ?t-id "_EAST"))
(bind ?w-name (str-cat ?t-id "_WEST"))
(assert (tile (id ?w-name) (type ?type) (ht 1) (wid 1) (N-wall ?n) (S-wall CLOSED) (E-wall OPEN) (E-tile ?e-name) (W-wall ?w)))
(assert (tile (id ?e-name) (type ?type) (ht 1) (wid 1) (N-wall CLOSED) (S-wall ?s) (E-wall ?e) (W-wall OPEN) (W-tile ?w-name)))
(assert (multitile (id ?t-id) (type ?type) (ht 1) (wid 2)))
(retract ?long-tile)
)

(defrule break-two-by-two
(declare (salience 20))
?square-tile <- (tile (id ?t-id) (type ?type) (ht 2) (wid 2) (N-wall ?n) (S-wall ?s) (E-wall ?e) (W-wall ?w))
=>
(bind ?nw-name (str-cat ?t-id "_NW"))
(bind ?ne-name (str-cat ?t-id "_NE"))
(bind ?se-name (str-cat ?t-id "_SE"))
(bind ?sw-name (str-cat ?t-id "_SW"))
(assert (tile (id ?nw-name) (type ?type) (ht 1) (wid 1) (N-wall ?n) (S-wall OPEN) (S-tile ?sw-name) (E-wall OPEN) (E-tile ?ne-name) (W-wall CLOSED)))
(assert (tile (id ?ne-name) (type ?type) (ht 1) (wid 1) (N-wall CLOSED) (E-wall ?e) (S-wall OPEN) (S-tile ?se-name) (W-wall OPEN) (W-tile ?nw-name)))
(assert (tile (id ?se-name) (type ?type) (ht 1) (wid 1) (N-wall OPEN) (N-tile ?ne-name) (E-wall CLOSED) (S-wall ?s) (W-wall OPEN) (W-tile ?sw-name)))
(assert (tile (id ?sw-name) (type ?type) (ht 1) (wid 1) (N-wall OPEN) (N-tile ?nw-name) (E-wall OPEN) (E-tile ?se-name) (S-wall CLOSED) (W-wall ?w)))
(assert (multitile (id ?t-id) (type ?type) (ht 2) (wid 2)))
(retract ?square-tile)
)

;; TODO: make goal 3x3

;; TODO: cut tile


;; verify no overlaps
(defrule verify-no-overlap
(declare (salience 15))
?vc <- (verify-coords (x ?x) (z ?z))
?c_tile <- (tile (id ?t-id) (x ?x) (z ?z))
(not (tile (id ~?t-id) (x ?x) (z ?z)))
=>
(retract ?vc)
)

;;todo: circular
(defrule fix-overlap
(declare (salience 15))
?vc <- (verify-coords (x ?x) (z ?z))
?c_tile <- (tile (id ?t-id) (x ?x) (z ?z))
(tile (id ~?t-id) (x ?x) (z ?z))
=>
(modify ?c_tile (x 999) (z 999) (assembled FALSE) (N-tile nil) (E-tile nil) (S-tile nil) (W-tile nil))
(retract ?vc)
)



;; If tiles were previously attached to each other before being assembled into the map make sure the adjacent tiles are marked appropriately
(defrule mark-N
(declare (salience 11))
(tile (assembled TRUE) (N-tile ?t-id&~nil) (x ?x) (z ?z) (dist ?d))
?adj-tile <- (tile (id ?t-id) (assembled FALSE))
=>
(modify ?adj-tile (assembled TRUE) (x ?x) (z (+ ?z 1)) (dist (+ ?d 1)))
)

(defrule mark-S
(declare (salience 11))
(tile (assembled TRUE) (S-tile ?t-id&~nil) (x ?x) (z ?z) (dist ?d))
?adj-tile <- (tile (id ?t-id) (assembled FALSE))
=>
(modify ?adj-tile (assembled TRUE) (x ?x) (z (- ?z 1)) (dist (+ ?d 1)))
)

(defrule mark-E
(declare (salience 11))
(tile (assembled TRUE) (E-tile ?t-id&~nil) (x ?x) (z ?z) (dist ?d))
?adj-tile <- (tile (id ?t-id) (assembled FALSE))
=>
(modify ?adj-tile (assembled TRUE) (x (+ ?x 1)) (z ?z) (dist (+ ?d 1)))
)

(defrule mark-W
(declare (salience 11))
(tile (assembled TRUE) (W-tile ?t-id&~nil) (x ?x) (z ?z) (dist ?d))
?adj-tile <- (tile (id ?t-id) (assembled FALSE))
=>
(modify ?adj-tile (assembled TRUE) (x (- ?x 1)) (z ?z) (dist (+ ?d 1)))
)



;; Assemble tiles

;; Mark start as first assembled tiles
(defrule start-assemble
(declare (salience 10))
(exists (db-status (valid TRUE)))
?start-tile <- (tile (id START) (assembled FALSE))
=>
(modify ?start-tile (assembled TRUE) (dist 0) (x 0) (z 0))
)

;; Attach tile with S opening to assembly with N opening
(defrule attach-S-to-N
(declare (salience 10))
(exists (db-status (valid TRUE)))
(params (min_dist ?m_dist))
?south-tile <- (tile (id ?s-id) (N-wall OPEN) (assembled FALSE))
?north-tile <- (tile (id ?n-id) (S-wall OPEN) (S-tile nil) (assembled TRUE) (dist ?d) (x ?x) (z ?z))
(or (tile (id ?s-id&~GOAL)) (test (>= ?d ?m_dist)))
(not (tile (id ~?s-id) (x ?x) (z =(- ?z 1))))
=>
(modify ?north-tile (S-tile ?s-id))
(modify ?south-tile (N-tile ?n-id) (assembled TRUE) (dist (+ ?d 1)) (x ?x) (z (- ?z 1)))
(assert (verify-coords (x ?x) (z (- ?z 1))))
) 

;; Attach tile with N opening to assembly with S opening
(defrule attach-N-to-S
(declare (salience 10))
(exists (db-status (valid TRUE)))
(params (min_dist ?m_dist))
?south-tile <- (tile (id ?s-id) (N-wall OPEN) (N-tile nil) (assembled TRUE) (dist ?d) (x ?x) (z ?z))
?north-tile <- (tile (id ?n-id) (S-wall OPEN) (S-tile nil) (assembled FALSE))
(or (tile (id ?n-id&~GOAL&~"GOAL_NW"&~"GOAL_NE"&~"GOAL_SE"&~"GOAL_SW")) (test (> ?d ?m_dist)))
(not (tile (id ~?n-id) (x ?x) (z =(+ ?z 1))))
=>
(modify ?north-tile (S-tile ?s-id) (assembled TRUE) (dist (+ ?d 1)) (x ?x) (z (+ ?z 1)))
(modify ?south-tile (N-tile ?n-id))
(assert (verify-coords (x ?x) (z (+ ?z 1))))
)

;; Attach tile with W opening to assembly with E opening
(defrule attach-W-to-E
(declare (salience 10))
(exists (db-status (valid TRUE)))
(params (min_dist ?m_dist))
?east-tile <- (tile (id ?e-id) (W-wall OPEN) (W-tile nil) (assembled TRUE) (dist ?d) (x ?x) (z ?z))
?west-tile <- (tile (id ?w-id) (E-wall OPEN) (E-tile nil) (assembled FALSE))
(or (tile (id ?w-id&~GOAL)) (test (> ?d ?m_dist)))
(not (tile (id ~?w-id) (x =(- ?x 1)) (z ?z)))
=>
(modify ?east-tile (W-tile ?w-id))
(modify ?west-tile (E-tile ?e-id) (assembled TRUE) (dist (+ ?d 1)) (x (- ?x 1)) (z ?z))
(assert (verify-coords (x (- ?x 1)) (z ?z)))
)

;; Attach tile with W opening to assembly with E opening
(defrule attach-E-to-W
(declare (salience 10))
(exists (db-status (valid TRUE)))
(params (min_dist ?m_dist))
?east-tile <- (tile (id ?e-id) (W-wall OPEN) (W-tile nil) (assembled FALSE))
?west-tile <- (tile (id ?w-id) (E-wall OPEN) (E-tile nil) (assembled TRUE) (x ?x) (z ?z) (dist ?d))
(or (tile (id ?e-id&~GOAL)) (test (> ?d ?m_dist)))
(not (tile (id ~?e-id) (x =(+ ?x 1)) (z ?z)))
=>
(modify ?west-tile (E-tile ?e-id))
(modify ?east-tile (W-tile ?w-id) (assembled TRUE) (dist (+ ?d 1)) (x (+ ?x 1)) (z ?z))
(assert (verify-coords (x (+ ?x 1)) (z ?z)))
)


;; FIXME: flag tiles occupying same space
(defrule print-overlap
(declare (salience 10))
(tile (id ?t1) (x ?x&~999) (z ?z&~999))
(tile (id ?t2&~?t1) (x ?x) (z ?z))
=>
(printout t ?t1 " and " ?t2 " occupy " ?x " " ?z crlf)
)



;; TODO: reevaluate distances via adjacencies




;; Validate that map assembly successfully connected start and goal tiles
(defrule validate-assembly
(declare (salience 1))
(tile (id GOAL) (assembled TRUE))
(tile (id ?id1) (x ?x) (z ?z))
(not (tile (id ?id2&~?id1) (x ?x) (z ?z)))
=>
(assert (assembly-result (successful TRUE)))
)

(defrule invalidate-assembly
(declare (salience 1))
(tile (id ?id1) (x ?x) (z ?z))
(or (tile (id GOAL) (assembled FALSE)) (not (tile (id ?id2&~id1) (x ?x) (z ?z))))
=>
(assert (assembly-result (successful FALSE)))
)

(defrule modify-assembly
(declare (salience 1))
?f <- (assembly-result (successful FALSE))
(assembly-result (successful TRUE))
=>
(retract ?f)
)



;; try rotating unused tiles if map has not been successfully assembled
;; note: only applies to 1x1 tiles not decomposed from larger rooms

(defrule rotate-tile
(declare (salience -10))
(assembly-result (successful FALSE))
?target <- (tile (assembled FALSE) (N-wall ?n) (E-wall ?e) (S-wall ?s) (W-wall ?w) (N-tile nil) (E-tile nil) (S-tile nil) (W-tile nil) (num_rots ?r))
(test (< ?r 4))
=>
(modify ?target (N-wall ?w) (E-wall ?n) (S-wall ?e) (W-wall ?s) (num_rots (+ ?r 1)))
)


;; TODO try detaching tiles and rotating if map has not been successfully assembled
(defrule detach-and-rotate-tile
(declare (salience -11))
(assembly-result (successful FALSE))
?target <- (tile (id ?t-id) (assembled TRUE) (N-wall ?n) (E-wall ?e) (S-wall ?s) (W-wall ?w) (dist ?d) (num_rots ?r))
?other_rot <- (tile (assembled FALSE) (num_rots ?r_1))
(not (exists (tile (dist =(+ ?d 1)))))
(test (< ?r 4))
=>
(modify ?target (assembled FALSE) (dist 999) (N-wall ?w) (E-wall ?n) (S-wall ?e) (W-wall ?s) (num_rots (+ ?r 1)))
(modify ?other_rot (num_rots 0))
(assert (cut-tile (id ?t-id)))
)


;; print assembly

(defrule print-NS-assembly
(declare (salience -20))
(assembly-result (successful TRUE))
(tile (id ?t-id) (assembled TRUE))
(tile (id ?t-id-2) (N-tile ?t-id) (assembled TRUE))
=>
(printout t ?t-id " to " ?t-id-2 crlf)
)

(defrule print-EW-assembly
(declare (salience -20))
(assembly-result (successful TRUE))
(tile (id ?t-id) (assembled TRUE))
(tile (id ?t-id-2) (E-tile ?t-id) (assembled TRUE))
=>
(printout t ?t-id " to " ?t-id-2 crlf)
)

(defrule print-N-open
(declare (salience -20))
(assembly-result (successful TRUE))
(tile (id ?t-id) (assembled TRUE) (N-wall OPEN) (N-tile nil))
=>
(printout t ?t-id " has an opening to the north" crlf)
)

(defrule print-E-open
(declare (salience -20))
(assembly-result (successful TRUE))
(tile (id ?t-id) (assembled TRUE) (E-wall OPEN) (E-tile nil))
=>
(printout t ?t-id " has an opening to the east" crlf)
)

(defrule print-S-open
(declare (salience -20))
(assembly-result (successful TRUE))
(tile (id ?t-id) (assembled TRUE) (S-wall OPEN) (S-tile nil))
=>
(printout t ?t-id " has an opening to the south" crlf)
)

(defrule print-W-open
(declare (salience -20))
(assembly-result (successful TRUE))
(tile (id ?t-id) (assembled TRUE) (W-wall OPEN) (W-tile nil))
=>
(printout t ?t-id " has an opening to the west" crlf)
)


(defrule print-failed
(declare (salience -20))
(assembly-result (successful ~TRUE))
=>
(printout t "Failed to assemble map. Please try adding more tiles or re-ordering the input sequence." crlf)
)



;; Find multitiles to pass back
(defrule find-two-by-one
(declare (salience -30))
?multitile <- (multitile (id ?m-id) (ht 2) (wid 1) (x_min 999))
(tile (id ?t-id) (assembled TRUE) (x ?x) (z ?z))
(test (eq (str-compare (str-cat ?m-id "_NORTH") ?t-id) 0))
=>
(modify ?multitile (x_min ?x) (x_max ?x) (z_min (- ?z 1)) (z_max ?z))
)

(defrule find-one-by-two
(declare (salience -30))
?multitile <- (multitile (id ?m-id) (ht 1) (wid 2) (x_min 999))
(tile (id ?t-id) (assembled TRUE) (x ?x) (z ?z))
(test (eq (str-compare (str-cat ?m-id "_EAST") ?t-id) 0))
=>
(modify ?multitile (x_min (- ?x 1)) (x_max ?x) (z_min ?z) (z_max ?z))
)

(defrule find-two-by-two
(declare (salience -30))
?multitile <- (multitile (id ?m-id) (ht 2) (wid 2) (x_min 999))
(tile (id ?t-id) (assembled TRUE) (x ?x) (z ?z))
(test (eq (str-compare (str-cat ?m-id "_NE") ?t-id) 0))
=>
(modify ?multitile (x_min (- ?x 1)) (x_max ?x) (z_min (- ?z 1)) (z_max ?z))
)

;; Pass in ordered list of tiles

(deffacts startup
(params (min_dist 2))
(tile (id START) (type room) (ht 1) (wid 1) (N-wall CLOSED) (S-wall OPEN) (E-wall CLOSED) (W-wall CLOSED))
(tile (id GOAL) (type room) (ht 1) (wid 1) (N-wall CLOSED) (S-wall CLOSED) (E-wall CLOSED) (W-wall OPEN))
(tile (id 0110) (type room) (ht 1) (wid 1) (N-wall OPEN) (S-wall CLOSED) (E-wall CLOSED) (W-wall OPEN))
(tile (id 1001) (type room) (ht 1) (wid 1) (N-wall CLOSED) (S-wall OPEN) (E-wall OPEN) (W-wall CLOSED))
(tile (id 0111) (type room) (ht 1) (wid 1) (N-wall OPEN) (S-wall CLOSED) (E-wall CLOSED) (W-wall CLOSED))
)

