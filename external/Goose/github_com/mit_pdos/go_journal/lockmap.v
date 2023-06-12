(* autogenerated from github.com/mit-pdos/go-journal/lockmap *)
From Perennial.goose_lang Require Import prelude.

Section code.
Context `{ext_ty: ext_types}.
Local Coercion Var' s: expr := Var s.

(* lockmap is a sharded lock map.

   The API is as if LockMap consisted of a lock for every possible uint64
   (which we think of as "addresses", but they could be any abstract location);
   LockMap.Acquire(a) acquires the lock associated with a and
   LockMap.Release(a) release it.

   The implementation doesn't actually maintain all of these locks; it
   instead maintains a fixed collection of shards so that shard i is
   responsible for maintaining the lock state of all a such that a % NSHARDS = i.
   Acquiring a lock requires synchronizing with any threads accessing the same
   shard. *)

Definition lockState := struct.decl [
  "held" :: boolT;
  "cond" :: ptrT;
  "waiters" :: uint64T
].

Definition lockShard := struct.decl [
  "mu" :: ptrT;
  "state" :: mapT ptrT
].

Definition mkLockShard: val :=
  rec: "mkLockShard" <> :=
    let: "state" := NewMap uint64T ptrT #() in
    let: "mu" := lock.new #() in
    let: "a" := struct.new lockShard [
      "mu" ::= "mu";
      "state" ::= "state"
    ] in
    "a".

Definition lockShard__acquire: val :=
  rec: "lockShard__acquire" "lmap" "addr" :=
    lock.acquire (struct.loadF lockShard "mu" "lmap");;
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "state" := ref (zero_val ptrT) in
      let: ("state1", "ok1") := MapGet (struct.loadF lockShard "state" "lmap") "addr" in
      (if: "ok1"
      then "state" <-[ptrT] "state1"
      else
        "state" <-[ptrT] struct.new lockState [
          "held" ::= #false;
          "cond" ::= lock.newCond (struct.loadF lockShard "mu" "lmap");
          "waiters" ::= #0
        ];;
        MapInsert (struct.loadF lockShard "state" "lmap") "addr" (![ptrT] "state"));;
      let: "acquired" := ref (zero_val boolT) in
      (if: ~ (struct.loadF lockState "held" (![ptrT] "state"))
      then
        struct.storeF lockState "held" (![ptrT] "state") #true;;
        "acquired" <-[boolT] #true
      else
        struct.storeF lockState "waiters" (![ptrT] "state") (struct.loadF lockState "waiters" (![ptrT] "state") + #1);;
        lock.condWait (struct.loadF lockState "cond" (![ptrT] "state"));;
        let: ("state2", "ok2") := MapGet (struct.loadF lockShard "state" "lmap") "addr" in
        (if: "ok2"
        then struct.storeF lockState "waiters" "state2" (struct.loadF lockState "waiters" "state2" - #1)
        else #()));;
      (if: ![boolT] "acquired"
      then Break
      else Continue));;
    lock.release (struct.loadF lockShard "mu" "lmap");;
    #().

Definition lockShard__release: val :=
  rec: "lockShard__release" "lmap" "addr" :=
    lock.acquire (struct.loadF lockShard "mu" "lmap");;
    let: "state" := Fst (MapGet (struct.loadF lockShard "state" "lmap") "addr") in
    struct.storeF lockState "held" "state" #false;;
    (if: struct.loadF lockState "waiters" "state" > #0
    then lock.condSignal (struct.loadF lockState "cond" "state")
    else MapDelete (struct.loadF lockShard "state" "lmap") "addr");;
    lock.release (struct.loadF lockShard "mu" "lmap");;
    #().

Definition NSHARD : expr := #65537.

Definition LockMap := struct.decl [
  "shards" :: slice.T ptrT
].

Definition MkLockMap: val :=
  rec: "MkLockMap" <> :=
    let: "shards" := ref (zero_val (slice.T ptrT)) in
    let: "i" := ref_to uint64T #0 in
    (for: (λ: <>, ![uint64T] "i" < NSHARD); (λ: <>, "i" <-[uint64T] ![uint64T] "i" + #1) := λ: <>,
      "shards" <-[slice.T ptrT] SliceAppend ptrT (![slice.T ptrT] "shards") (mkLockShard #());;
      Continue);;
    let: "a" := struct.new LockMap [
      "shards" ::= ![slice.T ptrT] "shards"
    ] in
    "a".

Definition LockMap__Acquire: val :=
  rec: "LockMap__Acquire" "lmap" "flataddr" :=
    let: "shard" := SliceGet ptrT (struct.loadF LockMap "shards" "lmap") ("flataddr" `rem` NSHARD) in
    lockShard__acquire "shard" "flataddr";;
    #().

Definition LockMap__Release: val :=
  rec: "LockMap__Release" "lmap" "flataddr" :=
    let: "shard" := SliceGet ptrT (struct.loadF LockMap "shards" "lmap") ("flataddr" `rem` NSHARD) in
    lockShard__release "shard" "flataddr";;
    #().

End code.
