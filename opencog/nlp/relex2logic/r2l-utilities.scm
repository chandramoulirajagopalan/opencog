;
; relex2logic/utilities.scm
;
; Assorted utilties for checking R2L outputs.
;
(use-modules (srfi srfi-1))

(use-modules (opencog))
(use-modules (opencog atom-types))
(use-modules (opencog exec))

; -----------------------------------------------------------------------
(define-public (r2l-get-root atom)
"
  r2l-get-root -- Return all hypergraph R2L roots containing 'atom'

  Similar to cog-get-root, except that it will stop at the SetLink,
  in the case where RelEx2Logic is called with the r2l(...) function.
"
	(define iset (cog-incoming-set atom))

	; Halt when the SetLink that wraps around R2L outputs is reached.
	; The SetLink is created by r2l(...)
	(if (and (= (length iset) 1) (equal? 'SetLink (cog-type (car iset))))
		(list atom)
		; if no incoming set (happens when using relex-parse(...))
		(if (null? iset)
			(list atom)
			(append-map r2l-get-root iset)
		)
	)
)

; -----------------------------------------------------------------------
(define-public (r2l-get-word-inst node)
"
  r2l-get-word-inst -- Retrieve WordInstanceNode given R2L style node

  Given a R2L style node, find the corresponding WordInstanceNode.
"
	(cond ((null? node) '())
	      ((has-word-inst? node) (car (cog-chase-link 'ReferenceLink 'WordInstanceNode node)))
	      (else '())
	)
)

; -----------------------------------------------------------------------
(define-public (r2l-get-word node)
"
  r2l-get-word -- Retrieve WordNode given R2L style node

  Given a R2L style node, find the corresponding WordNode.  Skipping
  WordInstanceNode since maybe it is not an instanced word.
  XXX TODO: update this when non-instanced R2L node are linked to WordNode
"
	(cond ((null? node) '())
	      ((has-word? node) (cog-node 'WordNode (cog-name node)))
	      (else '())
	)
)

; -----------------------------------------------------------------------
(define-public (r2l-get-interp a-set-link)
"
  r2l-get-interp -- Retrieve the InterpretationNode given SetLink.

  Returns the InterpretationNode associated with the SetLink.
"
	(car (cog-chase-link 'ReferenceLink 'InterpretationNode a-set-link))
)

; -----------------------------------------------------------------------
(define-public (has-word-inst? node)
"
  has-word-inst? -- Check if a node has the corresponding WordInstanceNode

  Return #t or #f depends on whether the node has a WordInstanceNode.
"
	(if (cog-node? node)
		(not (null? (cog-chase-link 'ReferenceLink 'WordInstanceNode node)))
		#f)
)

; -----------------------------------------------------------------------
(define-public (has-word? node)
"
  has-word? -- Check if a node has the corresponding WordNode

  Return #t or #f depends on whether the node has a WordNode.
  TODO: update this when non-instanced R2L node are linked to WordNode
"
	(not (null? (cog-node 'WordNode (cog-name node))))
)

; -----------------------------------------------------------------------
(define-public (is-r2l-inst? node)
"
  is-r2l-inst? -- Check if a node is a R2L instanced node.

  Return #t or #f depends on whether the node is instanced.  VariableNode
  is also instanced node.
"
	(or (equal? 'VariableNode (cog-type node)) (has-word-inst? node))
)

; -----------------------------------------------------------------------
(define-public (is-r2l-abstract? node)
"
  is-r2l-abstract? -- Check if a node is a R2L abstract node.

  Return #t or #f depends on whether the node is the abstract version.
"
	(has-word? node)
)

; -----------------------------------------------------------------------
(define-public (filter-for-pln a-list)
"
  Takes a list of atoms and return a SetLink containing atoms that pln can
  reason on. The that make the SetLink comprise of atoms with signatures,
          (Inheritance
              (Type \"ConceptNode\")
              (Type \"ConceptNode\"))
          (Evaluation
              (Type \"PredicateNode\")
              (ListLink
                  (Type \"ConceptNode\")
                  (Type \"ConceptNode\")))
          (Evaluation
              (Type \"PredicateNode\")
              (ListLink
                  (Type \"ConceptNode\"))))
          (Member
              (TypeChoice
                  (Type \"ConceptNode\")
                  (Type \"SatisfyingSetLink\"))
              (TypeChoice
                  (Type \"ConceptNode\")
                  (Type \"SatisfyingSetLink\")))

  a-list:
  - This is a list of atoms, for example a list of r2l outputs
"
; TODO: Move this to an (opencog pln) module, when there is one.
    (cog-execute!
        (MapLink
            (ScopeLink
                (TypedVariable
                    (Variable "$x")
                    (TypeChoice
                        (Signature
                            (Inheritance
                                (TypeChoice
                                    (Type "ConceptNode")
                                    (Type "SatisfyingSetLink"))
                                (TypeChoice
                                    (Type "ConceptNode")
                                    (Type "SatisfyingSetLink"))))
                        (Signature
                            (Member
                                (TypeChoice
                                    (Type "ConceptNode")
                                    (Type "SatisfyingSetLink"))
                                (TypeChoice
                                    (Type "ConceptNode")
                                    (Type "SatisfyingSetLink"))))
                        (Signature
                            (Evaluation
                                (Type "PredicateNode")
                                (ListLink
                                    (Type "ConceptNode")
                                    (Type "ConceptNode"))))
                        (Signature
                            (Evaluation
                                (Type "PredicateNode")
                                (ListLink
                                    (Type "ConceptNode"))))))
                    (Variable "$x"))
            (SetLink  a-list))
    )
)

; -----------------------------------------------------------------------
