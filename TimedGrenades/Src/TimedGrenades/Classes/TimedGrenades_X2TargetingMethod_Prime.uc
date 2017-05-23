class TimedGrenades_X2TargetingMethod_Prime extends X2TargetingMethod_Grenade;

function Init(AvailableAction InAction)
{
  super.Init(InAction);
  Cursor.m_fMaxChainedDistance = 0.0;
}

simulated protected function Vector GetSplashRadiusCenter()
{
	local vector Center;
	local TTile SnapTile;

  Center = `XWORLD.GetPositionFromTileCoordinates(UnitState.TileLocation);

	if (SnapToTile)
	{
		SnapTile = `XWORLD.GetTileCoordinatesFromPosition( Center );
		`XWORLD.GetFloorPositionForTile( SnapTile, Center );
	}

	return Center;
}

simulated protected function DrawSplashRadius()
{
	local Vector Center;
	local float Radius;
	local LinearColor CylinderColor;

  Center = `XWORLD.GetPositionFromTileCoordinates(UnitState.TileLocation);

	Radius = Ability.GetAbilityRadius();
	
	/*
	if (!bValid || (m_bTargetMustBeWithinCursorRange && (fTest >= fRestrictedRange) )) {
		CylinderColor = MakeLinearColor(1, 0.2, 0.2, 0.2);
	} else if (m_iSplashHitsFriendliesCache > 0 || m_iSplashHitsFriendlyDestructibleCache > 0) {
		CylinderColor = MakeLinearColor(1, 0.81, 0.22, 0.2);
	} else {
		CylinderColor = MakeLinearColor(0.2, 0.8, 1, 0.2);
	}
	*/

	if( (ExplosionEmitter != none) && (Center != ExplosionEmitter.Location))
	{
		ExplosionEmitter.SetLocation(Center); // Set initial location of emitter
		ExplosionEmitter.SetDrawScale(Radius / 48.0f);
		ExplosionEmitter.SetRotation( rot(0,0,1) );

		if( !ExplosionEmitter.ParticleSystemComponent.bIsActive )
		{
			ExplosionEmitter.ParticleSystemComponent.ActivateSystem();			
		}

		ExplosionEmitter.ParticleSystemComponent.SetMICVectorParameter(0, Name("RadiusColor"), CylinderColor);
		ExplosionEmitter.ParticleSystemComponent.SetMICVectorParameter(1, Name("RadiusColor"), CylinderColor);
	}
}

static function bool UseGrenadePath() { return false; }
