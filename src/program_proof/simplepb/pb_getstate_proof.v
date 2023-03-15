From Perennial.program_proof Require Import grove_prelude.
From Goose.github_com.mit_pdos.gokv.simplepb Require Export pb.
From Perennial.program_proof.simplepb Require Export pb_ghost.
From Perennial.program_proof.simplepb Require Import pb_marshal_proof.
From Perennial.program_proof Require Import marshal_stateless_proof.
From Perennial.program_proof.simplepb Require Import pb_definitions.
From Perennial.program_proof.reconnectclient Require Import proof.

Section pb_getstate_proof.
Context `{!heapGS Σ}.
Context {pb_record:Sm.t}.

Notation OpType := (Sm.OpType pb_record).
Notation has_op_encoding := (Sm.has_op_encoding pb_record).
Notation has_snap_encoding := (Sm.has_snap_encoding pb_record).
Notation compute_reply := (Sm.compute_reply pb_record).
Notation pbG := (pbG (pb_record:=pb_record)).

Context `{!waitgroupG Σ}.
Context `{!pbG Σ}.

(* XXX: GetState doesn't actually *need* to do any epoch comparison.
   It could simply return the state it has and the epoch for which it is the state.
   The issue is that an old epoch would then be able to seal future epochs,
   which might hurt liveness.
 *)
(* FIXME: rename to GetStateAndSeal *)
Lemma wp_Clerk__GetState γ γsrv ck args_ptr (epoch_lb:u64) (epoch:u64) :
  {{{
        "#Hck" ∷ is_Clerk ck γ γsrv ∗
        "#Hghost_epoch_lb" ∷ is_epoch_lb γsrv epoch_lb ∗
        "Hargs" ∷ GetStateArgs.own args_ptr (GetStateArgs.mkC epoch)
  }}}
    Clerk__GetState #ck #args_ptr
  {{{
        (reply:loc) (err:u64), RET #reply;
        if (decide (err = U64 0)) then
            ∃ epochacc opsfull enc,
            ⌜int.nat epoch_lb ≤ int.nat epochacc⌝ ∗
            ⌜int.nat epochacc ≤ int.nat epoch⌝ ∗
            is_accepted_ro γsrv epochacc opsfull ∗
            is_proposal_facts γ epochacc opsfull ∗
            is_proposal_lb γ epochacc opsfull ∗
            GetStateReply.own reply (GetStateReply.mkC 0 (length (get_rwops opsfull)) enc) ∗
            ⌜has_snap_encoding enc (get_rwops opsfull)⌝ ∗
            ⌜length (get_rwops opsfull) = int.nat (U64 (length (get_rwops opsfull)))⌝
          else
            GetStateReply.own reply (GetStateReply.mkC err 0 [])
  }}}.
Proof.
  iIntros (Φ) "Hpre HΦ".
  iNamed "Hpre".
  wp_call.
  wp_apply (wp_ref_of_zero).
  { done. }
  iIntros (rep) "Hrep".
  wp_pures.
  iNamed "Hck".
  wp_apply (GetStateArgs.wp_Encode with "[$Hargs]").
  iIntros (enc_args enc_args_sl) "(%Henc_args & Henc_args_sl & Hargs)".
  wp_loadField.
  iDestruct (is_slice_to_small with "Henc_args_sl") as "Henc_args_sl".
  wp_apply (wp_frame_wand with "HΦ").
  rewrite is_pb_host_unfold.
  iNamed "Hsrv".
  wp_apply (wp_ReconnectingClient__Call2 with "Hcl_rpc [] Henc_args_sl Hrep").
  {
    iDestruct "Hsrv" as "[_ [_ [$ _]]]".
  }
  { (* Successful RPC *)
    iModIntro.
    iNext.
    unfold GetState_spec.
    iExists _, _.
    iSplitR; first done.
    simpl.
    unfold GetState_core_spec.
    iFrame "Hghost_epoch_lb".
    iSplit.
    { (* No error from RPC, state was returned *)
      iIntros (?????) "???".
      iIntros (??? Henc_reply) "Hargs_sl".
      iIntros (?) "Hrep Hrep_sl".
      wp_pures.
      wp_load.
      wp_apply (GetStateReply.wp_Decode with "[$Hrep_sl]").
      { done. }
      iIntros (reply_ptr) "Hreply".
      iIntros "HΦ".
      iApply ("HΦ" $! _ 0).
      iExists _, _, _.
      iFrame "Hreply".
      iSplitR; first done.
      iSplitR; first done.
      eauto with iFrame.
    }
    { (* GetState was rejected by the server (e.g. stale epoch number) *)
      iIntros (err) "%Herr_nz".
      iIntros.
      wp_pures.
      wp_load.
      wp_apply (GetStateReply.wp_Decode with "[-] []").
      { eauto. }
      iModIntro.
      iIntros (reply_ptr) "Hreply".

      iIntros "HΦ".
      iApply ("HΦ" $! _ err).
      destruct (decide _).
      {
        exfalso. done.
      }
      {
        done.
      }
    }
  }
  { (* RPC error *)
    iIntros.
    wp_pures.
    wp_if_destruct.
    {
      iDestruct (is_slice_small_nil byteT 1 Slice.nil) as "#Hsl_nil".
      { done. }
      iMod (readonly_alloc_1 with "Hsl_nil") as "Hsl_nil2".
      wp_apply (wp_allocStruct).
      { repeat econstructor. apply zero_val_ty'. done. }
      iIntros (reply_ptr) "Hreply".
      iDestruct (struct_fields_split with "Hreply") as "HH".
      iNamed "HH".
      iIntros "HΦ".
      iApply ("HΦ" $! _ 3).
      iExists _. simpl. iFrame.
      replace (zero_val (slice.T byteT)) with (slice_val Slice.nil) by done.
      iFrame.
    }
    { exfalso. done. }
  }
Qed.

(** Helper lemmas for GetState() server-side proof *)
Lemma is_StateMachine_acc_getstate sm own_StateMachine P :
  is_StateMachine sm own_StateMachine P -∗
  (∃ getstateFn,
    "#Hgetstate" ∷ readonly (sm ↦[pb.StateMachine :: "GetStateAndSeal"] getstateFn) ∗
    "#HgetstateSpec" ∷ is_GetStateAndSeal_fn (pb_record:=pb_record) own_StateMachine getstateFn P
  )
.
Proof.
  rewrite /is_StateMachine /tc_opaque.
  iNamed 1. iExists _; iFrame "#".
Qed.

Lemma wp_Server__GetState γ γsrv s args_ptr args epoch_lb Φ Ψ :
  is_Server s γ γsrv -∗
  GetStateArgs.own args_ptr args -∗
  (∀ reply, Ψ reply -∗ ∀ (reply_ptr:loc), GetStateReply.own reply_ptr reply -∗ Φ #reply_ptr) -∗
  GetState_core_spec γ γsrv args.(GetStateArgs.epoch) epoch_lb Ψ -∗
  WP pb.Server__GetState #s #args_ptr {{ Φ }}
  .
Proof.
  iIntros "His_srv Hargs HΦ HΨ".
  wp_call.
  iNamed "His_srv".
  wp_loadField.
  wp_apply (acquire_spec with "HmuInv").
  iIntros "[Hlocked Hown]".
  iNamed "Hown".
  wp_pures.
  iNamed "Hargs".
  wp_loadField.
  iNamed "Hvol".
  wp_loadField.
  wp_if_destruct.
  { (* reply with error *)
    wp_loadField.
    wp_apply (release_spec with "[-HΦ HΨ]").
    {
      iFrame "HmuInv Hlocked".
      iNext.
      repeat (iExists _).
      iSplitR "HghostEph"; last iFrame.
      repeat (iExists _).
      iFrame "∗#%".
    }
    unfold GetState_core_spec.
    iDestruct "HΨ" as "[_ HΨ]".
    iRight in "HΨ".
    wp_pures.
    iDestruct (is_slice_small_nil byteT 1 Slice.nil) as "#Hsl_nil".
    { done. }
    iMod (readonly_alloc_1 with "Hsl_nil") as "Hsl_nil2".
    wp_apply (wp_allocStruct).
    { Transparent slice.T. repeat econstructor.
      Opaque slice.T. }
    iIntros (reply_ptr) "Hreply".
    iDestruct (struct_fields_split with "Hreply") as "HH".
    iNamed "HH".
    iApply ("HΦ" with "[HΨ]"); last first.
    {
      iExists _. iFrame.
      instantiate (1:=GetStateReply.mkC _ _ _).
      replace (slice.nil) with (slice_val Slice.nil) by done.
      iFrame.
    }
    simpl.
    iApply "HΨ".
    done.
  }
  wp_storeField.
  wp_loadField.

  iDestruct (is_StateMachine_acc_getstate with "HisSm") as "HH".
  iNamed "HH".
  wp_loadField.
  iDestruct "HΨ" as "[#Hepoch_lb HΨ]".
  wp_apply ("HgetstateSpec" with "[$Hstate HghostEph]").
  {
    iIntros "Hghost".
    iNamed "Hghost".
    iDestruct (ghost_epoch_lb_ineq with "Hepoch_lb Hghost") as "#Hepoch_ineq".
    iMod (ghost_seal with "Hghost") as "Hghost".
    iDestruct (ghost_get_accepted_ro with "Hghost") as "#Hacc_ro".
    iDestruct (ghost_get_proposal_facts with "Hghost") as "#[Hprop_lb Hprop_facts]".

    destruct sealed.
    {
      iDestruct "Heph" as "#Heph".
      iSplitL "Hghost Hprim".
      {
        iExists _.
        iFrame "∗#".
        iPureIntro. done.
      }
      instantiate (1:=(∃ opsfull, is_accepted_ro γsrv epoch opsfull ∗
                                  is_proposal_lb γ epoch opsfull ∗
                                  is_proposal_facts γ epoch opsfull ∗
                                  is_ephemeral_proposal_sealed γeph epoch opsfull_ephemeral ∗
                                  ⌜get_rwops opsfull = get_rwops opsfull_ephemeral⌝ ∗ ⌜int.nat epoch_lb ≤ int.nat epoch⌝)%I).
      iExists _.
      iFrame "#".
      iPureIntro. done.
    }
    {
      iMod (own_update with "Heph") as "Heph_ro".
      {
        apply singleton_update.
        apply mono_list.mono_list_auth_persist.
      }
      iDestruct "Heph_ro" as "#Heph_ro".
      iSplitL "Hghost Hprim".
      {
        iExists _.
        iFrame "∗#".
        iSplitR; first by iPureIntro.
        repeat iModIntro.
        iExists _; iFrame "#".
      }
      iCombine "Hacc_ro Hepoch_ineq" as "HH".
      iExists _.
      iFrame "#".
      iPureIntro.
      done.
    }
  }
  iIntros (??) "(#Hsnap_sl & %Hsnap_enc & [Hstate HQ])".
  iDestruct "HQ" as (?) "(#Hacc_ro &  #Hprop_lb & #Hprop_facts & #Hepoch_seal & %Hσeq_phys & %Hineq)".
  wp_pures.
  wp_loadField.
  wp_pures.
  wp_loadField.

  iLeft in "HΨ".
  iDestruct ("HΨ" with "[% //] [%] Hacc_ro Hprop_facts Hprop_lb [%] [%]") as "HΨ".
  { word. }
  { rewrite Hσeq_phys. done. }
  { apply (f_equal length) in Hσeq_phys.
    word. }

  (* signal all opApplied condvars *)
  wp_apply (wp_MapIter with "HopAppliedConds_map HopAppliedConds_conds").
  { iFrame "HopAppliedConds_conds". }
  { (* prove one iteration of the map for loop *)
    iIntros.
    iIntros (?) "!# [_ #Hpre] HΦ".
    wp_pures.
    wp_apply (wp_condSignal with "Hpre").
    iApply "HΦ".
    iFrame "#".
    instantiate (1:=(λ _ _, True)%I).
    done.
  }
  iIntros "(HopAppliedConds_map & _ & _)".

  wp_pures.
  wp_apply (wp_NewMap).
  iIntros (opAppliedConds_loc_new) "Hmapnew".
  wp_storeField.
  wp_loadField.
  wp_apply (release_spec with "[-Hsnap_sl HΨ HΦ]").
  {
    iFrame "HmuInv Hlocked".
    iNext.
    repeat (iExists _).
    iFrame "∗ HisSm #%".
    by iApply big_sepM_empty.
  }
  wp_apply (wp_allocStruct).
  { Transparent slice.T. repeat econstructor.
    Opaque slice.T. }
  iIntros (reply_ptr) "Hreply".
  iDestruct (struct_fields_split with "Hreply") as "HH".
  iNamed "HH".
  iApply ("HΦ" with "HΨ").
  iExists _.
  iFrame.
  simpl.

  apply (f_equal length) in Hσeq_phys.
  rewrite Hσeq_phys.
  rewrite Hσ_nextIndex.
  replace (U64 (int.nat nextIndex)) with (nextIndex) by word.
  iFrame "∗#".
Qed.

End pb_getstate_proof.
