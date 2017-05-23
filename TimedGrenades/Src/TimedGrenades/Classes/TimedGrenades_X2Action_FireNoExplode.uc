class TimedGrenades_X2Action_FireNoExplode extends X2Action_Fire;

function AddProjectileVolley(X2UnifiedProjectile NewProjectile)
{
  NewProjectile.ProjectileElements[0].PlayEffectOnDeath = (
    ParticleSystem'FX_WP_ProximityMine.P_ProximityMine_Interim'
  );
  NewProjectile.ProjectileElements[0].UseImpactActor = none;
  NewProjectile.ProjectileElements[0].DeathSound = none;
	super.AddProjectileVolley(NewProjectile);
}
