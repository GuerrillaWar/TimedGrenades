class TimedGrenades_GameState_Effect_TickingGrenade extends XComGameState_BaseObject;

var bool Launched;
var StateObjectReference SourceGrenade;


function XComGameState_Effect GetOwningEffect()
{
	return XComGameState_Effect(`XCOMHISTORY.GetGameStateForObjectID(OwningObjectId));
}

function EventListenerReturn OnTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Effect Effect;
  local XComGameState_Unit SourceUnit;
  local Object EffectObj;
	Effect = GetOwningEffect();
  EffectObj = self;

	SourceUnit = XComGameState_Unit(
    `XCOMHISTORY.GetGameStateForObjectID(
      Effect.ApplyEffectParameters.SourceStateObjectRef.ObjectID
    )
  );

  `XEVENTMGR.UnRegisterFromEvent(EffectObj, EventID);
  DetonateGrenade(Effect, SourceUnit, GameState);
  return ELR_NoInterrupt;
}


function DetonateGrenade(XComGameState_Effect Effect, XComGameState_Unit SourceUnit, XComGameState RespondingToGameState)
{
	local XComGameState_Ability AbilityState;
	local AvailableAction Action, IterAction;
	local AvailableTarget Target;
  local GameRulesCache_Unit UnitCache;
	local XComGameStateContext_EffectRemoved EffectRemovedState;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
  local name AbilityName;
  local int AbilityID;

	History = `XCOMHISTORY;
  `TACTICALRULES.GetGameRulesCache_Unit(SourceUnit.GetReference(), UnitCache);
  AbilityName = Launched
    ? class'TimedGrenades_X2Ability_Grenades'.default.DetonateLaunchedGrenadeAbilityName
    : class'TimedGrenades_X2Ability_Grenades'.default.DetonateGrenadeAbilityName;
	AbilityID = SourceUnit.FindAbility(AbilityName, SourceGrenade).ObjectID;

  foreach UnitCache.AvailableActions(IterAction)
  {
    if (IterAction.AbilityObjectRef.ObjectID == AbilityID)
    {
      Action = IterAction;
    }
  }
  `log(AbilityName @ "ID is" @ AbilityID);
  `log(AbilityName @ "found action ID is" @ Action.AbilityObjectRef.ObjectID);
  `log(Action.AvailableCode);

	if (Action.AbilityObjectRef.ObjectID != 0)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));
		if (AbilityState != none)
		{
			/* Action.AvailableCode = 'AA_Success'; */
			AbilityState.GatherAdditionalAbilityTargetsForLocation(Effect.ApplyEffectParameters.AbilityInputContext.TargetLocations[0], Target);
			Action.AvailableTargets.AddItem(Target);

			if (class'XComGameStateContext_Ability'.static.ActivateAbility(Action, 0, Effect.ApplyEffectParameters.AbilityInputContext.TargetLocations))
			{
				EffectRemovedState = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(Effect);
				NewGameState = History.CreateNewGameState(true, EffectRemovedState);
				Effect.RemoveEffect(NewGameState, RespondingToGameState);

        if (NewGameState.GetNumGameStateObjects() > 0)
        {
          `TACTICALRULES.SubmitGameState(NewGameState);

          //  effects may have changed action availability - if a unit died, took damage, etc.
        }
        else
        {
          `XCOMHISTORY.CleanupPendingGameState(NewGameState);
        }
			}
		}
	}
}

