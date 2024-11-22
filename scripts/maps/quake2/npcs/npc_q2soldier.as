namespace npc_q2soldier
{

const string NPC_MODEL				= "models/quake2/monsters/soldier/soldier.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_BONE2		= "models/quake2/objects/gibs/bone2.mdl";
const string MODEL_GIB_ARM			= "models/quake2/monsters/soldier/gibs/arm.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/soldier/gibs/chest.mdl";
const string MODEL_GIB_GUN			= "models/quake2/monsters/soldier/gibs/gun.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/soldier/gibs/head.mdl";

const int AE_ATTACK_SHOOT			= 6;
const int AE_ATTACK_REFIRE1		= 7;
const int AE_ATTACK_REFIRE2		= 8;

const int NPC_HEALTH_BLASTER		= 20;
const float BLASTER_DAMAGE			= 5;
const float BLASTER_SPEED			= 600;
const Vector BLASTER_SPREAD		= VECTOR_CONE_3DEGREES;

const int NPC_HEALTH_SHOTGUN	= 30;
const float SHOTGUN_DAMAGE		= 2.0;
const int SHOTGUN_COUNT			= 9;
const int SHOTGUN_AMMO				= 10;
const Vector SHOTGUN_SPREAD		= VECTOR_CONE_5DEGREES;

const int NPC_HEALTH_MGUN			= 40;
const float MGUN_FIRERATE			= 0.1;
const int MGUN_AMMO					= 35;
const float MGUN_DAMAGE				= 7.0;
const Vector MGUN_SPREAD			= VECTOR_CONE_3DEGREES;

const Vector NPC_MINS					= Vector( -16, -16, 0 );
const Vector NPC_MAXS					= Vector( 16, 16, 80 ); //# original

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/soldier/solidle1.wav",
	"quake2/npcs/soldier/solsght1.wav",
	"quake2/npcs/soldier/solsrch1.wav",
	"quake2/npcs/enforcer/infatck3.wav",
	"quake2/npcs/soldier/solatck2.wav",
	"quake2/npcs/soldier/solatck1.wav",
	"quake2/npcs/soldier/solatck3.wav",
	"quake2/npcs/soldier/solpain1.wav",
	"quake2/npcs/soldier/solpain2.wav",
	"quake2/npcs/soldier/solpain3.wav",
	"quake2/npcs/soldier/soldeth1.wav",
	"quake2/npcs/soldier/soldeth2.wav",
	"quake2/npcs/soldier/soldeth3.wav"
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_IDLE,
	SND_SIGHT,
	SND_SEARCH,
	SND_COCK,
	SND_BLASTER,
	SND_SHOTGUN,
	SND_MGUN,
	SND_PAIN1,
	SND_PAIN2,
	SND_PAIN3,
	SND_DEATH1,
	SND_DEATH2,
	SND_DEATH3
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_IDLE_FIDGET1,
	ANIM_IDLE_FIDGET2,
	ANIM_WALK1 = 4,
	ANIM_WALK2,
	ANIM_RUN,
	ANIM_ATTACK1 = 9, //12
	ANIM_ATTACK2, //18
	ANIM_MGUN,
	ANIM_DUCK = 14,
	ANIM_PAIN1,
	ANIM_PAIN2,
	ANIM_PAIN3,
	ANIM_PAIN4,
	ANIM_DEATH1,
	ANIM_DEATH2, //gut shot
	ANIM_DEATH3, //head shot
	ANIM_DEATH4,
	ANIM_DEATH5,
	ANIM_DEATH6
};

enum weapons_e
{
	WEAPON_BLASTER = 1,
	WEAPON_SHOTGUN = 2,
	WEAPON_MGUN = 4,
	WEAPON_RANDOM = 8
};

