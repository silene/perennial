(* autogenerated from lockservice *)
From Perennial.goose_lang Require Import prelude.
From Perennial.goose_lang Require Import ffi.disk_prelude.

(* nondet.go *)

Definition nondet: val :=
  rec: "nondet" <> :=
    #true.
