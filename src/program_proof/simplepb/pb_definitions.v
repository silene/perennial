From Perennial.program_proof Require Import grove_prelude.
From Goose.github_com.mit_pdos.gokv.simplepb Require Export pb.
From Perennial.program_proof.grove_shared Require Import urpc_proof urpc_spec.
From Perennial.program_proof.simplepb Require Export pb_ghost.
From Perennial.goose_lang.lib Require Import waitgroup.
From iris.base_logic Require Export lib.ghost_var mono_nat.
From iris.algebra Require Import dfrac_agree mono_list.
From Perennial.goose_lang Require Import crash_borrow.
From Perennial.program_proof.simplepb Require Import pb_marshal_proof.
From Perennial.program_proof Require Import marshal_stateless_proof.

Section pb_definitions.

Record PBRecord :=
  {
    pb_OpType:Type ;
    pb_has_op_encoding : list u8 → pb_OpType → Prop ;
    pb_has_snap_encoding: list u8 → (list pb_OpType) → Prop ;
    pb_has_op_encoding_injective : ∀ o1 o2 l, pb_has_op_encoding l o1 → pb_has_op_encoding l o2 → o1 = o2 ;
    pb_compute_reply : list pb_OpType → pb_OpType → list u8 ;
  }.

Context {pb_record:PBRecord}.
Notation OpType := (pb_OpType pb_record).
Notation has_op_encoding := (pb_has_op_encoding pb_record).
Notation has_snap_encoding := (pb_has_snap_encoding pb_record).
Notation has_op_encoding_injective := (pb_has_op_encoding_injective pb_record).
Notation compute_reply := (pb_compute_reply pb_record).

Definition client_logR := mono_listR (leibnizO OpType).

Class pbG Σ := {
    pb_ghostG :> pb_ghostG (EntryType:=(OpType * (list OpType → iProp Σ))%type) Σ ;
    pb_urpcG :> urpcregG Σ ;
    (* pb_wgG :> waitgroupG Σ ; *)
    pb_logG :> inG Σ client_logR;
    pb_apply_escrow_tok :> ghost_varG Σ unit ;
}.

Context `{!heapGS Σ, !stagedG Σ}.
Context `{!pbG Σ}.

