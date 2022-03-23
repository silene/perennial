(* autogenerated from github.com/mit-pdos/gokv/fencing/ctr *)
From Perennial.goose_lang Require Import prelude.
From Perennial.goose_lang Require Import ffi.grove_prelude.

From Goose Require github_com.mit_pdos.gokv.urpc.rpc.
From Goose Require github_com.tchajed.marshal.

(* 0_marshal.go *)

Definition PutArgs := struct.decl [
  "cid" :: uint64T;
  "seq" :: uint64T;
  "epoch" :: uint64T;
  "v" :: uint64T
].

Definition EncPutArgs: val :=
  rec: "EncPutArgs" "args" :=
    let: "enc" := marshal.NewEnc #24 in
    marshal.Enc__PutInt "enc" (struct.loadF PutArgs "cid" "args");;
    marshal.Enc__PutInt "enc" (struct.loadF PutArgs "seq" "args");;
    marshal.Enc__PutInt "enc" (struct.loadF PutArgs "v" "args");;
    marshal.Enc__PutInt "enc" (struct.loadF PutArgs "epoch" "args");;
    marshal.Enc__Finish "enc".

Definition DecPutArgs: val :=
  rec: "DecPutArgs" "raw_args" :=
    let: "dec" := marshal.NewDec "raw_args" in
    let: "args" := struct.alloc PutArgs (zero_val (struct.t PutArgs)) in
    struct.storeF PutArgs "cid" "args" (marshal.Dec__GetInt "dec");;
    struct.storeF PutArgs "seq" "args" (marshal.Dec__GetInt "dec");;
    struct.storeF PutArgs "v" "args" (marshal.Dec__GetInt "dec");;
    struct.storeF PutArgs "epoch" "args" (marshal.Dec__GetInt "dec");;
    "args".

Definition GetArgs := struct.decl [
  "cid" :: uint64T;
  "seq" :: uint64T;
  "epoch" :: uint64T
].

Definition EncGetArgs: val :=
  rec: "EncGetArgs" "args" :=
    let: "enc" := marshal.NewEnc #24 in
    marshal.Enc__PutInt "enc" (struct.loadF GetArgs "cid" "args");;
    marshal.Enc__PutInt "enc" (struct.loadF GetArgs "seq" "args");;
    marshal.Enc__PutInt "enc" (struct.loadF GetArgs "epoch" "args");;
    marshal.Enc__Finish "enc".

Definition DecGetArgs: val :=
  rec: "DecGetArgs" "raw_args" :=
    let: "dec" := marshal.NewDec "raw_args" in
    let: "args" := struct.alloc GetArgs (zero_val (struct.t GetArgs)) in
    struct.storeF GetArgs "cid" "args" (marshal.Dec__GetInt "dec");;
    struct.storeF GetArgs "seq" "args" (marshal.Dec__GetInt "dec");;
    struct.storeF GetArgs "epoch" "args" (marshal.Dec__GetInt "dec");;
    "args".

Definition GetReply := struct.decl [
  "err" :: uint64T;
  "val" :: uint64T
].

Definition EncGetReply: val :=
  rec: "EncGetReply" "reply" :=
    let: "enc" := marshal.NewEnc #16 in
    marshal.Enc__PutInt "enc" (struct.loadF GetReply "err" "reply");;
    marshal.Enc__PutInt "enc" (struct.loadF GetReply "val" "reply");;
    marshal.Enc__Finish "enc".

Definition DecGetReply: val :=
  rec: "DecGetReply" "raw_reply" :=
    let: "dec" := marshal.NewDec "raw_reply" in
    let: "reply" := struct.alloc GetReply (zero_val (struct.t GetReply)) in
    struct.storeF GetReply "err" "reply" (marshal.Dec__GetInt "dec");;
    struct.storeF GetReply "val" "reply" (marshal.Dec__GetInt "dec");;
    "reply".

