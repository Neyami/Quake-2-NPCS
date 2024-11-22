namespace npc_q2enforcer
{

const string NPC_MODEL				= "models/quake2/monsters/enforcer/enforcer.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_ARM			= "models/quake2/monsters/enforcer/gibs/arm.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/enforcer/gibs/chest.mdl";
const string MODEL_GIB_FOOT		= "models/quake2/monsters/enforcer/gibs/foot.mdl";
const string MODEL_GIB_GUN			= "models/quake2/monsters/enforcer/gibs/gun.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/enforcer/gibs/head.mdl";

const Vector NPC_MINS					= Vector( -16, -16, 0 );
const Vector NPC_MAXS					= Vector( 16, 16, 80 );

const int NPC_HEALTH					= 100;

const int AE_MELEEATTACK				= 6;
const int AE_DECAPITATE				= 7;
const int AE_DEATHSHOT				= 8;
const int AE_COCKGUN					= 9;
const int AE_SHOOTGUN					= 10;

const float GUN_DAMAGE				= 3.0;
const Vector GUN_SPREAD				= VECTOR_CONE_3DEGREES;

const float MELEE_DMG_MIN			= 5.0;
const float MELEE_DMG_MAX			= 10.0;
const float MELEE_KICK					= 50.0;
const float MELEE_CD						= 1.5;

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/enforcer/infidle1.wav",
	"quake2/npcs/enforcer/infsght1.wav",
	"quake2/npcs/enforcer/infsrch1.wav",
	"quake2/npcs/enforcer/infatck3.wav",
	"quake2/npcs/enforcer/infatck1.wav",
	"quake2/npcs/enforcer/infatck2.wav",
	"quake2/npcs/enforcer/melee2.wav",
	"quake2/npcs/enforcer/infpain1.wav",
	"quake2/npcs/enforcer/infpain2.wav",
	"quake2/npcs/enforcer/infdeth1.wav",
	"quake2/npcs/enforcer/infdeth2.wav"
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_IDLE,
	SND_SIGHT,
	SND_SEARCH,
	SND_COCK,
	SND_SHOOT,
	SND_MELEE,
	SND_MELEE_HIT
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_IDLE_FIDGET,
	ANIM_WALK,
	ANIM_RUN,
	ANIM_RUN_SHOOT,
	ANIM_PAIN1,
	ANIM_PAIN2,
	ANIM_DUCK,
	ANIM_DEATH1,
	ANIM_DEATH2,
	ANIM_DEATH3,
	ANIM_DEFEND,
	ANIM_GUN_NOCOCK,
	ANIM_GUN_START,
	ANIM_GUN_LOOP,
	ANIM_GUN_END,
	ANIM_MELEE
};