Definition own_log γ σ := own γ (●ML{#1/2} (σ : list (leibnizO OpType))).

(* RPC specs *)

Program Definition ApplyAsBackup_spec γ γsrv :=
  λ (encoded_args:list u8), λne (Φ : list u8 -d> iPropO Σ) ,
  (∃ args σ op Q,
    ⌜ApplyArgs.has_encoding encoded_args args⌝ ∗
    ⌜length σ = int.nat args.(ApplyArgs.index)⌝ ∗
    ⌜has_op_encoding args.(ApplyArgs.op) op⌝∗
    ⌜last σ = Some (op, Q) ⌝ ∗
    is_proposal_lb γ args.(ApplyArgs.epoch) σ ∗
    is_proposal_facts γ args.(ApplyArgs.epoch) σ ∗
    (∀ error (reply:list u8),
        ⌜has_encoding_Error reply error⌝ -∗
        (if (decide (error = (U64 0))) then is_accepted_lb γsrv args.(ApplyArgs.epoch) σ else True) -∗
        Φ reply)
    )%I
.
Next Obligation.
  solve_proper.
Defined.

Definition SetState_core_spec γ γsrv args σ :=
  λ (Φ : u64 -> iPropO Σ) ,
  (
    ⌜has_snap_encoding args.(SetStateArgs.state) (fst <$> σ)⌝ ∗
    ⌜length σ = int.nat args.(SetStateArgs.nextIndex)⌝ ∗
    is_proposal_lb γ args.(SetStateArgs.epoch) σ ∗
    is_proposal_facts γ args.(SetStateArgs.epoch) σ ∗
    (
      (is_epoch_lb γsrv args.(SetStateArgs.epoch) -∗
       Φ 0) ∧
      (∀ err, ⌜err ≠ U64 0⌝ → Φ err))
    )%I
.

Program Definition SetState_spec γ γsrv :=
  λ (enc_args:list u8), λne (Φ : list u8 -d> iPropO Σ) ,
  (∃ args σ,
    ⌜SetStateArgs.has_encoding enc_args args⌝ ∗
    SetState_core_spec γ γsrv args σ (λ err, ∀ reply, ⌜reply = u64_le err⌝ -∗ Φ reply)
  )%I
.
Next Obligation.
  unfold SetState_core_spec.
  solve_proper.
Defined.

Definition GetState_core_spec γ γsrv (epoch:u64) ghost_epoch_lb :=
  λ (Φ : GetStateReply.C -> iPropO Σ) ,
  (
    ( is_epoch_lb γsrv ghost_epoch_lb ∗
      (
      (∀ epochacc σ snap,
            ⌜int.nat ghost_epoch_lb ≤ int.nat epochacc⌝ -∗
            ⌜int.nat epochacc ≤ int.nat epoch⌝ -∗
            is_accepted_ro γsrv epochacc σ -∗
            is_proposal_facts γ epochacc σ -∗
            is_proposal_lb γ epochacc σ -∗
            ⌜has_snap_encoding snap (fst <$> σ)⌝ -∗
            ⌜length σ = int.nat (U64 (length σ))⌝ -∗
                 Φ (GetStateReply.mkC 0 (length σ) snap)) ∧
      (∀ err, ⌜err ≠ U64 0⌝ → Φ (GetStateReply.mkC err 0 [])))
    )
    )%I
.

Program Definition GetState_spec γ γsrv :=
  λ (enc_args:list u8), λne (Φ : list u8 -d> iPropO Σ) ,
  (∃ args epoch_lb,
    ⌜GetStateArgs.has_encoding enc_args args⌝ ∗
    GetState_core_spec γ γsrv args.(GetStateArgs.epoch) epoch_lb (λ reply, ∀ enc_reply, ⌜GetStateReply.has_encoding enc_reply reply⌝ -∗ Φ enc_reply)
  )%I
.
Next Obligation.
  unfold GetState_core_spec.
  solve_proper.
Defined.

Definition BecomePrimary_core_spec γ γsrv args σ backupγ (ρ:u64 -d> pb_system_names -d> pb_server_names -d> iPropO Σ) :=
  λ (Φ : u64 -> iPropO Σ) ,
  (
    is_epoch_lb γsrv args.(BecomePrimaryArgs.epoch) ∗
    is_epoch_config γ args.(BecomePrimaryArgs.epoch) (γsrv :: backupγ) ∗
    (* FIXME: want this to be "is_pb_host", but that will require recursion *)
    ([∗ list] host ; γsrv' ∈ args.(BecomePrimaryArgs.replicas) ; γsrv :: backupγ, (ρ host γ γsrv') ∗ is_epoch_lb γsrv' args.(BecomePrimaryArgs.epoch)) ∗
    become_primary_escrow γ γsrv args.(BecomePrimaryArgs.epoch) σ ∗
    is_proposal_lb γ args.(BecomePrimaryArgs.epoch) σ ∗
    is_proposal_facts γ args.(BecomePrimaryArgs.epoch) σ ∗
    (∀ err, Φ err)
    )%I
.

Program Definition BecomePrimary_spec_pre γ γsrv ρ :=
  λ (enc_args:list u8), λne (Φ : list u8 -d> iPropO Σ) ,
  (∃ args σ confγ,
    ⌜BecomePrimaryArgs.has_encoding enc_args args⌝ ∗
    BecomePrimary_core_spec γ γsrv args σ confγ ρ (λ err, ∀ reply, ⌜reply = u64_le err⌝ -∗ Φ reply)
  )%I
.
Next Obligation.
  unfold BecomePrimary_core_spec.
  solve_proper.
Defined.

Definition is_pb_host_pre ρ : (u64 -d> pb_system_names -d> pb_server_names -d> iPropO Σ) :=
  (λ host γ γsrv,
  handler_spec γsrv.(pb_urpc_gn) host (U64 0) (ApplyAsBackup_spec γ γsrv) ∗
  handler_spec γsrv.(pb_urpc_gn) host (U64 1) (SetState_spec γ γsrv) ∗
  handler_spec γsrv.(pb_urpc_gn) host (U64 2) (GetState_spec γ γsrv) ∗
  handler_spec γsrv.(pb_urpc_gn) host (U64 3) (BecomePrimary_spec_pre γ γsrv ρ) ∗
  handlers_dom γsrv.(pb_urpc_gn) {[ (U64 0) ; (U64 1) ; (U64 2) ; (U64 3) ; (U64 4) ]})%I
.

Instance is_pb_host_pre_contr : Contractive is_pb_host_pre.
Proof.
  rewrite /is_pb_host_pre=> n is1 is2 Hpre γ γsrv host.
  do 5 (f_contractive || f_equiv).
  f_equiv.
  admit.
Admitted.

Definition is_pb_host_def :=
  fixpoint (is_pb_host_pre).
Definition is_pb_host_aux : seal (is_pb_host_def). by eexists. Qed.
Definition is_pb_host := is_pb_host_aux.(unseal).
Definition is_pb_host_eq : is_pb_host = is_pb_host_def := is_pb_host_aux.(seal_eq).

Definition BecomePrimary_spec γ γsrv := BecomePrimary_spec_pre γ γsrv is_pb_host.

Lemma is_pb_host_unfold host γ γsrv:
  is_pb_host host γ γsrv ⊣⊢ is_pb_host_pre (is_pb_host) host γ γsrv
.
Proof.
  rewrite is_pb_host_eq. apply (fixpoint_unfold (is_pb_host_pre)).
Qed.

Global Instance is_pb_host_pers host γ γsrv: Persistent (is_pb_host host γ γsrv).
Proof.
  rewrite is_pb_host_unfold.
  apply _.
Qed.

(* End RPC specs *)

Definition is_Clerk (ck:loc) γ γsrv : iProp Σ :=
  ∃ (cl:loc) srv,
  "#Hcl" ∷ readonly (ck ↦[pb.Clerk :: "cl"] #cl) ∗
  "#Hcl_rpc"  ∷ is_uRPCClient cl srv ∗
  "#Hsrv" ∷ is_pb_host srv γ γsrv 
.
Lemma wp_MakeClerk host γ γsrv :
  {{{
        is_pb_host host γ γsrv
  }}}
    MakeClerk #host
  {{{
        ck, RET #ck; is_Clerk ck γ γsrv
  }}}.
Proof.
Admitted.

(* FIXME: these belong in a separate file. These will be proved from the RPC specs. *)
(* Clerk specs *)
Lemma wp_Clerk__Apply γ γsrv ck args_ptr (epoch index:u64) σ ghost_op op_sl op :
  {{{
        "#HisClerk" ∷ is_Clerk ck γ γsrv ∗
        "#HepochLb" ∷ is_epoch_lb γsrv epoch ∗
        "#Hprop_lb" ∷ is_proposal_lb γ epoch σ ∗
        "#Hprop_facts" ∷ is_proposal_facts γ epoch σ ∗
        "%Hghost_op_σ" ∷ ⌜last σ = Some ghost_op⌝ ∗
        "%Hghost_op_op" ∷ ⌜has_op_encoding op ghost_op.1⌝ ∗
        "%Hσ_index" ∷ ⌜length σ = ((int.nat index) + 1)%nat⌝ ∗
        "%HnoOverflow" ∷ ⌜int.nat index < int.nat (word.add index 1)⌝ ∗

        "#HargEpoch" ∷ readonly (args_ptr ↦[pb.ApplyArgs :: "epoch"] #epoch) ∗
        "#HargIndex" ∷ readonly (args_ptr ↦[pb.ApplyArgs :: "index"] #index) ∗
        "#HargOp" ∷ readonly (args_ptr ↦[pb.ApplyArgs :: "op"] (slice_val op_sl)) ∗
        "#HopSl" ∷ readonly (is_slice_small op_sl byteT 1 op)
  }}}
    Clerk__Apply #ck #args_ptr
  {{{
        (err:u64), RET #err; □ if (decide (err = 0)) then
                               is_accepted_lb γsrv epoch σ
                             else True
  }}}.
Proof.
Admitted.

Lemma wp_Clerk__BecomePrimary γ γsrv ck args_ptr (epoch:u64) servers server_γs σ :
  {{{
        "#HisClerk" ∷ is_Clerk ck γ γsrv ∗
        "#Hconf" ∷ is_epoch_config γ epoch server_γs ∗
        "#Hhost" ∷ ([∗ list] γsrv;host ∈ server_γs;servers, is_pb_host host γ γsrv) ∗
        "#Hacc" ∷ is_accepted_lb γsrv epoch σ ∗
        "Hprop" ∷ own_proposal γ epoch σ ∗ (* FIXME: escrow this *)
        "Hargs" ∷ BecomePrimaryArgs.own args_ptr (BecomePrimaryArgs.mkC epoch servers)
  }}}
    Clerk__BecomePrimary #ck #args_ptr
  {{{
        (err:u64), RET #err; True
  }}}.
Proof.
Admitted.

(* End clerk specs *)

(* Server-side definitions *)

Implicit Type (own_StateMachine: u64 → list OpType → bool → (u64 → list OpType → bool → iProp Σ) → iProp Σ).
(* StateMachine *)
Definition is_ApplyFn own_StateMachine (applyFn:val) (P:u64 → list (OpType) → bool → iProp Σ) : iProp Σ :=
  ∀ op_sl (epoch:u64) (σ:list OpType) (op_bytes:list u8) (op:OpType) Q,
  {{{
        ⌜has_op_encoding op_bytes op⌝ ∗
        readonly (is_slice_small op_sl byteT 1 op_bytes) ∗
        (P epoch σ false ={⊤}=∗ P epoch (σ ++ [op]) false ∗ Q) ∗
        own_StateMachine epoch σ false P
  }}}
    applyFn (slice_val op_sl)
  {{{
        reply_sl,
        RET (slice_val reply_sl);
        is_slice reply_sl byteT 1 (compute_reply σ op) ∗
        own_StateMachine epoch (σ ++ [op]) false P ∗
        Q
  }}}
.

Definition is_SetStateAndUnseal_fn own_StateMachine (set_state_fn:val) P : iProp Σ :=
  ∀ σ_prev (epoch_prev:u64) σ epoch (snap:list u8) snap_sl sealed Q,
  {{{
        ⌜has_snap_encoding snap σ⌝ ∗
        readonly (is_slice_small snap_sl byteT 1 snap) ∗
        (P epoch_prev σ_prev sealed ={⊤}=∗ P epoch σ false ∗ Q) ∗
        own_StateMachine epoch_prev σ_prev sealed P
  }}}
    set_state_fn (slice_val snap_sl) #epoch #(U64 (length σ))
  {{{
        RET #();
        own_StateMachine epoch σ false P ∗
        Q
  }}}
.

Definition is_GetStateAndSeal_fn own_StateMachine (get_state_fn:val) P : iProp Σ :=
  ∀ σ epoch sealed Q,
  {{{
        own_StateMachine epoch σ sealed P ∗
        (P epoch σ sealed ={⊤}=∗ P epoch σ true ∗ Q)
  }}}
    get_state_fn #()
  {{{
        snap_sl snap,
        RET (slice_val snap_sl);
        is_slice_small snap_sl byteT 1 snap ∗
        ⌜has_snap_encoding snap σ⌝ ∗
        own_StateMachine epoch σ true P ∗
        Q
  }}}
.

Definition accessP_fact own_StateMachine P : iProp Σ :=
  □ (∀ Φ E σ epoch sealed,
  (P epoch σ sealed ={E}=∗ P epoch σ sealed ∗ Φ) -∗
  own_StateMachine epoch σ sealed P ={E}=∗
  wpc_nval E (own_StateMachine epoch σ sealed P ∗ Φ))
  (* FIXME: this wpc_nval is there because P might be in a crash borrow in
     own_StateMachine. Joe said it imght be possible to get rid of wpc_nval by
     changing the model of crash_borrows by using later credits. *)
.

Definition is_StateMachine (sm:loc) own_StateMachine P : iProp Σ :=
  ∃ (applyFn:val) (getFn:val) (setFn:val),
  "#Happly" ∷ readonly (sm ↦[pb.StateMachine :: "Apply"] applyFn) ∗
  "#HapplySpec" ∷ is_ApplyFn own_StateMachine applyFn P ∗

  "#HsetState" ∷ readonly (sm ↦[pb.StateMachine :: "SetStateAndUnseal"] setFn) ∗
  "#HsetStateSpec" ∷ is_SetStateAndUnseal_fn own_StateMachine setFn P ∗

  "#HgetState" ∷ readonly (sm ↦[pb.StateMachine :: "GetStateAndSeal"] getFn) ∗
  "#HgetStateSpec" ∷ is_GetStateAndSeal_fn own_StateMachine getFn P ∗

  "#HaccP" ∷ accessP_fact own_StateMachine P.

(* Hides the ghost part of the log; this is suitable for exposing as part of
   interfaces for users of the library. For now, it's only part of the crash
   obligation. *)
Definition own_Server_ghost γ γsrv epoch σphys sealed : iProp Σ :=
  ∃ σ, ⌜σphys = σ.*1⌝ ∗ (own_replica_ghost γ γsrv epoch σ sealed) ∗
      (own_primary_ghost γ γsrv epoch σ)
.

Definition own_Server (s:loc) γ γsrv own_StateMachine : iProp Σ :=
  ∃ (epoch:u64) σg (nextIndex:u64) (sealed:bool) (isPrimary:bool) (sm:loc) (clerks_sl:Slice.t),
  (* physical *)
  "Hepoch" ∷ s ↦[pb.Server :: "epoch"] #epoch ∗
  "HnextIndex" ∷ s ↦[pb.Server :: "nextIndex"] #nextIndex ∗
  "HisPrimary" ∷ s ↦[pb.Server :: "isPrimary"] #isPrimary ∗
  "Hsealed" ∷ s ↦[pb.Server :: "sealed"] #sealed ∗
  "Hsm" ∷ s ↦[pb.Server :: "sm"] #sm ∗
  "Hclerks" ∷ s ↦[pb.Server :: "clerks"] (slice_val clerks_sl) ∗

  (* state-machine callback specs *)
  "#HisSm" ∷ is_StateMachine sm own_StateMachine (own_Server_ghost γ γsrv) ∗

  (* ghost-state *)
  "Hstate" ∷ own_StateMachine epoch (fst<$>σg) sealed (own_Server_ghost γ γsrv) ∗
  "%Hσ_nextIndex" ∷ ⌜length σg = int.nat nextIndex⌝ ∗
  (* ghost witnesses for convenience; we could insist on extracting them from own_Server_ghost *)
  "#Hs_acc_lb" ∷ is_accepted_lb γsrv epoch σg ∗
  "#Hs_prop_lb" ∷ is_proposal_lb γ epoch σg ∗
  "#Hs_prop_facts" ∷ is_proposal_facts γ epoch σg ∗
  "#Hs_epoch_lb" ∷ is_epoch_lb γsrv epoch ∗

  (* primary-only *)
  "HprimaryOnly" ∷ if isPrimary then (
            ∃ (clerks:list loc) (backups:list pb_server_names),
            "#Htok_used_witness" ∷ is_tok γsrv epoch ∗
            "%Hconf_clerk_len" ∷ ⌜length clerks = length (backups)⌝ ∗
            "#Hconf" ∷ is_epoch_config γ epoch (γsrv :: backups) ∗
                     (* FIXME: ptrT vs refT (struct.t Clerk) *)
            "#Hclerks_sl" ∷ readonly (is_slice_small clerks_sl ptrT 1 clerks) ∗
            "#Hclerks_rpc" ∷ ([∗ list] ck ; γsrv' ∈ clerks ; backups, is_Clerk ck γ γsrv' ∗
                                                                      is_epoch_lb γsrv' epoch
                             )
        )
                   else True
.

Definition is_Server (s:loc) γ γsrv : iProp Σ :=
  ∃ (mu:val) own_StateMachine,
  "#Hmu" ∷ readonly (s ↦[pb.Server :: "mu"] mu) ∗
  "#HmuInv" ∷ is_lock pbN mu (own_Server s γ γsrv own_StateMachine) ∗
  "#Hsys_inv" ∷ sys_inv γ.

Lemma wp_Server__isEpochStale {stk} (s:loc) γ γsrv (currEpoch epoch:u64) σ sealed own_StateMachine:
  {{{
        is_epoch_lb γsrv epoch ∗
        s ↦[pb.Server :: "epoch"] #currEpoch ∗
        accessP_fact own_StateMachine (own_Server_ghost γ γsrv) ∗
        own_StateMachine currEpoch σ sealed (own_Server_ghost γ γsrv)
  }}}
    pb.Server__isEpochStale #s #epoch @ stk
  {{{
        RET #(bool_decide (int.Z epoch < int.Z currEpoch));
        ⌜int.nat currEpoch ≥ int.nat epoch⌝ ∗
        s ↦[pb.Server :: "epoch"] #currEpoch ∗
        own_StateMachine currEpoch σ sealed (own_Server_ghost γ γsrv)
  }}}
.
Proof.
  iIntros (Φ) "(#Hlb & HcurrEpoch & #HaccP & Hstate) HΦ".
  wp_call.
  iMod ("HaccP" $! (⌜int.nat currEpoch ≥ int.nat epoch⌝)%I with "[] Hstate") as "HH".
  {
    iIntros "H".
    iDestruct "H" as (?) "[%Hre H]".
    iDestruct "H" as "[H HQ]".
    iNamed "H".
    iDestruct (mono_nat_lb_own_valid with "Hepoch_ghost Hlb") as %[_ Hineq].
    iModIntro.
    iSplitL; last done.
    iExists _; iFrame "∗#%".
  }
  unfold wpc_nval.
  wp_bind (struct.loadF _ _ _).
  iApply (wpc_wp _ _ _ _ (True%I)).
  wpc_apply "HH".
  { done. }
  { done. }
  iCache with "".
  { done. }
  wpc_loadField.
  iIntros "[Hstate %Hineq]".
  wp_pures.
  iModIntro.
  iApply ("HΦ").
  iFrame "∗%".
Qed.

End pb_definitions.
