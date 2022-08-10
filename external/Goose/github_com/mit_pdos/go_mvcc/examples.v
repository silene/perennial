(* autogenerated from github.com/mit-pdos/go-mvcc/examples *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.mit_pdos.go_mvcc.txn.

From Perennial.goose_lang Require Import ffi.grove_prelude.

Definition WriteReservedKeySeq: val :=
  rec: "WriteReservedKeySeq" "txn" :=
    txn.Txn__Put "txn" #0 #2;;
    #true.

Definition WriteReservedKey: val :=
  rec: "WriteReservedKey" "txn" :=
    txn.Txn__DoTxn "txn" WriteReservedKeySeq.

Definition WriteFreeKeySeq: val :=
  rec: "WriteFreeKeySeq" "txn" :=
    txn.Txn__Put "txn" #1 #3;;
    #true.

Definition WriteFreeKey: val :=
  rec: "WriteFreeKey" "txn" :=
    txn.Txn__DoTxn "txn" WriteFreeKeySeq.

Definition WriteReservedKeyExample: val :=
  rec: "WriteReservedKeyExample" <> :=
    let: "mgr" := txn.MkTxnMgr #() in
    let: "p" := ref (zero_val uint64T) in
    txn.TxnMgr__InitializeData "mgr" "p";;
    let: "txn" := txn.TxnMgr__New "mgr" in
    let: "ok" := WriteReservedKey "txn" in
    (if: "ok"
    then "p" <-[uint64T] #2
    else #());;
    ("p", "ok").

Definition WriteFreeKeyExample: val :=
  rec: "WriteFreeKeyExample" <> :=
    let: "mgr" := txn.MkTxnMgr #() in
    let: "p" := ref (zero_val uint64T) in
    txn.TxnMgr__InitializeData "mgr" "p";;
    let: "txn" := txn.TxnMgr__New "mgr" in
    let: "ok" := WriteFreeKey "txn" in
    "ok".
