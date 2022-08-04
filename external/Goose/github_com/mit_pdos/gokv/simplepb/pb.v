(* autogenerated from github.com/mit-pdos/gokv/simplepb/pb *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.goose_lang.std.
From Goose Require github_com.mit_pdos.gokv.simplepb.e.
From Goose Require github_com.mit_pdos.gokv.urpc.
From Goose Require github_com.tchajed.marshal.

From Perennial.goose_lang Require Import ffi.grove_prelude.

(* 0_marshal.go *)

Definition Op: ty := slice.T byteT.

Definition ApplyArgs := struct.decl [
  "epoch" :: uint64T;
  "index" :: uint64T;
  "op" :: slice.T byteT
].

Definition EncodeApplyArgs: val :=
  rec: "EncodeApplyArgs" "args" :=
    let: "enc" := ref_to (slice.T byteT) (NewSliceWithCap byteT #0 (#8 + #8 + slice.len (struct.loadF ApplyArgs "op" "args"))) in
    "enc" <-[slice.T byteT] marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF ApplyArgs "epoch" "args");;
    "enc" <-[slice.T byteT] marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF ApplyArgs "index" "args");;
    "enc" <-[slice.T byteT] marshal.WriteBytes (![slice.T byteT] "enc") (struct.loadF ApplyArgs "op" "args");;
    ![slice.T byteT] "enc".

Definition DecodeApplyArgs: val :=
  rec: "DecodeApplyArgs" "enc_args" :=
    let: "enc" := ref_to (slice.T byteT) "enc_args" in
    let: "args" := struct.alloc ApplyArgs (zero_val (struct.t ApplyArgs)) in
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF ApplyArgs "epoch" "args" "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF ApplyArgs "index" "args" "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    struct.storeF ApplyArgs "op" "args" (![slice.T byteT] "enc");;
    "args".

Definition SetStateArgs := struct.decl [
  "Epoch" :: uint64T;
  "State" :: slice.T byteT
].

Definition EncodeSetStateArgs: val :=
  rec: "EncodeSetStateArgs" "args" :=
    let: "enc" := ref_to (slice.T byteT) (NewSliceWithCap byteT #0 (#8 + slice.len (struct.loadF SetStateArgs "State" "args"))) in
    "enc" <-[slice.T byteT] marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF SetStateArgs "Epoch" "args");;
    "enc" <-[slice.T byteT] marshal.WriteBytes (![slice.T byteT] "enc") (struct.loadF SetStateArgs "State" "args");;
    ![slice.T byteT] "enc".

Definition DecodeSetStateArgs: val :=
  rec: "DecodeSetStateArgs" "enc_args" :=
    let: "enc" := ref_to (slice.T byteT) "enc_args" in
    let: "args" := struct.alloc SetStateArgs (zero_val (struct.t SetStateArgs)) in
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF SetStateArgs "Epoch" "args" "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    struct.storeF SetStateArgs "State" "args" (![slice.T byteT] "enc");;
    "args".

Definition GetStateArgs := struct.decl [
  "Epoch" :: uint64T
].

Definition EncodeGetStateArgs: val :=
  rec: "EncodeGetStateArgs" "args" :=
    let: "enc" := ref_to (slice.T byteT) (NewSliceWithCap byteT #0 #8) in
    "enc" <-[slice.T byteT] marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF GetStateArgs "Epoch" "args");;
    ![slice.T byteT] "enc".

Definition DecodeGetStateArgs: val :=
  rec: "DecodeGetStateArgs" "enc" :=
    let: "args" := struct.alloc GetStateArgs (zero_val (struct.t GetStateArgs)) in
    let: ("0_ret", "1_ret") := marshal.ReadInt "enc" in
    struct.storeF GetStateArgs "Epoch" "args" "0_ret";;
    "1_ret";;
    "args".

Definition GetStateReply := struct.decl [
  "Err" :: uint64T;
  "State" :: slice.T byteT
].

Definition EncodeGetStateReply: val :=
  rec: "EncodeGetStateReply" "reply" :=
    let: "enc" := ref_to (slice.T byteT) (NewSliceWithCap byteT #0 (#8 + slice.len (struct.loadF GetStateReply "State" "reply"))) in
    "enc" <-[slice.T byteT] marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF GetStateReply "Err" "reply");;
    "enc" <-[slice.T byteT] marshal.WriteBytes (![slice.T byteT] "enc") (struct.loadF GetStateReply "State" "reply");;
    ![slice.T byteT] "enc".

Definition DecodeGetStateReply: val :=
  rec: "DecodeGetStateReply" "enc_reply" :=
    let: "enc" := ref_to (slice.T byteT) "enc_reply" in
    let: "reply" := struct.alloc GetStateReply (zero_val (struct.t GetStateReply)) in
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF GetStateReply "Err" "reply" "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    struct.storeF GetStateReply "State" "reply" (![slice.T byteT] "enc");;
    "reply".