(* client.go *)

Definition RPC_GET : expr := #0.

Definition RPC_PUT : expr := #1.

Definition RPC_FRESHCID : expr := #2.

Definition Clerk := struct.decl [
  "cl" :: ptrT;
  "cid" :: uint64T;
  "seq" :: uint64T
].

Definition Clerk__Get: val :=
  rec: "Clerk__Get" "c" "epoch" :=
    struct.storeF Clerk "seq" "c" (struct.loadF Clerk "seq" "c" + #1);;
    let: "args" := struct.new GetArgs [
      "epoch" ::= "epoch";
      "cid" ::= struct.loadF Clerk "cid" "c";
      "seq" ::= struct.loadF Clerk "seq" "c"
    ] in
    let: "reply_ptr" := ref (zero_val (slice.T byteT)) in
    let: "err" := rpc.RPCClient__Call (struct.loadF Clerk "cl" "c") RPC_GET (EncGetArgs "args") "reply_ptr" #100 in
    (if: "err" ≠ #0
    then
      (* log.Println("ctr: urpc get call failed/timed out") *)
      grove_ffi.Exit #1
    else #());;
    let: "r" := DecGetReply (![slice.T byteT] "reply_ptr") in
    (if: struct.loadF GetReply "err" "r" ≠ "ENone"
    then
      (* log.Println("ctr: get() stale epoch number") *)
      grove_ffi.Exit #1
    else #());;
    struct.loadF GetReply "val" "r".

Definition Clerk__Put: val :=
  rec: "Clerk__Put" "c" "v" "epoch" :=
    struct.storeF Clerk "seq" "c" (struct.loadF Clerk "seq" "c" + #1);;
    let: "args" := struct.new PutArgs [
      "cid" ::= struct.loadF Clerk "cid" "c";
      "seq" ::= struct.loadF Clerk "seq" "c";
      "v" ::= "v";
      "epoch" ::= "epoch"
    ] in
    let: "reply_ptr" := ref (zero_val (slice.T byteT)) in
    let: "err" := rpc.RPCClient__Call (struct.loadF Clerk "cl" "c") RPC_GET (EncPutArgs "args") "reply_ptr" #100 in
    (if: "err" ≠ #0
    then
      (* log.Println("ctr: urpc put call failed/timed out") *)
      grove_ffi.Exit #1
    else #());;
    let: "dec" := marshal.NewDec (![slice.T byteT] "reply_ptr") in
    let: "epochErr" := marshal.Dec__GetInt "dec" in
    (if: "epochErr" ≠ "ENone"
    then
      (* log.Println("ctr: get() stale epoch number") *)
      grove_ffi.Exit #1
    else #());;
    #().

Definition MakeClerk: val :=
  rec: "MakeClerk" "host" :=
    let: "ck" := struct.alloc Clerk (zero_val (struct.t Clerk)) in
    struct.storeF Clerk "seq" "ck" #0;;
    struct.storeF Clerk "cl" "ck" (rpc.MakeRPCClient "host");;
    let: "reply_ptr" := ref (zero_val (slice.T byteT)) in
    let: "err" := rpc.RPCClient__Call (struct.loadF Clerk "cl" "ck") RPC_GET (NewSlice byteT #0) "reply_ptr" #100 in
    (if: "err" ≠ #0
    then Panic ("ctr: urpc call failed/timed out")
    else #());;
    struct.storeF Clerk "cid" "ck" (marshal.Dec__GetInt (marshal.NewDec (![slice.T byteT] "reply_ptr")));;
    "ck".

(* server.go *)

Definition Server := struct.decl [
  "mu" :: ptrT;
  "v" :: uint64T;
  "lastEpoch" :: uint64T;
  "lastSeq" :: mapT uint64T;
  "lastReply" :: mapT uint64T;
  "lastCID" :: uint64T
].

Definition ENone : expr := #0.

Definition EStale : expr := #1.

Definition Server__Put: val :=
  rec: "Server__Put" "s" "args" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    (if: struct.loadF PutArgs "epoch" "args" < struct.loadF Server "lastEpoch" "s"
    then
      lock.release (struct.loadF Server "mu" "s");;
      EStale
    else
      struct.storeF Server "lastEpoch" "s" (struct.loadF PutArgs "epoch" "args");;
      let: ("last", "ok") := MapGet (struct.loadF Server "lastSeq" "s") (struct.loadF PutArgs "cid" "args") in
      let: "seq" := struct.loadF PutArgs "seq" "args" in
      (if: "ok" && ("seq" ≤ "last")
      then
        lock.release (struct.loadF Server "mu" "s");;
        ENone
      else
        struct.storeF Server "v" "s" (struct.loadF PutArgs "v" "args");;
        MapInsert (struct.loadF Server "lastSeq" "s") (struct.loadF PutArgs "cid" "args") "seq";;
        lock.release (struct.loadF Server "mu" "s");;
        ENone)).

Definition Server__Get: val :=
  rec: "Server__Get" "s" "args" "reply" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    struct.storeF GetReply "err" "reply" ENone;;
    (if: struct.loadF GetArgs "epoch" "args" < struct.loadF Server "lastEpoch" "s"
    then
      lock.release (struct.loadF Server "mu" "s");;
      struct.storeF GetReply "err" "reply" EStale;;
      #()
    else
      struct.storeF Server "lastEpoch" "s" (struct.loadF GetArgs "epoch" "args");;
      struct.storeF GetReply "val" "reply" (struct.loadF Server "v" "s");;
      lock.release (struct.loadF Server "mu" "s");;
      #()).

Definition Server__GetFreshCID: val :=
  rec: "Server__GetFreshCID" "s" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    struct.storeF Server "lastCID" "s" (struct.loadF Server "lastCID" "s" + #1);;
    let: "ret" := struct.loadF Server "lastCID" "s" in
    lock.release (struct.loadF Server "mu" "s");;
    "ret".

Definition StartServer: val :=
  rec: "StartServer" "me" :=
    let: "s" := struct.alloc Server (zero_val (struct.t Server)) in
    struct.storeF Server "mu" "s" (lock.new #());;
    struct.storeF Server "lastCID" "s" #0;;
    struct.storeF Server "v" "s" #0;;
    struct.storeF Server "lastSeq" "s" (NewMap uint64T #());;
    struct.storeF Server "lastReply" "s" (NewMap uint64T #());;
    let: "handlers" := NewMap ((slice.T byteT -> ptrT -> unitT)%ht) #() in
    MapInsert "handlers" RPC_GET (λ: "raw_args" "raw_reply",
      let: "args" := DecGetArgs "raw_args" in
      let: "reply" := struct.alloc GetReply (zero_val (struct.t GetReply)) in
      Server__Get "s" "args" "reply";;
      "raw_reply" <-[slice.T byteT] EncGetReply "reply";;
      #()
      );;
    MapInsert "handlers" RPC_PUT (λ: "raw_args" "reply",
      let: "args" := DecPutArgs "raw_args" in
      let: "err" := Server__Put "s" "args" in
      let: "enc" := marshal.NewEnc #8 in
      marshal.Enc__PutInt "enc" "err";;
      "reply" <-[slice.T byteT] marshal.Enc__Finish "enc";;
      #()
      );;
    MapInsert "handlers" RPC_FRESHCID (λ: "raw_args" "reply",
      let: "enc" := marshal.NewEnc #8 in
      marshal.Enc__PutInt "enc" (Server__GetFreshCID "s");;
      "reply" <-[slice.T byteT] marshal.Enc__Finish "enc";;
      #()
      );;
    let: "r" := rpc.MakeRPCServer "handlers" in
    rpc.RPCServer__Serve "r" "me" #1;;
    #().
