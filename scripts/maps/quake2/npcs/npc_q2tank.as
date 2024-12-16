namespace npc_q2tank
{

const string NPC_MODEL						= "models/quake2/monsters/tank/tank.mdl";
const string MODEL_GIB_GEAR				= "models/quake2/objects/gibs/gear.mdl";
const string MODEL_GIB_MEAT				= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_METAL				= "models/quake2/objects/gibs/sm_metal.mdl";
const string MODEL_GIB_ARM					= "models/quake2/monsters/tank/gibs/barm.mdl";
const string MODEL_GIB_CHEST				= "models/quake2/monsters/tank/gibs/chest.mdl";
const string MODEL_GIB_FOOT				= "models/quake2/monsters/tank/gibs/foot.mdl";
const string MODEL_GIB_HEAD				= "models/quake2/monsters/tank/gibs/head.mdl";
const string MODEL_GIB_THIGH				= "models/quake2/monsters/tank/gibs/thigh.mdl";

const Vector NPC_MINS							= Vector( -32, -32, 0 );
const Vector NPC_MAXS							= Vector( 32, 32, 113 ); //88 in quake 2

const float NPC_HEALTH							= 750.0;
const float NPC_HEALTH_COMM				= 1000.0;
const float NPC_HEALTH_COMM_G			= 1500.0;

const int AE_ATTACK_MACHINEGUN		= 11;
const int AE_ATTACK_BLASTER				= 12;
const int AE_ATTACK_BLASTER_REFIRE	= 13;
const int AE_ATTACK_ROCKET					= 14;
const int AE_ATTACK_ROCKET_REFIRE		= 15;
const int AE_FOOTSTEP							= 16;

const float MGUN_DMG							= 20.0;
const float BLASTER_DMG						= 30.0;
const float BLASTER_SPEED					= 800.0;
const float ROCKET_DMG						= 50.0;
const float ROCKET_SPEED						= 650.0;
const float ROCKET_SPEED_HEAT			= 500.0;
const float ROCKET_HEATSEEKING			= 0.075; //turn-rate, higher number means better heatseeking

const float RANGE_SHORT						= 160.0; //125 * 1.285
const float RANGE_MID							= 320.0; //250 * 1.285

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/tank/death.wav",
	"quake2/npcs/tank/tnkidle1.wav",
	"quake2/npcs/tank/sight1.wav",
	"quake2/npcs/tank/step.wav",
	"quake2/npcs/tank/tnkpain2.wav",
	"quake2/npcs/tank/pain.wav",
	"quake2/npcs/tank/tnkatck3.wav", //blaster
	"quake2/npcs/tank/tnkatck1.wav", //rocket launcher
	"quake2/npcs/tank/tnkatk2a.wav", //machine gun
	"quake2/npcs/tank/tnkatk2b.wav",
	"quake2/npcs/tank/tnkatk2c.wav",
	"quake2/npcs/tank/tnkatk2d.wav",
	"quake2/npcs/tank/tnkatk2e.wav",
	"quake2/npcs/tank/tnkdeth2.wav" //thud when falling to the ground after death
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_DEATH_NORMAL,
	SND_IDLE,
	SND_SIGHT,
	SND_FOOTSTEP,
	SND_PAIN,
	SND_PAIN_C,
	SND_BLASTER,
	SND_ROCKET,
	SND_MACHINEGUN
};

const array<string> arrsNPCAnims =
{
	"pain1",
	"pain2",
	"pain3"
};

enum anim_e
{
	ANIM_PAIN1 = 0,
	ANIM_PAIN2,
	ANIM_PAIN3
};