Definition BecomePrimaryArgs := struct.decl [
  "Epoch" :: uint64T;
  "Replicas" :: slice.T uint64T
].

Definition EncodeBecomePrimaryArgs: val :=
  rec: "EncodeBecomePrimaryArgs" "args" :=
    let: "enc" := ref_to (slice.T byteT) (NewSliceWithCap byteT #0 (#8 + #8 + #8 * slice.len (struct.loadF BecomePrimaryArgs "Replicas" "args"))) in
    "enc" <-[slice.T byteT] marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF BecomePrimaryArgs "Epoch" "args");;
    "enc" <-[slice.T byteT] marshal.WriteInt (![slice.T byteT] "enc") (slice.len (struct.loadF BecomePrimaryArgs "Replicas" "args"));;
    ForSlice uint64T <> "h" (struct.loadF BecomePrimaryArgs "Replicas" "args")
      ("enc" <-[slice.T byteT] marshal.WriteInt (![slice.T byteT] "enc") "h");;
    ![slice.T byteT] "enc".

Definition DecodeBecomePrimaryArgs: val :=
  rec: "DecodeBecomePrimaryArgs" "enc_args" :=
    let: "enc" := ref_to (slice.T byteT) "enc_args" in
    let: "args" := struct.alloc BecomePrimaryArgs (zero_val (struct.t BecomePrimaryArgs)) in
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF BecomePrimaryArgs "Epoch" "args" "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    let: "replicasLen" := ref (zero_val uint64T) in
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    "replicasLen" <-[uint64T] "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    struct.storeF BecomePrimaryArgs "Replicas" "args" (NewSlice uint64T (![uint64T] "replicasLen"));;
    ForSlice uint64T "i" <> (struct.loadF BecomePrimaryArgs "Replicas" "args")
      (let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
      SliceSet uint64T (struct.loadF BecomePrimaryArgs "Replicas" "args") "i" "0_ret";;
      "enc" <-[slice.T byteT] "1_ret");;
    "args".

(* clerk.go *)

Definition Clerk := struct.decl [
  "cl" :: ptrT
].

Definition RPC_APPLY : expr := #0.

Definition RPC_SETSTATE : expr := #1.

Definition RPC_GETSTATE : expr := #2.

Definition RPC_BECOMEPRIMARY : expr := #4.

Definition RPC_PRIMARYAPPLY : expr := #5.

Definition MakeClerk: val :=
  rec: "MakeClerk" "host" :=
    struct.new Clerk [
      "cl" ::= urpc.MakeClient "host"
    ].

Definition Clerk__Apply: val :=
  rec: "Clerk__Apply" "ck" "args" :=
    let: "reply" := ref (zero_val (slice.T byteT)) in
    let: "err" := urpc.Client__Call (struct.loadF Clerk "cl" "ck") RPC_APPLY (EncodeApplyArgs "args") "reply" #100 in
    (if: "err" ≠ #0
    then e.Timeout
    else e.DecodeError (![slice.T byteT] "reply")).

Definition Clerk__SetState: val :=
  rec: "Clerk__SetState" "ck" "args" :=
    let: "reply" := ref (zero_val (slice.T byteT)) in
    let: "err" := urpc.Client__Call (struct.loadF Clerk "cl" "ck") RPC_SETSTATE (EncodeSetStateArgs "args") "reply" #1000 in
    (if: "err" ≠ #0
    then e.Timeout
    else e.DecodeError (![slice.T byteT] "reply")).

Definition Clerk__GetState: val :=
  rec: "Clerk__GetState" "ck" "args" :=
    let: "reply" := ref (zero_val (slice.T byteT)) in
    let: "err" := urpc.Client__Call (struct.loadF Clerk "cl" "ck") RPC_GETSTATE (EncodeGetStateArgs "args") "reply" #1000 in
    (if: "err" ≠ #0
    then
      struct.new GetStateReply [
        "Err" ::= e.Timeout
      ]
    else DecodeGetStateReply (![slice.T byteT] "reply")).

Definition Clerk__BecomePrimary: val :=
  rec: "Clerk__BecomePrimary" "ck" "args" :=
    let: "reply" := ref (zero_val (slice.T byteT)) in
    let: "err" := urpc.Client__Call (struct.loadF Clerk "cl" "ck") RPC_BECOMEPRIMARY (EncodeBecomePrimaryArgs "args") "reply" #100 in
    (if: "err" ≠ #0
    then e.Timeout
    else e.DecodeError (![slice.T byteT] "reply")).

