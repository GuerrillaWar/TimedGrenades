class TimedGrenades_GameState_Effect_PrimedGrenade extends XComGameState_BaseObject;

var bool OnExplosionTurn;
var StateObjectReference SourceGrenade;

function XComGameState_Effect GetOwningEffect()
{
	return XComGameState_Effect(`XCOMHISTORY.GetGameStateForObjectID(OwningObjectId));
}

function EventListenerReturn OnTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
  local TimedGrenades_GameState_Effect_PrimedGrenade NewEffectState;
  local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("X2Effect_PrimedGrenade: Marking Explosion Turn");
  NewEffectState = TimedGrenades_GameState_Effect_PrimedGrenade(
    NewGameState.CreateStateObject(Class, ObjectID)
  );
  NewEffectState.OnExplosionTurn = true;
  NewGameState.AddStateObject(NewEffectState);
  `TACTICALRULES.SubmitGameState(NewGameState);

  return ELR_NoInterrupt;
}

function EventListenerReturn OnTurnEnded(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Effect Effect;
  local XComGameState_Unit SourceUnit;
	Effect = GetOwningEffect();
	SourceUnit = XComGameState_Unit(
    `XCOMHISTORY.GetGameStateForObjectID(
      Effect.ApplyEffectParameters.SourceStateObjectRef.ObjectID
    )
  );

  if (OnExplosionTurn)
  {
    DetonateGrenade(Effect, SourceUnit, GameState);
    RemoveEffect(Effect, GameState);
  }

  return ELR_NoInterrupt;
}

function RemoveEffect(XComGameState_Effect Effect, XComGameState RespondingToGameState)
{
	local XComGameStateContext_EffectRemoved EffectRemovedState;
	local XComGameState NewGameState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

  EffectRemovedState = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(Effect);
  NewGameState = History.CreateNewGameState(true, EffectRemovedState);
  Effect.RemoveEffect(NewGameState, RespondingToGameState);

  if (NewGameState.GetNumGameStateObjects() > 0)
  {
    `TACTICALRULES.SubmitGameState(NewGameState);
  }
  else
  {
    `XCOMHISTORY.CleanupPendingGameState(NewGameState);
  }
}


function DetonateGrenade(XComGameState_Effect Effect, XComGameState_Unit SourceUnit, XComGameState RespondingToGameState)
{
	local XComGameState_Ability AbilityState;
	local AvailableAction Action, IterAction;
	local AvailableTarget Target;
  local GameRulesCache_Unit UnitCache;
	local XComGameStateHistory History;
  local vector                DetonationLocation;
  local array<vector>         TargetLocations;
  local int AbilityID;

	History = `XCOMHISTORY;
  `TACTICALRULES.GetGameRulesCache_Unit(SourceUnit.GetReference(), UnitCache);
	AbilityID = SourceUnit.FindAbility(
    class'TimedGrenades_X2Ability_Grenades'.default.DetonateGrenadeAbilityName,
    SourceGrenade
  ).ObjectID;
  foreach UnitCache.AvailableActions(IterAction)
  {
    if (IterAction.AbilityObjectRef.ObjectID == AbilityID)
    {
      Action = IterAction;
    }
  }
	if (Action.AbilityObjectRef.ObjectID != 0)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));

    DetonationLocation = `XWORLD.GetPositionFromTileCoordinates(SourceUnit.TileLocation);
		if (AbilityState != none)
		{
			/* Action.AvailableCode = 'AA_Success'; */
			AbilityState.GatherAdditionalAbilityTargetsForLocation(DetonationLocation, Target);
			Action.AvailableTargets.AddItem(Target);
      TargetLocations.AddItem(DetonationLocation);

			class'XComGameStateContext_Ability'.static.ActivateAbility(Action, 0, TargetLocations);
		}
	}
}

