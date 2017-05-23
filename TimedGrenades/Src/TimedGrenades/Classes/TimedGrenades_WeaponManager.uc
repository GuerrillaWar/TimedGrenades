class TimedGrenades_WeaponManager extends Object config(TimedGrenades);

var config array<name>                            arrTimedGrenades;


static function bool IsTimedGrenade(StateObjectReference GrenadeRef)
{
  local XComGameState_Item GrenadeState;
  GrenadeState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(GrenadeRef.ObjectID));

  if (GrenadeState != none) {
    return default.arrTimedGrenades.Find(GrenadeState.GetMyTemplateName()) != INDEX_NONE;
  }

  return false;
}



static function LoadGrenadeProfiles ()
{
  local array<X2DataTemplate> ItemTemplates;
  local X2DataTemplate ItemTemplate;
  local X2GrenadeTemplate GrenadeTemplate;
  local X2ItemTemplateManager Manager;
  local name GrenadeName;

  Manager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

  foreach default.arrTimedGrenades(GrenadeName)
  {
    ItemTemplates.Length = 0;
    Manager.FindDataTemplateAllDifficulties(GrenadeName, ItemTemplates);
    foreach ItemTemplates(ItemTemplate)
    {
      GrenadeTemplate = X2GrenadeTemplate(ItemTemplate);
      GrenadeTemplate.Abilities.RemoveItem('ThrowGrenade');
      GrenadeTemplate.Abilities.AddItem('TG_ThrowGrenade');
      GrenadeTemplate.Abilities.AddItem('TG_PrimeGrenade');
      GrenadeTemplate.Abilities.AddItem('TG_ThrowPrimedGrenade');
      if (GrenadeTemplate.AbilityIconOverrides.Length > 0)
      {
        GrenadeTemplate.AddAbilityIconOverride(
          'TG_ThrowGrenade',
          GrenadeTemplate.AbilityIconOverrides[0].OverrideIcon
        );
        GrenadeTemplate.AddAbilityIconOverride(
          'TG_ThrowPrimedGrenade',
          GrenadeTemplate.AbilityIconOverrides[0].OverrideIcon
        );
        GrenadeTemplate.AddAbilityIconOverride(
          'TG_LaunchGrenade',
          GrenadeTemplate.AbilityIconOverrides[0].OverrideIcon
        );
      }
      GrenadeTemplate.Abilities.AddItem(
        class'TimedGrenades_X2Ability_Grenades'.default.DetonateGrenadeAbilityName
      );
      GrenadeTemplate.Abilities.AddItem(
        class'TimedGrenades_X2Ability_Grenades'.default.DetonateLaunchedGrenadeAbilityName
      );
    }
  }
}


static function LockdownAbilitiesWhenPrimedGrenadeHeld ()
{
  local array<X2DataTemplate> DataTemplates;
  local X2DataTemplate DataTemplate;
  local X2AbilityTemplate AbilityTemplate;
  local X2AbilityTemplateManager Manager;
  local array<name> AbilityNames;
  local name AbilityName;
  local X2Condition_UnitEffects           ExcludeEffects;
  local int Index;
  local bool bInputAbility;

  Manager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
  Manager.GetTemplateNames(AbilityNames);

  foreach AbilityNames(AbilityName)
  {
    if (
      AbilityName == 'TG_ThrowPrimedGrenade' ||
      AbilityName == 'TG_DetonateGrenade' ||
      AbilityName == 'TG_DetonateLaunchedGrenade'
    )
    {
      continue;
    }
    DataTemplates.Length = 0;
    Manager.FindDataTemplateAllDifficulties(AbilityName, DataTemplates);
    foreach DataTemplates(DataTemplate)
    {
      AbilityTemplate = X2AbilityTemplate(DataTemplate);

      for( Index = 0; Index < AbilityTemplate.AbilityTriggers.Length && !bInputAbility; ++Index )
      {
        bInputAbility = AbilityTemplate.AbilityTriggers[Index].IsA('X2AbilityTrigger_PlayerInput');
      }

      if (bInputAbility)
      {
        ExcludeEffects = new class'X2Condition_UnitEffects';
        ExcludeEffects.AddExcludeEffect(class'TimedGrenades_Effect_PrimedGrenade'.default.EffectName, 'AA_HoldingPrimedGrenade');
        AbilityTemplate.AbilityShooterConditions.AddItem(ExcludeEffects);
      }
    }
  }
}