final class npc_q2tank : CBaseQ2NPC
{
	private bool m_bGibbed;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, NPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, NPC_MINS, NPC_MAXS );

		float flHealth;

		if( self.GetClassname() == "npc_q2tank" )
		{
			flHealth						= NPC_HEALTH * m_flHealthMultiplier;
			m_flGibHealth			= -200.0;
		}
		else
		{
			pev.skin					= 2;
			flHealth						= NPC_HEALTH_COMM * m_flHealthMultiplier;
			m_flGibHealth			= -225.0;
		}

		if( (pev.weapons & q2::SPAWNFLAG_TANK_COMMANDER_GUARDIAN) != 0 )
		{
			if( pev.scale <= 0 )
				pev.scale = 1.5;

			flHealth						= NPC_HEALTH_COMM_G * m_flHealthMultiplier;
		}

		if( pev.health <= 0 )
			pev.health					= flHealth;

		pev.solid						= SOLID_SLIDEBOX;
		pev.movetype				= MOVETYPE_STEP;

		self.m_bloodColor			= DONT_BLEED;
		self.m_flFieldOfView		= 0.5;
		self.m_afCapability			= bits_CAP_DOORS_GROUP;

		if( string(self.m_FormattedName).IsEmpty() )
		{
			if( self.GetClassname() == "npc_q2tank" )
				self.m_FormattedName	= "Tank";
			else
				self.m_FormattedName	= "Tank Commander";
		}

		m_flHeatTurnRate			= ROCKET_HEATSEEKING;

		CommonSpawn();

		self.MonsterInit();

		if( self.IsPlayerAlly() )
			SetUse( UseFunction(this.FollowerUse) );
	}

	void Precache()
	{
		uint i;

		g_Game.PrecacheModel( NPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_GEAR );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_METAL );
		g_Game.PrecacheModel( MODEL_GIB_ARM );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_FOOT );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
		g_Game.PrecacheModel( MODEL_GIB_THIGH );

		for( i = 0; i < arrsNPCSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( arrsNPCSounds[i] );
	}

	void FollowerUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		self.FollowerPlayerUse( pActivator, pCaller, useType, flValue );
	}

	void SetYawSpeed() //SUPER IMPORTANT, NPC WON'T DO ANYTHING WITHOUT THIS :aRage:
	{
		int ys = 120;

		if( self.m_Activity == ACT_MELEE_ATTACK1 ) //no turning when firing machine gun
			ys = 0;

		pev.yaw_speed = ys;
	}

	int Classify()
	{
		if( self.IsPlayerAlly() ) 
			return CLASS_PLAYER_ALLY;

		return CLASS_ALIEN_MILITARY;
	}

	//don't run away at low health!
	int IgnoreConditions() { return ( bits_COND_SEE_FEAR | bits_COND_LIGHT_DAMAGE | bits_COND_HEAVY_DAMAGE ); }

	void IdleSoundQ2()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_IDLE], VOL_NORM, ATTN_IDLE );
	}

	void AlertSound()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );
	}

	void DeathSound()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_DEATH_NORMAL], VOL_NORM, ATTN_NORM );
	}

	Schedule@ GetScheduleOfType( int Type )
	{
		switch( Type )
		{
			case SCHED_RANGE_ATTACK1:
			{
				//TESTING
				//return BaseClass.GetScheduleOfType( SCHED_MELEE_ATTACK1 ); //machine gun
				//return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 ); //blaster
				//return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK2 ); //rocket launcher

				float flRandom = Math.RandomFloat(0.0, 1.0);
				float flDist = (pev.origin - self.m_hEnemy.GetEntity().pev.origin).Length();

				if( flDist <= RANGE_SHORT )
				{
					if( flRandom < 0.5 ) //0.4
						return BaseClass.GetScheduleOfType( SCHED_MELEE_ATTACK1 ); //machine gun
					else 
						return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 ); //blaster
				}
				else if( flDist <= RANGE_MID )
				{
					if( flRandom < 0.25 ) //0.5
						return BaseClass.GetScheduleOfType( SCHED_MELEE_ATTACK1 ); //machine gun
					else
						return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 ); //blaster
				}
				else
				{
					if( flRandom < 0.33 )
						return BaseClass.GetScheduleOfType( SCHED_MELEE_ATTACK1 ); //machine gun
					else if( flRandom < 0.66 )
					{
						pev.pain_finished = g_Engine.time + 5.0; // no pain for a while
						return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK2 ); //rocket launcher
					}
					else
						return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 ); //blaster
				}
			}
		}

		return BaseClass.GetScheduleOfType( Type );
	}

	void HandleAnimEventQ2( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case AE_ATTACK_MACHINEGUN:
			{
				Vector vecMuzzle;
				self.GetAttachment( 0, vecMuzzle, void );

				monster_muzzleflash( vecMuzzle, 255, 255, 0 );
				MachineGunEffects( vecMuzzle );
				TankMachineGun( vecMuzzle );

				break;
			}

			case AE_ATTACK_BLASTER:
			{
				Vector vecMuzzle;
				self.GetAttachment( 2, vecMuzzle, void );

				monster_muzzleflash( vecMuzzle, 255, 255, 0 );
				TankBlaster( vecMuzzle );

				break;
			}

			case AE_ATTACK_BLASTER_REFIRE:
			{
				if( q2::g_iDifficulty >= q2::DIFF_HARD and self.m_hEnemy.IsValid() and self.m_hEnemy.GetEntity().pev.health > 0 )
				{
					if( self.FVisible(self.m_hEnemy, true) and Math.RandomFloat(0, 1) <= 0.6 )
						SetFrame( 22, 10 );
				}

				break;
			}

			//1 = Left rocket (looking at the tank)
			//2 = Middle rocket
			//3 = Right rocket (looking at the tank)
			case AE_ATTACK_ROCKET:
			{
				Vector vecMuzzle;
				self.GetAttachment( 3, vecMuzzle, void );

				if( atoi(pEvent.options()) == 1 )
				{
					Math.MakeVectors( pev.angles );
					vecMuzzle = vecMuzzle + g_Engine.v_right * 8.0;
				}
				else if( atoi(pEvent.options()) == 3 )
				{
					Math.MakeVectors( pev.angles );
					vecMuzzle = vecMuzzle - g_Engine.v_right * 8.0;					
				}

				TankRocket( vecMuzzle );

				break;
			}

			case AE_ATTACK_ROCKET_REFIRE:
			{
				if( self.m_hEnemy.IsValid() and self.m_hEnemy.GetEntity().pev.health > 0 )
				{
					if( self.FVisible(self.m_hEnemy, true) and Math.RandomFloat(0, 1) <= 0.4 )
						SetFrame( 53, 22 );
				}

				break;
			}

			case AE_FOOTSTEP:
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_FOOTSTEP], VOL_NORM, ATTN_NORM );
				break;
			}			
		}
	}

	void TankMachineGun( Vector vecStart )
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MACHINEGUN + Math.RandomLong(0, 4)], VOL_NORM, ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.1, self );

		Vector vecBonePos;

		g_EngineFuncs.GetBonePosition( self.edict(), 4, vecBonePos, void );
		Vector vecAim = (vecStart - vecBonePos).Normalize();

		if( self.m_hEnemy.IsValid() )
		{
			Vector vecTarget;
			vecTarget = self.m_hEnemy.GetEntity().pev.origin;
			vecTarget.z += self.m_hEnemy.GetEntity().pev.view_ofs.z;
			vecTarget = (vecTarget - vecStart).Normalize();
			vecAim.z = vecTarget.z;
		}

		monster_fire_weapon( q2::WEAPON_BULLET, vecStart, vecAim, MGUN_DMG );
	}

	void TankBlaster( Vector vecStart )
	{
		if( !self.m_hEnemy.IsValid() )
			return;

		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_BLASTER], VOL_NORM, ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.1, self );

		Vector vecAim;
		PredictAim( self.m_hEnemy, vecStart, 0, false, 0.0, vecAim, void );

		monster_fire_weapon( q2::WEAPON_BLASTER, vecStart, vecAim, BLASTER_DMG, BLASTER_SPEED );
	}

	void TankRocket( Vector vecStart )
	{
		Vector vecAim;

		if( self.m_hEnemy.IsValid() )
		{
			// don't shoot at feet if they're above where i'm shooting from.
			if( Math.RandomFloat(0.0, 1.0) < 0.66 or vecStart.z < self.m_hEnemy.GetEntity().pev.absmin.z )
			{
				Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
				vecEnemyOrigin.z += self.m_hEnemy.GetEntity().pev.view_ofs.z;
				vecAim = (vecEnemyOrigin - vecStart).Normalize();
			}
			else
			{
				Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
				vecEnemyOrigin.z = self.m_hEnemy.GetEntity().pev.absmin.z + 1;
				vecAim = (vecEnemyOrigin - vecStart).Normalize();
			}

			Vector vecTrace;

			if( Math.RandomFloat(0.0, 1.0) < (0.2 + ((3 - q2::g_iDifficulty) * 0.15)) )
			{
				float flRocketSpeed;
				if( pev.speed > 0.0 )
					flRocketSpeed = pev.speed;
				else if( (pev.weapons & q2::SPAWNFLAG_TANK_COMMANDER_HEAT_SEEKING) != 0 ) 
					flRocketSpeed = ROCKET_SPEED_HEAT;
				else
					flRocketSpeed = ROCKET_SPEED;

				PredictAim( self.m_hEnemy, vecStart, flRocketSpeed, false, 0.0, vecAim, vecTrace );
			}

			// paranoia, make sure we're not shooting a target right next to us
			TraceResult tr;
			g_Utility.TraceLine( vecStart, vecTrace, missile, self.edict(), tr );
			if( tr.flFraction > 0.5 or tr.fAllSolid == 0 ) //trace.ent->solid != SOLID_BSP
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_ROCKET], VOL_NORM, ATTN_NORM );
				GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.3, self );

				monster_muzzleflash( vecStart, 255, 128, 51 );

				if( (pev.weapons & q2::SPAWNFLAG_TANK_COMMANDER_HEAT_SEEKING) != 0 ) 
					monster_fire_weapon( q2::WEAPON_HEATSEEKING, vecStart, vecAim, ROCKET_DMG, ROCKET_SPEED_HEAT );
				else
					monster_fire_weapon( q2::WEAPON_ROCKET, vecStart, vecAim, ROCKET_DMG, ROCKET_SPEED );
			}
		}
	}

	//attacks are handled in GetScheduleOfType
	bool CheckMeleeAttack1( float flDot, float flDist ) { return false; }
	bool CheckRangeAttack2( float flDot, float flDist ) { return false; }

	bool CheckRangeAttack1( float flDot, float flDist )
	{
		if( M_CheckAttack(flDist) and flDot >= 0.5 )
			return true;

		return false;
	}

	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		float psave = CheckPowerArmor( pevInflictor, flDamage );
		flDamage -= psave;

		if( pev.health < (pev.max_health / 2) )
			pev.skin |= 1;
		else
			pev.skin &= ~1;

		pevAttacker.frags += ( flDamage/90 );

		pev.dmg = flDamage;

		if( pev.deadflag == DEAD_NO )
			HandlePain( flDamage , pevInflictor.classname );

		//don't send the tank flying unless the damage is very high (nukes?)
		if( flDamage < 500 )
			bitsDamageType &= ~DMG_BLAST|DMG_LAUNCH;

		return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}

	void HandlePain( float flDamage, string sWeaponName )
	{
		if( sWeaponName != "weapon_q2chainfist" and flDamage <= 10 )
			return;

		if( g_Engine.time < pev.pain_finished )
			return;

		if( sWeaponName != "weapon_q2chainfist" )
		{
			if( flDamage <= 30 )
			{
				if( Math.RandomFloat(0, 1) > 0.2 )
					return;
			}

			// don't go into pain while attacking
			//blaster and rocket
			if( self.m_Activity == ACT_RANGE_ATTACK1 or self.m_Activity == ACT_RANGE_ATTACK2 )
				return;
		}

		pev.pain_finished = g_Engine.time + 3.0;

		if( self.GetClassname() == "npc_q2tank" )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN], VOL_NORM, ATTN_NORM );
		else
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN_C], VOL_NORM, ATTN_NORM );

		if( !M_ShouldReactToPain() )
			return;

		if( flDamage <= 30 )
			SetAnim( self.LookupSequence(arrsNPCAnims[ANIM_PAIN1])  );
		else if( flDamage <= 60 )
			SetAnim( self.LookupSequence(arrsNPCAnims[ANIM_PAIN2])  );
		else
			SetAnim( self.LookupSequence(arrsNPCAnims[ANIM_PAIN3])  );
	}

	//Overridden to remove the arm upon normal death
	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		if( !m_bGibbed and pev.deadflag == DEAD_NO )
		{
			pev.body = 1;

			DropArm();
		}

		BaseClass.Killed( pevAttacker, iGib );
	}

	void GibMonster()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_DEATH_GIB], VOL_NORM, ATTN_NORM );

		ThrowGib( 1, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		ThrowGib( 3, MODEL_GIB_METAL, pev.dmg, -1, BREAK_METAL );
		ThrowGib( 1, MODEL_GIB_GEAR, pev.dmg, -1, BREAK_METAL );
		ThrowGib( 2, MODEL_GIB_FOOT, pev.dmg, 20, BREAK_CONCRETE, pev.skin / 2 );
		ThrowGib( 2, MODEL_GIB_THIGH, pev.dmg, 14, BREAK_CONCRETE, pev.skin / 2 );
		ThrowGib( 1, MODEL_GIB_CHEST, pev.dmg, 2, BREAK_CONCRETE, pev.skin / 2 );
		ThrowGib( 1, MODEL_GIB_HEAD, pev.dmg, 10, BREAK_CONCRETE, pev.skin / 2 );

		if( pev.body == 0 )
			DropArm();

		m_bGibbed = true;

		SetThink( ThinkFunction(this.SUB_Remove) );
		pev.nextthink = g_Engine.time;
	}
 
 	void DropArm()
	{
		Vector vecRight, vecUp;
		g_EngineFuncs.AngleVectors( pev.angles, void, vecRight, vecUp );

		Vector vecOrigin; //= pev.origin + vecRight * -16.0 + vecUp * 23.0;
		g_EngineFuncs.GetBonePosition( self.edict(), 23, vecOrigin, void );
		Vector vecVelocity = vecUp * 100.0 + vecRight * -120.0;

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_BREAKMODEL );
			m1.WriteCoord( vecOrigin.x ); //position x y z
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteCoord( 1 ); //size x y z
			m1.WriteCoord( 1 );
			m1.WriteCoord( 1 );
			m1.WriteCoord( vecVelocity.x ); //velocity x y z
			m1.WriteCoord( vecVelocity.y );
			m1.WriteCoord( vecVelocity.z );
			m1.WriteByte( 1 ); //random velocity in 10's
			m1.WriteShort( g_EngineFuncs.ModelIndex(MODEL_GIB_ARM) );
			m1.WriteByte( 1 ); //count
			m1.WriteByte( 90 ); //life in 0.1 secs
			m1.WriteByte( BREAK_CONCRETE|BREAK_SMOKE ); //flags
		m1.End();
	}

	void SUB_Remove()
	{
		self.UpdateOnRemove();

		if( pev.health > 0 )
		{
			// this situation can screw up monsters who can't tell their entity pointers are invalid.
			pev.health = 0;
		}

		g_EntityFuncs.Remove(self);
	}
}

void Register()
{
	q2::RegisterProjectile( "laser" );
	q2::RegisterProjectile( "rocket" );

	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2tank::npc_q2tank", "npc_q2tank" );
	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2tank::npc_q2tank", "npc_q2tankc" );
	g_Game.PrecacheOther( "npc_q2tank" );
}

} //end of namespace npc_q2tank

/* FIXME
*/

/* TODO
	Improve the blaster refire animation ??
	Add the strike victory pose ??
*/