class TimedGrenades_Effect_PrimedGrenade extends X2Effect_ModifyStats config(TimedGrenades);

var bool Launched;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local TimedGrenades_GameState_Effect_PrimedGrenade GrenadeEffectState;
	local X2EventManager EventMgr;
	local Object ListenerObj;
  local XComGameState_Ability Ability;
  local XComGameStateHistory History;
  local XComGameState_Unit Unit;
	local XComGameState_Player PlayerState;
	local StatChange Change;

  History = `XCOMHISTORY;
	EventMgr = `XEVENTMGR;
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(NewEffectState.ApplyEffectParameters.PlayerStateObjectRef.ObjectID));
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(NewEffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	Change.StatType = eStat_Mobility;
	Change.StatAmount = Unit.GetCurrentStat(eStat_Mobility) * -1;
	NewEffectState.StatChanges.AddItem(Change);

	if (GetEffectComponent(NewEffectState) == none)
	{
		//create component and attach it to GameState_Effect, adding the new state object to the NewGameState container
		GrenadeEffectState = TimedGrenades_GameState_Effect_PrimedGrenade(
      NewGameState.CreateStateObject(class'TimedGrenades_GameState_Effect_PrimedGrenade')
    );
    Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(
      ApplyEffectParameters.AbilityStateObjectRef.ObjectID
    ));
    GrenadeEffectState.SourceGrenade = Ability.SourceWeapon;
		NewEffectState.AddComponentObject(GrenadeEffectState);
		NewGameState.AddStateObject(GrenadeEffectState);
	}

	//add listener to new component effect -- do it here because the RegisterForEvents call happens before OnEffectAdded, so component doesn't yet exist
	ListenerObj = GrenadeEffectState;
	if (ListenerObj == none)
	{
		`Redscreen("PrimedGrenade: Failed to find GrenadeComponent Component when registering listener");
		return;
	}

  EventMgr.RegisterForEvent(ListenerObj, 'PlayerTurnBegun', GrenadeEffectState.OnTurnBegun, ELD_OnStateSubmitted, , PlayerState);
  EventMgr.RegisterForEvent(ListenerObj, 'PlayerTurnEnded', GrenadeEffectState.OnTurnEnded, ELD_OnStateSubmitted, , PlayerState);

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local TimedGrenades_GameState_Effect_PrimedGrenade GrenadeEffectState;
	local Object ListenerObj;
	local X2EventManager EventMgr;

	EventMgr = `XEVENTMGR;

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);
	GrenadeEffectState = GetEffectComponent(RemovedEffectState);
	ListenerObj = GrenadeEffectState;
  EventMgr.UnRegisterFromEvent(ListenerObj, 'PlayerTurnEnded');
  EventMgr.UnRegisterFromEvent(ListenerObj, 'PlayerTurnBegun');
}


static function TimedGrenades_GameState_Effect_PrimedGrenade GetEffectComponent(XComGameState_Effect Effect)
{
	if (Effect != none) 
		return TimedGrenades_GameState_Effect_PrimedGrenade(
      Effect.FindComponentObject(class'TimedGrenades_GameState_Effect_PrimedGrenade')
    );
	return none;
}


simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local XComGameState_Effect MineEffect, EffectState;
	local TimedGrenades_X2Action_ShowTickingGrenade EffectAction;
	local X2Action_StartStopSound SoundAction;
  local XComGameState_Ability Ability;

	if (EffectApplyResult != 'AA_Success' || BuildTrack.TrackActor == none)
		return;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		if (EffectState.GetX2Effect() == self)
		{
			MineEffect = EffectState;
			break;
		}
	}
	`assert(MineEffect != none);

  Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(
    MineEffect.ApplyEffectParameters.AbilityStateObjectRef.ObjectID
  ));

	//For multiplayer: don't visualize mines on the enemy team.
	if (MineEffect.GetSourceUnitAtTimeOfApplication().ControllingPlayer.ObjectID != `TACTICALRULES.GetLocalClientPlayerObjectID())
		return;

	EffectAction = TimedGrenades_X2Action_ShowTickingGrenade(
    class'TimedGrenades_X2Action_ShowTickingGrenade'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext())
  );
  EffectAction.GrenadeRadius = Ability.GetAbilityRadius();
  EffectAction.GrenadeIcon = Ability.GetMyIconImage();
	EffectAction.EffectName = "FX_GW_DelayedExplosions.P_DelayedExplosion";
	EffectAction.EffectLocation = MineEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations[0];

	SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	SoundAction.Sound = new class'SoundCue';
	SoundAction.Sound.AkEventOverride = AkEvent'SoundX2CharacterFX.Item_Proximity_Mine_Active_Ping';
	SoundAction.iAssociatedGameStateObjectId = MineEffect.ObjectID;
	SoundAction.bStartPersistentSound = true;
	SoundAction.bIsPositional = true;
	SoundAction.vWorldPosition = MineEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
}

simulated function AddX2ActionsForVisualization_Sync(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack)
{
	//We assume 'AA_Success', because otherwise the effect wouldn't be here (on load) to get sync'd
	AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 'AA_Success');
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local XComGameState_Effect MineEffect, EffectState;
	local TimedGrenades_X2Action_ShowTickingGrenade EffectAction;
	local X2Action_StartStopSound SoundAction;

	if (EffectApplyResult != 'AA_Success' || BuildTrack.TrackActor == none)
		return;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		if (EffectState.GetX2Effect() == self)
		{
			MineEffect = EffectState;
			break;
		}
	}
	`assert(MineEffect != none);

	//For multiplayer: don't visualize mines on the enemy team.
	if (MineEffect.GetSourceUnitAtTimeOfApplication().ControllingPlayer.ObjectID != `TACTICALRULES.GetLocalClientPlayerObjectID())
		return;

	EffectAction = TimedGrenades_X2Action_ShowTickingGrenade(
    class'TimedGrenades_X2Action_ShowTickingGrenade'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext())
  );
	EffectAction.EffectName = "FX_GW_DelayedExplosions.P_DelayedExplosion";
	EffectAction.EffectLocation = MineEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
	EffectAction.bStopEffect = true;

	SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	SoundAction.Sound = new class'SoundCue';
	SoundAction.Sound.AkEventOverride = AkEvent'SoundX2CharacterFX.Stop_Proximity_Mine_Active_Ping';
	SoundAction.iAssociatedGameStateObjectId = MineEffect.ObjectID;
	SoundAction.bIsPositional = true;
	SoundAction.bStopPersistentSound = true;
}

DefaultProperties
{
	EffectName="PrimedGrenade"
	DuplicateResponse = eDupe_Allow;
	bCanBeRedirected = false;
}