Definition Clerk__PrimaryApply: val :=
  rec: "Clerk__PrimaryApply" "ck" "op" :=
    let: "reply" := ref (zero_val (slice.T byteT)) in
    let: "err" := urpc.Client__Call (struct.loadF Clerk "cl" "ck") RPC_PRIMARYAPPLY "op" "reply" #200 in
    (if: ("err" = #0)
    then
      let: ("err", <>) := marshal.ReadInt (![slice.T byteT] "reply") in
      ("err", SliceSkip byteT (![slice.T byteT] "reply") #8)
    else ("err", slice.nil)).

(* server.go *)

Definition StateMachine := struct.decl [
  "Apply" :: (Op -> slice.T byteT)%ht;
  "SetState" :: (slice.T byteT -> unitT)%ht;
  "GetState" :: (unitT -> slice.T byteT)%ht;
  "EnterEpoch" :: (uint64T -> unitT)%ht
].

Definition Server := struct.decl [
  "mu" :: ptrT;
  "epoch" :: uint64T;
  "sm" :: ptrT;
  "nextIndex" :: uint64T;
  "isPrimary" :: boolT;
  "clerks" :: slice.T ptrT
].

(* called on the primary server to apply a new operation. *)
Definition Server__Apply: val :=
  rec: "Server__Apply" "s" "op" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    (if: ~ (struct.loadF Server "isPrimary" "s")
    then
      (* log.Println("Got request while not being primary") *)
      lock.release (struct.loadF Server "mu" "s");;
      (e.Stale, slice.nil)
    else
      let: "ret" := struct.loadF StateMachine "Apply" (struct.loadF Server "sm" "s") "op" in
      let: "nextIndex" := struct.loadF Server "nextIndex" "s" in
      struct.storeF Server "nextIndex" "s" (std.SumAssumeNoOverflow (struct.loadF Server "nextIndex" "s") #1);;
      let: "epoch" := struct.loadF Server "epoch" "s" in
      let: "clerks" := struct.loadF Server "clerks" "s" in
      lock.release (struct.loadF Server "mu" "s");;
      let: "wg" := waitgroup.New #() in
      let: "errs" := NewSlice uint64T (slice.len "clerks") in
      let: "args" := struct.new ApplyArgs [
        "epoch" ::= "epoch";
        "index" ::= "nextIndex";
        "op" ::= "op"
      ] in
      ForSlice ptrT "i" "clerk" "clerks"
        (let: "clerk" := "clerk" in
        let: "i" := "i" in
        waitgroup.Add "wg" #1;;
        Fork (SliceSet uint64T "errs" "i" (Clerk__Apply "clerk" "args");;
              waitgroup.Done "wg"));;
      waitgroup.Wait "wg";;
      let: "err" := ref_to uint64T e.None in
      let: "i" := ref_to uint64T #0 in
      Skip;;
      (for: (λ: <>, ![uint64T] "i" < slice.len "clerks"); (λ: <>, Skip) := λ: <>,
        let: "err2" := SliceGet uint64T "errs" (![uint64T] "i") in
        (if: "err2" ≠ e.None
        then "err" <-[uint64T] "err2"
        else #());;
        "i" <-[uint64T] ![uint64T] "i" + #1;;
        Continue);;
      (* log.Println("Apply() returned ", err) *)
      (![uint64T] "err", "ret")).

(* returns true iff stale *)
Definition Server__epochFence: val :=
  rec: "Server__epochFence" "s" "epoch" :=
    (if: struct.loadF Server "epoch" "s" < "epoch"
    then
      struct.storeF Server "epoch" "s" "epoch";;
      struct.loadF StateMachine "EnterEpoch" (struct.loadF Server "sm" "s") (struct.loadF Server "epoch" "s");;
      struct.storeF Server "isPrimary" "s" #false;;
      struct.storeF Server "nextIndex" "s" #0
    else #());;
    struct.loadF Server "epoch" "s" > "epoch".

(* called on backup servers to apply an operation so it is replicated and
   can be considered committed by primary. *)
Definition Server__ApplyAsBackup: val :=
  rec: "Server__ApplyAsBackup" "s" "args" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    (if: Server__epochFence "s" (struct.loadF ApplyArgs "epoch" "args")
    then
      lock.release (struct.loadF Server "mu" "s");;
      e.Stale
    else
      (if: struct.loadF ApplyArgs "index" "args" ≠ struct.loadF Server "nextIndex" "s"
      then
        lock.release (struct.loadF Server "mu" "s");;
        e.OutOfOrder
      else
        struct.loadF StateMachine "Apply" (struct.loadF Server "sm" "s") (struct.loadF ApplyArgs "op" "args");;
        struct.storeF Server "nextIndex" "s" (struct.loadF Server "nextIndex" "s" + #1);;
        lock.release (struct.loadF Server "mu" "s");;
        e.None)).

Definition Server__SetState: val :=
  rec: "Server__SetState" "s" "args" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    (if: struct.loadF Server "epoch" "s" > struct.loadF SetStateArgs "Epoch" "args"
    then
      lock.release (struct.loadF Server "mu" "s");;
      e.Stale
    else
      (if: (struct.loadF Server "epoch" "s" = struct.loadF SetStateArgs "Epoch" "args")
      then
        lock.release (struct.loadF Server "mu" "s");;
        e.None
      else
        struct.loadF StateMachine "SetState" (struct.loadF Server "sm" "s") (struct.loadF SetStateArgs "State" "args");;
        lock.release (struct.loadF Server "mu" "s");;
        e.None)).

Definition Server__GetState: val :=
  rec: "Server__GetState" "s" "args" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    (if: Server__epochFence "s" (struct.loadF GetStateArgs "Epoch" "args")
    then
      lock.release (struct.loadF Server "mu" "s");;
      struct.new GetStateReply [
        "Err" ::= e.Stale;
        "State" ::= slice.nil
      ]
    else
      let: "ret" := struct.loadF StateMachine "GetState" (struct.loadF Server "sm" "s") #() in
      lock.release (struct.loadF Server "mu" "s");;
      struct.new GetStateReply [
        "Err" ::= e.None;
        "State" ::= "ret"
      ]).

Definition Server__BecomePrimary: val :=
  rec: "Server__BecomePrimary" "s" "args" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    (if: Server__epochFence "s" (struct.loadF BecomePrimaryArgs "Epoch" "args")
    then
      (* log.Println("Stale BecomePrimary request") *)
      lock.release (struct.loadF Server "mu" "s");;
      e.Stale
    else
      (* log.Println("Became Primary") *)
      struct.storeF Server "isPrimary" "s" #true;;
      struct.storeF Server "clerks" "s" (NewSlice ptrT (slice.len (struct.loadF BecomePrimaryArgs "Replicas" "args") - #1));;
      ForSlice ptrT "i" <> (struct.loadF Server "clerks" "s")
        (SliceSet ptrT (struct.loadF Server "clerks" "s") "i" (MakeClerk (SliceGet uint64T (struct.loadF BecomePrimaryArgs "Replicas" "args") ("i" + #1))));;
      lock.release (struct.loadF Server "mu" "s");;
      e.None).

Definition MakeServer: val :=
  rec: "MakeServer" "sm" "nextIndex" "epoch" :=
    let: "s" := struct.alloc Server (zero_val (struct.t Server)) in
    struct.storeF Server "mu" "s" (lock.new #());;
    struct.storeF Server "epoch" "s" "epoch";;
    struct.storeF Server "sm" "s" "sm";;
    struct.storeF Server "nextIndex" "s" "nextIndex";;
    struct.storeF Server "isPrimary" "s" #false;;
    "s".

Definition Server__Serve: val :=
  rec: "Server__Serve" "s" "me" :=
    let: "handlers" := NewMap ((slice.T byteT -> ptrT -> unitT)%ht) #() in
    MapInsert "handlers" RPC_APPLY (λ: "args" "reply",
      "reply" <-[slice.T byteT] e.EncodeError (Server__ApplyAsBackup "s" (DecodeApplyArgs "args"));;
      #()
      );;
    MapInsert "handlers" RPC_SETSTATE (λ: "args" "reply",
      "reply" <-[slice.T byteT] e.EncodeError (Server__SetState "s" (DecodeSetStateArgs "args"));;
      #()
      );;
    MapInsert "handlers" RPC_GETSTATE (λ: "args" "reply",
      "reply" <-[slice.T byteT] EncodeGetStateReply (Server__GetState "s" (DecodeGetStateArgs "args"));;
      #()
      );;
    MapInsert "handlers" RPC_BECOMEPRIMARY (λ: "args" "reply",
      "reply" <-[slice.T byteT] e.EncodeError (Server__BecomePrimary "s" (DecodeBecomePrimaryArgs "args"));;
      #()
      );;
    MapInsert "handlers" RPC_PRIMARYAPPLY (λ: "args" "reply",
      let: ("err", "ret") := Server__Apply "s" "args" in
      (if: ("err" = e.None)
      then
        "reply" <-[slice.T byteT] NewSliceWithCap byteT #0 (#8 + slice.len "ret");;
        "reply" <-[slice.T byteT] marshal.WriteInt (![slice.T byteT] "reply") "err";;
        "reply" <-[slice.T byteT] marshal.WriteBytes (![slice.T byteT] "reply") "ret";;
        #()
      else
        "reply" <-[slice.T byteT] NewSliceWithCap byteT #0 #8;;
        "reply" <-[slice.T byteT] marshal.WriteInt (![slice.T byteT] "reply") "err";;
        #())
      );;
    let: "rs" := urpc.MakeServer "handlers" in
    urpc.Server__Serve "rs" "me";;
    #().
