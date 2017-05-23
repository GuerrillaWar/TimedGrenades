//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_ProximityMine.uc
//  AUTHOR:  Joshua Bouscher  --  3/24/2015
//  PURPOSE: This effect will persist on a unit that uses a proximity mine.
//           It is in charge of detecting enemy movement within the appropriate
//           range and issuing the corresponding detonation ability.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class TimedGrenades_Effect_TickingGrenade extends X2Effect_Persistent config(TimedGrenades);

var bool Launched;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local TimedGrenades_GameState_Effect_TickingGrenade GrenadeEffectState;
	local X2EventManager EventMgr;
	local Object ListenerObj;
  local XComGameState_Ability Ability;
  local XComGameState_Unit SourceUnit;
  local XComGameState_Item Weapon, IterItem;
  local array<XComGameState_Item> ItemList;
  local XComGameStateHistory History;
  local X2GrenadeTemplate GrenadeTemplate;
	local XComGameState_Player PlayerState;

  History = `XCOMHISTORY;
	EventMgr = `XEVENTMGR;
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(NewEffectState.ApplyEffectParameters.PlayerStateObjectRef.ObjectID));

	if (GetEffectComponent(NewEffectState) == none)
	{
		//create component and attach it to GameState_Effect, adding the new state object to the NewGameState container
		GrenadeEffectState = TimedGrenades_GameState_Effect_TickingGrenade(
      NewGameState.CreateStateObject(class'TimedGrenades_GameState_Effect_TickingGrenade')
    );
    GrenadeEffectState.Launched = Launched;
    Ability = XComGameState_Ability(History.GetGameStateForObjectID(
      ApplyEffectParameters.AbilityStateObjectRef.ObjectID
    ));
    if (Launched)
    {
      Weapon = XComGameState_Item(History.GetGameStateForObjectID(
        Ability.SourceWeapon.ObjectID
      ));
      GrenadeTemplate = X2GrenadeTemplate(Weapon.GetLoadedAmmoTemplate(Ability));
      SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(
        Ability.OwnerStateObject.ObjectID
      ));

      ItemList = SourceUnit.GetAllInventoryItems();
      foreach ItemList(IterItem)
      {
        if (IterItem.GetMyTemplateName() == GrenadeTemplate.DataName)
        {
          GrenadeEffectState.SourceGrenade = IterItem.GetReference();
          break;
        }
      }
    }
    else
    {
      GrenadeEffectState.SourceGrenade = Ability.SourceWeapon;
    }
    `log("From Ability" @ Ability.GetMyTemplateName());
    `log("Grenade from " @ GrenadeEffectState.SourceGrenade.ObjectID);
		NewEffectState.AddComponentObject(GrenadeEffectState);
		NewGameState.AddStateObject(GrenadeEffectState);
	}

	//add listener to new component effect -- do it here because the RegisterForEvents call happens before OnEffectAdded, so component doesn't yet exist
	ListenerObj = GrenadeEffectState;
	if (ListenerObj == none)
	{
		`Redscreen("TickingGrenade: Failed to find GrenadeComponent Component when registering listener");
		return;
	}

  EventMgr.RegisterForEvent(ListenerObj, 'PlayerTurnBegun', GrenadeEffectState.OnTurnBegun, ELD_OnStateSubmitted, , PlayerState);
}

static function TimedGrenades_GameState_Effect_TickingGrenade GetEffectComponent(XComGameState_Effect Effect)
{
	if (Effect != none) 
		return TimedGrenades_GameState_Effect_TickingGrenade(
      Effect.FindComponentObject(class'TimedGrenades_GameState_Effect_TickingGrenade')
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
	EffectName="TickingGrenade"
	DuplicateResponse = eDupe_Allow;
	bCanBeRedirected = false;
}