final class npc_q2soldier : CBaseQ2NPC
{
	private float m_flStopShooting;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, NPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, NPC_MINS, NPC_MAXS );

		if( pev.weapons <= 0 )
			pev.weapons = WEAPON_BLASTER;
		else if( pev.weapons == WEAPON_RANDOM )
			pev.weapons = Math.RandomLong( WEAPON_BLASTER, WEAPON_MGUN );

		if( pev.weapons == WEAPON_SHOTGUN )
		{
			pev.skin = 2;
			pev.health = NPC_HEALTH_SHOTGUN;

			if( string(self.m_FormattedName).IsEmpty() )
				self.m_FormattedName	= "Shotgun Guard";
		}
		else if( pev.weapons == WEAPON_MGUN )
		{
			pev.skin = 4;
			pev.health = NPC_HEALTH_MGUN;

			if( string(self.m_FormattedName).IsEmpty() )
				self.m_FormattedName	= "Machine Gun Guard";
		}
		else
		{
			pev.skin = 0;
			pev.health = NPC_HEALTH_BLASTER;

			if( string(self.m_FormattedName).IsEmpty() )
				self.m_FormattedName	= "Light Guard";
		}

		pev.solid						= SOLID_SLIDEBOX;
		pev.movetype				= MOVETYPE_STEP;
		self.m_bloodColor			= BLOOD_COLOR_RED;
		self.m_flFieldOfView		= 0.3;
		self.m_afCapability			= bits_CAP_DOORS_GROUP;

		m_flGibHealth = -60.0;

		if( q2::g_ChaosMode == q2::CHAOS_LEVEL1 )
			m_iWeaponType = Math.RandomLong(q2::WEAPON_BULLET, q2::WEAPON_BFG);

		self.MonsterInit();

		if( self.IsPlayerAlly() )
			SetUse( UseFunction(this.FollowerUse) );
	}

	void Precache()
	{
		uint i;

		g_Game.PrecacheModel( NPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_BONE );
		g_Game.PrecacheModel( MODEL_GIB_BONE2 );
		g_Game.PrecacheModel( MODEL_GIB_ARM );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_GUN );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );

		for( i = 0; i < arrsNPCSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( arrsNPCSounds[i] );
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

	void SetYawSpeed() //SUPER IMPORTANT, NPC WON'T DO ANYTHING WITHOUT THIS :aRage:
	{
		int ys;

		switch( self.m_Activity )
		{
			case ACT_IDLE:
				ys = 150;
				break;
			case ACT_RUN:
				ys = 150;	
				break;
			case ACT_WALK:
				ys = 180;		
				break;
			case ACT_RANGE_ATTACK1:
				ys = 120;	
				break;
			case ACT_RANGE_ATTACK2:
				ys = 120;	
				break;
			case ACT_TURN_LEFT:
			case ACT_TURN_RIGHT:
				ys = 180;
				break;
			default:
				ys = 90;
				break;
		}

		pev.yaw_speed = ys;
	}

	int Classify()
	{
		if( self.IsPlayerAlly() ) 
			return CLASS_PLAYER_ALLY;

		return CLASS_ALIEN_MILITARY;
	}

	bool CheckMeleeAttack1( float flDot, float flDist ) { return false; }
	bool CheckMeleeAttack2( float flDot, float flDist ) { return false; }

	void AlertSound()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );
	}

	void SearchSound()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SEARCH], VOL_NORM, ATTN_NORM );
	}

	void HandleAnimEventQ2( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case q2::AE_IDLESOUND:
			{
				if( Math.RandomFloat(0.0, 1.0) > 0.8 )
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_IDLE], VOL_NORM, ATTN_IDLE );

				break;
			}

			case q2::AE_FOOTSTEP:
			{
				monster_footstep();

				break;
			}

			case AE_ATTACK_SHOOT:
			{
				soldier_fire();

				break;
			}

			case AE_ATTACK_REFIRE1:
			{
				if( pev.weapons != WEAPON_BLASTER )
					return;

				if( !self.m_hEnemy.IsValid() or self.m_hEnemy.GetEntity().pev.health <= 0 )
					return;

				//if (((frandom() < 0.5f) && visible(self, self->enemy)) || (range_to(self, self->enemy) <= RANGE_MELEE))
				if( Math.RandomFloat(0.0, 1.0) < 0.5 or (pev.origin - self.m_hEnemy.GetEntity().pev.origin).Length2D() <= Q2_RANGE_MELEE )
				{
					if( GetAnim(ANIM_ATTACK1) )
						SetFrame( 12, 1 );
					else if( GetAnim(ANIM_ATTACK2) )
						SetFrame( 18, 3 );
				}
				else
				{
					if( GetAnim(ANIM_ATTACK1) )
						SetFrame( 12, 9 );
					else if( GetAnim(ANIM_ATTACK2) )
						SetFrame( 18, 15 );
				}

				break;
			}

			case AE_ATTACK_REFIRE2:
			{
				if( pev.weapons == WEAPON_BLASTER )
					return;

				if( !self.m_hEnemy.IsValid() or self.m_hEnemy.GetEntity().pev.health <= 0 )
					return;

				//if (((frandom() < 0.5f) && visible(self, self->enemy)) || (range_to(self, self->enemy) <= RANGE_MELEE))
				if( Math.RandomFloat(0.0, 1.0) < 0.5 or (pev.origin - self.m_hEnemy.GetEntity().pev.origin).Length2D() <= Q2_RANGE_MELEE )
				{
					if( GetAnim(ANIM_ATTACK1) )
						SetFrame( 12, 1 );
					else if( GetAnim(ANIM_ATTACK2) )
						SetFrame( 18, 3 );
				}

				break;
			}

			default:
				BaseClass.HandleAnimEvent( pEvent );
				break;
		}
	}

	//blaster and shotgun
	bool CheckRangeAttack1( float flDot, float flDist )
	{
		if( pev.weapons != WEAPON_MGUN and M_CheckAttack(flDist) ) //flDist > 64 and flDist <= 784 and flDot >= 0.5
			return true;

		return false;
	}

	//machinegun
	bool CheckRangeAttack2( float flDot, float flDist )
	{
		if( pev.weapons == WEAPON_MGUN and M_CheckAttack(flDist) ) //flDist > 64 and flDist <= 512 and flDot >= 0.5
		{
			m_flStopShooting = 0.0;

			return true;
		}

		return false;
	}

	void soldier_fire()
	{
		Vector vecMuzzle, vecAim;
		self.GetAttachment( 0, vecMuzzle, void );

		if( pev.deadflag != DEAD_NO )
		{
			g_EngineFuncs.MakeVectors( pev.angles );
			vecAim = g_Engine.v_forward;
		}
		else if( self.m_hEnemy.IsValid() )
		{
			Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
			vecEnemyOrigin.z += self.m_hEnemy.GetEntity().pev.view_ofs.z;
			//vecEnemyOrigin.z += (self.m_hEnemy.GetEntity().pev.maxs.z * 0.8); //don't aim too high
			vecAim = (vecEnemyOrigin - vecMuzzle).Normalize();
		}

		if( pev.weapons == WEAPON_SHOTGUN )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_SHOTGUN], VOL_NORM, ATTN_NORM );

			monster_muzzleflash( vecMuzzle, 20, 255, 255, 0 );
			MachineGunEffects( vecMuzzle );
			//monster_fire_shotgun( vecMuzzle, vecAim, SHOTGUN_DAMAGE, SHOTGUN_SPREAD, SHOTGUN_COUNT );
			monster_fire_weapon( q2::WEAPON_SHOTGUN, vecMuzzle, vecAim, SHOTGUN_DAMAGE );
		}
		else if( pev.weapons == WEAPON_MGUN )
		{
			if( m_flStopShooting <= 0.0 )
				m_flStopShooting = g_Engine.time + Math.RandomFloat( 0.3, 1.1 );

			g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MGUN], VOL_NORM, ATTN_NORM );

			monster_muzzleflash( vecMuzzle, 20, 255, 255, 0 );
			MachineGunEffects( vecMuzzle );
			//monster_fire_bullet( vecMuzzle, vecAim, MGUN_DAMAGE, MGUN_SPREAD );
			monster_fire_weapon( q2::WEAPON_BULLET, vecMuzzle, vecAim, MGUN_DAMAGE );

			if( g_Engine.time < m_flStopShooting )
			{
				if( pev.deadflag != DEAD_NO )
					SetFrame( 36, 20 );
				else
					SetFrame( 6, 1 );
			}
		}
		else
		{
			g_EngineFuncs.MakeVectors( vecAim );

			float x, y;
			g_Utility.GetCircularGaussianSpread( x, y );

			vecAim = vecAim + x * BLASTER_SPREAD.x * g_Engine.v_right + y * BLASTER_SPREAD.y * g_Engine.v_up;

			g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_BLASTER], VOL_NORM, ATTN_NORM );

			monster_muzzleflash( vecMuzzle, 20, 255, 255, 0 );
			//monster_fire_blaster( vecMuzzle, vecAim, BLASTER_DAMAGE, BLASTER_SPEED );
			monster_fire_weapon( q2::WEAPON_BLASTER, vecMuzzle, vecAim, BLASTER_DAMAGE, BLASTER_SPEED );
		}
	}

	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		pevAttacker.frags += ( flDamage/90 );

		HandlePain( flDamage );

		return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}

	void HandlePain( float flDamage )
	{
		pev.dmg = flDamage;

		if( pev.deadflag != DEAD_NO ) return;

		if( pev.health < (pev.max_health / 2) )
			pev.skin |= 1;

		if( g_Engine.time < pev.pain_finished )
		{
			if( pev.velocity.z > 100 and (GetAnim(ANIM_PAIN1) or GetAnim(ANIM_PAIN2) or GetAnim(ANIM_PAIN3)) )
				SetAnim( ANIM_PAIN4 );

			return;
		}

		pev.pain_finished = g_Engine.time + 3.0;

		if( pev.weapons == WEAPON_SHOTGUN )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN3], VOL_NORM, ATTN_NORM );
		else if( pev.weapons == WEAPON_MGUN )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN1], VOL_NORM, ATTN_NORM );
		else
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN2], VOL_NORM, ATTN_NORM );

		if( pev.velocity.z > 100 )
		{
			SetAnim( ANIM_PAIN4 );
			return;
		}

		//if (skill->value == 3)
			//return;		// no pain anims in nightmare

		float flRand = Math.RandomFloat(0.0, 1.0);

		if( flRand < 0.33 )
			SetAnim( ANIM_PAIN1 );
		else if( flRand < 0.66 )
			SetAnim( ANIM_PAIN2 );
		else
			SetAnim( ANIM_PAIN3 );
	}

	void StartTask( Task@ pTask )
	{
		switch( pTask.iTask )
		{
			case TASK_DIE:
			{
				if( pev.weapons == WEAPON_SHOTGUN )
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_DEATH1], VOL_NORM, ATTN_NORM );
				else if( pev.weapons == WEAPON_MGUN )
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_DEATH3], VOL_NORM, ATTN_NORM );
				else
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_DEATH2], VOL_NORM, ATTN_NORM );

				if( self.m_LastHitGroup == HITGROUP_HEAD and pev.velocity.z < 65.0 )
				{
					// head shot
					SetAnim( ANIM_DEATH3 );
					return;
				}

				/*// if we die while on the ground, do a quicker death4
				if (self->monsterinfo.active_move == &soldier_move_trip || self->monsterinfo.active_move == &soldier_move_attack5)
				{
					SetAnim( ANIM_DEATH4, 1.0, SetFrame2(53, 12) );
					soldier_death_shrink(self);
					return;
				}*/

				int iRand;
				// only do the spin-death if we have enough velocity to justify it
				if( pev.velocity.z > 65.0 or pev.velocity.Length() > 150.0 )
					iRand = Math.RandomLong(0, 4);
				else
					iRand = Math.RandomLong(0, 3);

				if( iRand == 0 )
				{
					m_flStopShooting = 0.0;
					SetAnim( ANIM_DEATH1 );
				}
				else if( iRand == 1 )
					SetAnim( ANIM_DEATH2 );
				else if( iRand == 2 )
					SetAnim( ANIM_DEATH4 );
				else if( iRand == 3 )
					SetAnim( ANIM_DEATH5 );
				else
					SetAnim( ANIM_DEATH6 );

				break;
			}

			default:
			{			
				BaseClass.StartTask( pTask );
				break;
			}
		}
	}

	void GibMonster()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_DEATH_GIB], VOL_NORM, ATTN_NORM );

		ThrowGib( 3, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_BONE, pev.dmg, -1, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_BONE2, pev.dmg, -1, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_ARM, pev.dmg, 7, BREAK_FLESH, pev.skin / 2 ); //divide by 2 to get the proper gibskin, since the monster model has 6 skins but the gibs only have 3
		ThrowGib( 1, MODEL_GIB_GUN, pev.dmg, 5, 0, pev.skin / 2 );
		ThrowGib( 1, MODEL_GIB_CHEST, pev.dmg, 2, BREAK_FLESH, pev.skin / 2 );
		ThrowGib( 1, MODEL_GIB_HEAD, pev.dmg, 3, BREAK_FLESH, pev.skin / 2 );

		SetThink( ThinkFunction(this.SUB_Remove) );
		pev.nextthink = g_Engine.time;
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
	if( !g_CustomEntityFuncs.IsCustomEntity( "q2lasernpc" ) ) 
		q2::RegisterNPCLaser();

	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2soldier::npc_q2soldier", "npc_q2soldier" );
	g_Game.PrecacheOther( "npc_q2soldier" );
}

} //end of namespace npc_q2soldier

/* FIXME
	The second machinegun burst during the death animation needs to be longer
*/

/* TODO
	Try to find the proper way of using the flinching animations

	Try to find the proper way of firing the machinegun ??

	Tripping

	WalkMove in certain animations ??
*/