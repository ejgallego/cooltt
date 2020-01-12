%{
  open ConcreteSyntax
%}

%token <int> NUMERAL
%token <string> ATOM
%token <string option> HOLE_NAME
%token COLON PIPE AT COMMA RIGHT_ARROW RRIGHT_ARROW UNDERSCORE
%token LPR RPR LBR RBR LSQ RSQ
%token EQUALS
%token UNIV
%token TIMES FST SND
%token LAM LET IN 
%token SUC NAT ZERO UNFOLD
%token QUIT NORMALIZE DEF
%token ID REFL ELIM
%token EOF

%start <ConcreteSyntax.signature> sign
%%

name:
  | s = ATOM
    { s }
  | UNDERSCORE
    { "_" }

decl:
  | DEF; nm = name; COLON; tp = term; EQUALS; body = term
    { Def {name = nm; def = body; tp} }
  | QUIT
    { Quit }
  | NORMALIZE; tm = term
    { NormalizeTerm tm }

sign:
  | EOF
    { [] }
  | d = decl; s = sign
    { d :: s }

atomic:
  | LBR; term = term; RBR
    { term }
  | a = ATOM
    { Var a }
  | ZERO
    { Lit 0 }
  | n = NUMERAL
    { Lit n }
  | NAT
    { Nat }
  | REFL
    { Refl }
  | UNIV 
    { Univ }
  | LSQ; left = term; COMMA; right = term; RSQ
    { Pair (left, right) }
  | name = HOLE_NAME
    { Hole name }
  | UNDERSCORE 
    { Underscore }

spine:
  | t = atomic 
    { Term t }

term:
  | f = atomic; args = list(spine)
    { match args with [] -> f | _ -> Ap (f, args) }
  | UNFOLD; names = nonempty_list(name); IN; body = term; 
    { Unfold (names, body) }
  | LET; name = name; COLON; tp = term; EQUALS; def = term; IN; body = term
    { Let (Ann {term = def; tp}, B {name; body}) }
  | LET; name = name; EQUALS; def = term; IN; body = term
    { Let (def, B {name; body}) }
  | LPR t = term; AT; tp = term RPR
    { Ann {term = t; tp} }
  | SUC; t = term
    { Suc t }
  | ID; tp = atomic; left = atomic; right = atomic
    { Id (tp, left, right) }
  | LAM; names = list(name); RRIGHT_ARROW; body = term
    { Lam (BN {names; body}) }
  | LAM; ELIM; cases = cases 
    { LamElim cases }
  | ELIM; scrut = term; AT; mot = motive; cases = cases 
    { Elim {mot; cases; scrut}}
  | tele = nonempty_list(tele_cell); RIGHT_ARROW; cod = term
    { Pi (tele, cod) }
  | tele = nonempty_list(tele_cell); TIMES; cod = term
    { Sg (tele, cod) }
  | dom = atomic RIGHT_ARROW; cod = term
    { Pi ([Cell {name = ""; tp = dom}], cod) }
  | dom = atomic; TIMES; cod = term
    { Sg ([Cell {name = ""; tp = dom}], cod) }
  | FST; t = term 
    { Fst t }
  | SND; t = term 
    { Snd t }

motive:
  | LBR names = list(name) RRIGHT_ARROW body = term RBR
    { BN {names; body} }

cases:
  | LSQ option(PIPE) cases = separated_list(PIPE, case) RSQ 
    { cases }

case: 
  | p = pat RRIGHT_ARROW t = term 
    { p, t }

pat_lbl:
  | REFL
    { "refl" }
  | ZERO 
    { "zero" }
  | SUC 
    { "suc" }
  | lbl = ATOM 
    { lbl }
  

pat:
  | lbl = pat_lbl args = list(pat_arg)
   { Pat {lbl; args} } 

pat_arg:
  | ident = name
    { `Simple (Some ident) }
  | LBR i0 = name RRIGHT_ARROW i1 = name RBR 
    { `Inductive (Some i0, Some i1) }

tele_cell:
  | LPR name = name; COLON tp = term; RPR
    { Cell {name; tp} }
