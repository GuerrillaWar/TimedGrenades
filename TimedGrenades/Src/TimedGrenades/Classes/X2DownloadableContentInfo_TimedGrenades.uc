class X2DownloadableContentInfo_TimedGrenades extends X2DownloadableContentInfo Config(Game);

static event OnPostTemplatesCreated()
{
  `log("TimedGrenades :: Present And Correct");

  class'TimedGrenades_WeaponManager'.static.LoadGrenadeProfiles();
  class'TimedGrenades_WeaponManager'.static.LockdownAbilitiesWhenPrimedGrenadeHeld();
}


static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	local int Index;

  for( Index = 0; Index < SetupData.Length; ++Index )
  {
    if (SetupData[Index].TemplateName == 'LaunchGrenade')
    {
      if (class'TimedGrenades_WeaponManager'.static.IsTimedGrenade(SetupData[Index].SourceAmmoRef)) {
        SetupData[Index].TemplateName = 'TG_LaunchGrenade';
        SetupData[Index].Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('TG_LaunchGrenade');
      }
    }
  }
}