final class npc_q2enforcer : CBaseQ2NPC
{
	private float m_flStopShooting;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, NPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, NPC_MINS, NPC_MAXS );

		pev.health						= NPC_HEALTH;
		pev.solid						= SOLID_SLIDEBOX;
		pev.movetype				= MOVETYPE_STEP;
		self.m_bloodColor			= BLOOD_COLOR_RED;
		self.m_flFieldOfView		= 0.3;
		self.m_afCapability			= bits_CAP_DOORS_GROUP;

		if( string(self.m_FormattedName).IsEmpty() )
			self.m_FormattedName	= "Enforcer";

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
		g_Game.PrecacheModel( MODEL_GIB_BONE );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_ARM );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_FOOT );
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
		int ys = 120;
		pev.yaw_speed = ys;
	}

	int Classify()
	{
		if( self.IsPlayerAlly() ) 
			return CLASS_PLAYER_ALLY;

		return CLASS_ALIEN_MILITARY;
	}

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
			case AE_MELEEATTACK:
			{
				int iDamage = Math.RandomLong(MELEE_DMG_MIN, MELEE_DMG_MAX);

				CBaseEntity@ pHurt = CheckTraceHullAttack( Q2_MELEE_DISTANCE, iDamage, DMG_GENERIC );
				if( pHurt !is null )
				{
					if( pHurt.pev.FlagBitSet(FL_MONSTER) or pHurt.pev.FlagBitSet(FL_CLIENT) )
					{
						pHurt.pev.punchangle.x = 5;
						Math.MakeVectors( pev.angles );

						pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * MELEE_KICK;
					}

					g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_MELEE_HIT], VOL_NORM, ATTN_NORM );
				}
				else
					m_flMeleeCooldown = g_Engine.time + MELEE_CD;

				break;
			}

			case AE_COCKGUN:
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_COCK], VOL_NORM, ATTN_NORM );

				break;
			}

			case AE_SHOOTGUN:
			{
				infantry_fire();

				break;
			}

			case AE_DEATHSHOT:
			{
				InfantryMachineGun();

				break;
			}

			case AE_DECAPITATE:
			{
				pev.body = 1; //headless

				if( Math.RandomFloat(0.0, 1.0) <= 0.45 ) //0.25 original
				{
					CGib@ pGib = g_EntityFuncs.CreateGib( pev.origin + Vector(0, 0, NPC_MAXS.z), g_vecZero );
					pGib.Spawn( MODEL_GIB_HEAD );

					pGib.pev.velocity = VelocityForDamage( 200 );

					pGib.pev.velocity.x += Math.RandomFloat( -0.15, 0.15 );
					pGib.pev.velocity.y += Math.RandomFloat( -0.25, 0.15 );
					pGib.pev.velocity.z += Math.RandomFloat( -0.2, 1.9 );

					pGib.pev.avelocity.x = Math.RandomFloat( 70, 200 );
					pGib.pev.avelocity.y = Math.RandomFloat( 70, 200 );

					pGib.LimitVelocity();

					pGib.m_bloodColor = BLOOD_COLOR_RED;
					pGib.m_cBloodDecals = 5;
					pGib.m_material = matFlesh;

					g_WeaponFuncs.SpawnBlood( pGib.pev.origin, BLOOD_COLOR_RED, 400 );
				}

				break;
			}
		}
	}

	bool CheckMeleeAttack1( float flDot, float flDist )
	{
		if( g_Engine.time < m_flMeleeCooldown )
			return false;

		if( flDist <= 64 and flDot >= 0.7 and self.m_hEnemy.IsValid() and self.m_hEnemy.GetEntity().pev.FlagBitSet(FL_ONGROUND) )
			return true;

		return false;
	}

	bool CheckRangeAttack1( float flDot, float flDist ) //flDist > 64 and flDist <= 784 and flDot >= 0.5
	{
		if( M_CheckAttack(flDist) )
		{
			m_flStopShooting = 0.0;

			return true;
		}

		return false;
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
			return;

		pev.pain_finished = g_Engine.time + 3.0;

		self.m_IdealActivity = ACT_SMALL_FLINCH;
	}

	void GibMonster()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_DEATH_GIB], VOL_NORM, ATTN_NORM );

		ThrowGib( 1, MODEL_GIB_BONE, pev.dmg, -1, BREAK_FLESH );
		ThrowGib( 3, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_CHEST, pev.dmg, 5, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_GUN, pev.dmg, 9 );
		ThrowGib( 1, MODEL_GIB_FOOT, pev.dmg, 4, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_FOOT, pev.dmg, 17, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_ARM, pev.dmg, 8, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_ARM, pev.dmg, 12, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_HEAD, pev.dmg, 6, BREAK_FLESH );

		SetThink( ThinkFunction(this.SUB_Remove) );
		pev.nextthink = g_Engine.time;
	}
 
	void infantry_fire()
	{
		if( m_flStopShooting <= 0.0 )
			m_flStopShooting = g_Engine.time + Math.RandomFloat( 0.7, 2.0 );

		InfantryMachineGun();

		if( g_Engine.time < m_flStopShooting )
			SetFrame( 15, 9 );
	}

	void InfantryMachineGun()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );

		Vector vecMuzzle, vecAim;

		if( self.m_hEnemy.IsValid() and pev.deadflag == DEAD_NO )
		{
			self.GetAttachment( 0, vecMuzzle, void );
			Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
			vecEnemyOrigin.z += self.m_hEnemy.GetEntity().pev.view_ofs.z;
			vecAim = (vecEnemyOrigin - vecMuzzle).Normalize();
		}
		else
		{
			Vector vecBonePos;

			g_EngineFuncs.GetBonePosition( self.edict(), 9, vecBonePos, void );
			self.GetAttachment( 1, vecMuzzle, void );
			vecAim = (vecMuzzle - vecBonePos).Normalize();
		}

		MachineGunEffects( vecMuzzle, 3 );

		//monster_fire_bullet( vecMuzzle, vecAim, GUN_DAMAGE, GUN_SPREAD );
		monster_fire_weapon( q2::WEAPON_BULLET, vecMuzzle, vecAim, GUN_DAMAGE );
	}

	void SUB_Remove()
	{
		self.UpdateOnRemove();

		if( pev.health > 0 )
			pev.health = 0;

		g_EntityFuncs.Remove(self);
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2enforcer::npc_q2enforcer", "npc_q2enforcer" );
	g_Game.PrecacheOther( "npc_q2enforcer" );
}

} //end of namespace npc_q2enforcer

/* FIXME
	Flinching ??
*/

/* TODO
	Add newer attacks
*/