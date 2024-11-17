const float Q2_MELEE_DISTANCE = 50.0; //80
const float Q2_RANGE_MELEE = 60.0; //20
const float Q2_RANGE_NEAR = 500.0;
const float Q2_RANGE_MID = 1000.0;

const int TASKSTATUS_RUNNING = 1;

enum steptype_e
{
	STEP_CONCRETE = 0, // default step sound
	STEP_METAL, // metal floor
	STEP_DIRT, // dirt, sand, rock
	STEP_VENT, // ventilation duct
	STEP_GRATE, // metal grating
	STEP_TILE, // floor tiles
	STEP_SLOSH, // shallow liquid puddle
	STEP_WADE, // wading in liquid
	STEP_LADDER, // climbing ladder
	STEP_WOOD,
	STEP_FLESH,
	STEP_SNOW
};

class CBaseQ2NPC : ScriptBaseMonsterEntity
{
	protected float m_flGibHealth;
	protected float m_flAttackFinished;
	protected int m_iStepLeft;

	int ObjectCaps()
	{
		if( self.IsPlayerAlly() ) 
			return (BaseClass.ObjectCaps() | FCAP_IMPULSE_USE);

		return BaseClass.ObjectCaps();
	}

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "is_player_ally" )
		{
			if( atoi(szValue) >= 1 )
				self.SetPlayerAllyDirect( true );

			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void FollowerUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		self.FollowerPlayerUse( pActivator, pCaller, useType, flValue );

		/*CBaseEntity@ pTarget = self.m_hTargetEnt;
		
		if( pTarget is pActivator )
			g_SoundSystem.PlaySentenceGroup( self.edict(), "BA_OK", 1.0, ATTN_NORM, 0, PITCH_NORM );
		else
			g_SoundSystem.PlaySentenceGroup( self.edict(), "BA_WAIT", 1.0, ATTN_NORM, 0, PITCH_NORM );*/
	} 

	bool M_CheckAttack( float flDist )
	{
		float flChance;

		if( g_Engine.time < m_flAttackFinished )
			return false;

		if( flDist >= 1000 ) //RANGE_FAR (> 1000)
			return false;

		if( flDist <= Q2_RANGE_MELEE )
			flChance = 0.4;  //0.2
		else if( flDist <= Q2_RANGE_NEAR )
			flChance = 0.25; //0.1
		else if( flDist <= Q2_RANGE_MID )
			flChance = 0.06; //0.02
		else
			return false;

		//if( skill->value == 0 )
			//flChance *= 0.5;
		//else if( skill->value >= 2 )
			flChance *= 2.0;

		if( Math.RandomFloat(0.0, 1.0) < flChance )
		{
			m_flAttackFinished = g_Engine.time + Math.RandomFloat( 1.0, 2.0 ); //2*random();

			return true;
		}

		return true;
	}

	CBaseEntity@ Q2CheckTraceHullAttack( float flDist, float flDamage, int iDmgType )
	{
		TraceResult tr;

		if( self.IsPlayer() )
			Math.MakeVectors( self.pev.angles );
		else
			Math.MakeAimVectors( self.pev.angles );

		Vector vecStart = self.pev.origin;
		vecStart.z += self.pev.size.z * 0.5;
		Vector vecEnd = vecStart + (g_Engine.v_forward * flDist );

		g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, self.edict(), tr );

		if( tr.pHit !is null )
		{
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			if( flDamage > 0 )
				pEntity.TakeDamage( self.pev, self.pev, flDamage, iDmgType );

			return pEntity;
		}

		return null;
	}

	void monster_fire_bullet( Vector vecStart, Vector vecDir, float flDamage, Vector vecSpread )
	{
		self.FireBullets( 1, vecStart, vecDir, vecSpread, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), self.pev );
	}

	void monster_fire_shotgun( Vector vecStart, Vector vecDir, float flDamage, Vector vecSpread, int iCount )
	{
		for( int i = 0; i < iCount; i++ )
			self.FireBullets( 1, vecStart, vecDir, vecSpread, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), self.pev );

		//too loud
		//self.FireBullets( iCount, vecStart, vecDir, vecSpread, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), self.pev );
	}

	void monster_fire_blaster( Vector vecStart, Vector vecDir, float flDamage, int flSpeed )
	{
		CBaseEntity@ pLaser = g_EntityFuncs.Create( "q2lasernpc", vecStart, vecDir, false, self.edict() ); 
		pLaser.pev.velocity = vecDir * flSpeed;
		pLaser.pev.dmg = flDamage;
		pLaser.pev.angles = Math.VecToAngles( vecDir.Normalize() );
		pLaser.pev.targetname = self.GetClassname(); //for death messages
	}

	void monster_fire_rocket( Vector vecStart, Vector vecDir, float flDamage, int flSpeed, float flScale = 1.0 )
	{
		CBaseEntity@ pRocket = g_EntityFuncs.Create( "q2rocketnpc", vecStart, vecDir, false, self.edict() ); 
		pRocket.pev.velocity = vecDir * flSpeed;
		pRocket.pev.dmg = flDamage;
		pRocket.pev.angles = Math.VecToAngles( vecDir.Normalize() );
		pRocket.pev.scale = flScale;
		pRocket.pev.targetname = self.GetClassname(); //for death messages
	}

	void monster_fire_grenade( Vector vecStart, Vector vecVelocity, float flDamage, float flScale = 1.0 )
	{
		CBaseEntity@ pGrenade = g_EntityFuncs.Create( "q2grenadenpc", vecStart, g_vecZero, false, self.edict() );
		pGrenade.pev.velocity = vecVelocity;
		pGrenade.pev.dmg = flDamage;
		pGrenade.pev.scale = flScale;
		pGrenade.pev.targetname = self.GetClassname(); //for death messages
	}

	void monster_fire_bfg( Vector vecStart, Vector vecDir, float flDamage, int flSpeed )
	{
		CBaseEntity@ pBFG = g_EntityFuncs.Create( "q2bfgnpc", vecStart, vecDir, false, self.edict() );
		pBFG.pev.velocity = vecDir * flSpeed;
		pBFG.pev.dmg = flDamage;
		pBFG.pev.targetname = self.GetClassname(); //for death messages
	}

	void monster_fire_railgun( Vector vecStart, Vector vecEnd, float flDamage )
	{
		TraceResult tr;

		vecEnd = vecStart + vecEnd * 8192;
		Vector railstart = vecStart;
		
		edict_t@ ignore = self.edict();
		
		while( ignore !is null )
		{
			g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, ignore, tr );

			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			
			if( pHit.IsMonster() or pHit.IsPlayer() or tr.pHit.vars.solid == SOLID_BBOX or (tr.pHit.vars.ClassNameIs( "func_breakable" ) and tr.pHit.vars.takedamage != DAMAGE_NO) )
				@ignore = tr.pHit;
			else
				@ignore = null;

			g_WeaponFuncs.ClearMultiDamage();

			if( tr.pHit !is self.edict() and pHit.pev.takedamage != DAMAGE_NO )
				pHit.TraceAttack( self.pev, flDamage, vecEnd, tr, DMG_ENERGYBEAM | DMG_LAUNCH ); 

			g_WeaponFuncs.ApplyMultiDamage( self.pev, self.pev );

			vecStart = tr.vecEndPos;
		}

		CreateRailbeam( railstart, tr.vecEndPos );

		if( tr.pHit !is null )
		{
			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			
			if( pHit is null or pHit.IsBSPModel() == true )
			{
				g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_SNIPER );
				g_Utility.DecalTrace( tr, DECAL_BIGSHOT4 + Math.RandomLong(0,1) );

				int r = 155, g = 255, b = 255;

				NetworkMessage railimpact( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
					railimpact.WriteByte( TE_DLIGHT );
					railimpact.WriteCoord( tr.vecEndPos.x );
					railimpact.WriteCoord( tr.vecEndPos.y );
					railimpact.WriteCoord( tr.vecEndPos.z );
					railimpact.WriteByte( 8 );//radius
					railimpact.WriteByte( int(r) );
					railimpact.WriteByte( int(g) );
					railimpact.WriteByte( int(b) );
					railimpact.WriteByte( 48 );//life
					railimpact.WriteByte( 12 );//decay
				railimpact.End();
			}
		}
	}

	void CreateRailbeam( Vector vecStart, Vector vecEnd )
	{
		CBaseEntity@ cbeBeam = g_EntityFuncs.CreateEntity( "q2railbeamnpc", null, false );
		q2::q2railbeamnpc@ pBeam = cast<q2::q2railbeamnpc@>(CastToScriptClass(cbeBeam));
		pBeam.m_vecStart = vecStart;
		pBeam.m_vecEnd = vecEnd;
		g_EntityFuncs.SetOrigin( pBeam.self, vecStart );
		g_EntityFuncs.DispatchSpawn( pBeam.self.edict() );
	}

	void monster_muzzleflash( Vector vecOrigin, int iRadius, int iR, int iG, int iB )
	{
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_DLIGHT );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteByte( iRadius + Math.RandomLong(0, 6) ); //radius
			m1.WriteByte( iR ); //rgb
			m1.WriteByte( iG );
			m1.WriteByte( iB );
			m1.WriteByte( 10 ); //lifetime
			m1.WriteByte( 35 ); //decay
		m1.End();
	}

	void MachineGunEffects( Vector vecOrigin, int iScale = 5 )
	{
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_SMOKE );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z - 10.0 );
			m1.WriteShort( g_EngineFuncs.ModelIndex("sprites/steam1.spr") );
			m1.WriteByte( iScale ); // scale * 10
			m1.WriteByte( 105 ); // framerate
		m1.End();

		NetworkMessage m2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m2.WriteByte( TE_DLIGHT );
			m2.WriteCoord( vecOrigin.x );
			m2.WriteCoord( vecOrigin.y );
			m2.WriteCoord( vecOrigin.z );
			m2.WriteByte( 16 ); //radius
			m2.WriteByte( 240 ); //rgb
			m2.WriteByte( 180 );
			m2.WriteByte( 0 );
			m2.WriteByte( 8 ); //lifetime
			m2.WriteByte( 50 ); //decay
		m2.End();
	}

	Vector closest_point_to_box( const Vector &in from, const Vector &in absmins, const Vector &in absmaxs )
	{
		return Vector(
			(from.x < absmins.x) ? absmins.x : (from.x > absmaxs.x) ? absmaxs.x : from.x,
			(from.y < absmins.y) ? absmins.y : (from.y > absmaxs.y) ? absmaxs.y : from.y,
			(from.z < absmins.z) ? absmins.z : (from.z > absmaxs.z) ? absmaxs.z : from.z
		);
	}

	void ThrowGib( EHandle hEntity, int iCount, const string &in sGibName, float flDamage, int iBone = -1, int iType = 0, int iSkin = 0 )
	{
		CBaseEntity@ pEntity = hEntity.GetEntity();
		if( pEntity is null ) return;

		for( int i = 0; i < iCount; i++ )
		{
			CGib@ pGib = g_EntityFuncs.CreateGib( pEntity.pev.origin, g_vecZero );
			pGib.Spawn( sGibName );
			pGib.pev.skin = iSkin;

			if( iBone >= 0 )
			{
				Vector vecBonePos;
				g_EngineFuncs.GetBonePosition( pEntity.edict(), iBone, vecBonePos, void );
				g_EntityFuncs.SetOrigin( pGib, vecBonePos );
			}
			else
			{
				Vector vecOrigin = pEntity.pev.origin;

				vecOrigin.x = pEntity.pev.absmin.x + pEntity.pev.size.x * (Math.RandomFloat(0 , 1));
				vecOrigin.y = pEntity.pev.absmin.y + pEntity.pev.size.y * (Math.RandomFloat(0 , 1));
				vecOrigin.z = pEntity.pev.absmin.z + pEntity.pev.size.z * (Math.RandomFloat(0 , 1)) + 1;

				g_EntityFuncs.SetOrigin( pGib, vecOrigin );
			}

			pGib.pev.velocity = VelocityForDamage( flDamage );

			pGib.pev.velocity.x += Math.RandomFloat( -0.15, 0.15 );
			pGib.pev.velocity.y += Math.RandomFloat( -0.25, 0.15 );
			pGib.pev.velocity.z += Math.RandomFloat( -0.2, 1.9 );

			pGib.pev.avelocity.x = Math.RandomFloat( 70, 200 );
			pGib.pev.avelocity.y = Math.RandomFloat( 70, 200 );

			pGib.LimitVelocity();

			if( iType == BREAK_FLESH )
			{
				pGib.m_bloodColor = BLOOD_COLOR_RED;
				pGib.m_cBloodDecals = 5;
				pGib.m_material = matFlesh;
				g_WeaponFuncs.SpawnBlood( pGib.pev.origin, BLOOD_COLOR_RED, 400 );
			}
			else
				pGib.m_bloodColor = DONT_BLEED;
		}
	}

	//from pm_shared.c, because model event 2003 doesn't work :aRage:
	void monster_footstep( int iPitch = PITCH_NORM, bool bSetOrigin = false, Vector vecSetOrigin = g_vecZero )
	{
		int iRand;
		float flVol = 1.0;

		if( m_iStepLeft == 0 ) m_iStepLeft = 1;
			else m_iStepLeft = 0;

		iRand = Math.RandomLong(0, 1) + (m_iStepLeft * 2);

		Vector vecOrigin = pev.origin;

		if( bSetOrigin )
			vecOrigin = vecSetOrigin;

		TraceResult tr;
		g_Utility.TraceLine( vecOrigin, vecOrigin + Vector(0, 0, -64),  ignore_monsters, self.edict(), tr );

		edict_t@ pWorld = g_EntityFuncs.Instance(0).edict();
		if( tr.pHit !is null ) @pWorld = tr.pHit;

		string sTexture = g_Utility.TraceTexture( pWorld, vecOrigin, vecOrigin + Vector(0, 0, -64) );
		char chTextureType = g_SoundSystem.FindMaterialType( sTexture );
		int iStep = MapTextureTypeStepType( chTextureType );

		if( pev.waterlevel == WATERLEVEL_FEET ) iStep = STEP_SLOSH;
		else if( pev.waterlevel >= WATERLEVEL_WAIST ) iStep = STEP_WADE;

		switch( iStep )
		{
			case STEP_VENT:
			{
				flVol = 0.7; //fWalking ? 0.4 : 0.7;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_duct1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_duct3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_duct2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_duct4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_DIRT:
			{
				flVol = 0.55; //fWalking ? 0.25 : 0.55;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_dirt1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_dirt3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_dirt2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_dirt4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_GRATE:
			{
				flVol = 0.5; //fWalking ? 0.2 : 0.5;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_grate1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_grate3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_grate2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_grate4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_METAL:
			{
				flVol = 0.5; //fWalking ? 0.2 : 0.5;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_metal1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_metal3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_metal2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_metal4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_SLOSH:
			{
				flVol = 0.5; //fWalking ? 0.2 : 0.5;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_slosh1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_slosh3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_slosh2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_slosh4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_WADE: { break; }

			case STEP_TILE:
			{
				flVol = 0.5; //fWalking ? 0.2 : 0.5;

				if( Math.RandomLong(0, 4) == 0 )
					iRand = 4;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_tile1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_tile3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_tile2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_tile4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 4: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_tile5.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_WOOD:
			{
				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_wood1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_wood3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_wood2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_wood4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_FLESH:
			{
				flVol = 0.55; //fWalking ? 0.25 : 0.55;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_organic1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_organic3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_organic2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_organic4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_SNOW:
			{
				flVol = 0.55; //fWalking ? 0.25 : 0.55;

				if( Math.RandomLong(0, 1) == 1 )
					iRand += 4;

				switch( iRand )
				{
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 4:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow5.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 5:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow6.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 6:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow7.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 7:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow8.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_CONCRETE:
			default:
			{
				flVol = 0.5; //fWalking ? 0.2 : 0.5;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_step1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_step3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_step2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_step4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}
		}

		//g_Game.AlertMessage( at_notice, "sTexture: %1\n", sTexture );
		//g_Game.AlertMessage( at_notice, "chTextureType: %1\n", string(chTextureType) );
		//g_Game.AlertMessage( at_notice, "iStep: %1\n", iStep );
	}

	int MapTextureTypeStepType( char chTextureType )
	{
		if( chTextureType == 'C' ) return STEP_CONCRETE;
		else if( chTextureType == 'M' ) return STEP_METAL;
		else if( chTextureType == 'D' ) return STEP_DIRT;
		else if( chTextureType == 'V' ) return STEP_VENT;
		else if( chTextureType == 'G' ) return STEP_GRATE;
		else if( chTextureType == 'T' ) return STEP_TILE;
		else if( chTextureType == 'S' ) return STEP_SLOSH;
		else if( chTextureType == 'W' ) return STEP_WOOD;
		else if( chTextureType == 'F' ) return STEP_FLESH;
		else if( chTextureType == 'O' ) return STEP_SNOW;

		return STEP_CONCRETE;
	}

	Vector VelocityForDamage( float flDamage )
	{
		Vector vec( Math.RandomFloat(-20, 20), Math.RandomFloat(-20, 20), Math.RandomFloat(30, 40) );

		if( flDamage > 50 )
			vec = vec * 0.7;
		else if( flDamage > 200 )
			vec = vec * 2;
		else
			vec = vec * 10;

		return vec;
	}

	int GetAnim()
	{
		return pev.sequence;
	}

	bool GetAnim( int iAnim )
	{
		return pev.sequence == iAnim;
	}

	void SetAnim( int iAnim, float flFramerate = 1.0, float flFrame = 0.0 )
	{
		pev.sequence = iAnim;
		self.ResetSequenceInfo();
		pev.frame = flFrame;
		pev.framerate = flFramerate;
	}

	int GetFrame( int iMaxFrames )
	{
		return int( (pev.frame/255) * iMaxFrames );
	}

	void SetFrame( float flMaxFrames, float flFrame )
	{
		pev.frame = float( (flFrame / flMaxFrames) * 255 );
	}

	float SetFrame2( float flMaxFrames, float flFrame )
	{
		return float( (flFrame / flMaxFrames) * 255 );
	}

	bool IsBetween( float flValue, float flMin, float flMax )
	{
		return (flValue > flMin and flValue < flMax);
	}

	bool IsBetween( int iValue, int iMin, int iMax )
	{
		return (iValue > iMin and iValue < iMax);
	}

	bool IsBetween2( float flValue, float flMin, float flMax )
	{
		return (flValue >= flMin and flValue <= flMax);
	}

	bool IsBetween2( int iValue, int iMin, int iMax )
	{
		return (iValue >= iMin and iValue <= iMax);
	}
}