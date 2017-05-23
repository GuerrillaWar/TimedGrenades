class TimedGrenades_X2Action_SpawnImpactActor extends X2Action;

var Vector TargetLocation;
var Vector TargetRotation;
var XComProjectileImpactActor Impact;

simulated state Executing
{
Begin:
		Impact = Spawn( class'XComProjectileImpactActor', self, ,
			TargetLocation,
			Rotator(TargetRotation),
			Impact, true );

		if (Impact != none)
		{
			Impact.HitNormal = TargetRotation;
			Impact.HitLocation = TargetLocation;
			Impact.TraceLocation = TargetLocation; 
			Impact.TraceNormal = TargetRotation;
			Impact.TraceActor = none;
			Impact.Init( );
		}
    CompleteAction();
}
